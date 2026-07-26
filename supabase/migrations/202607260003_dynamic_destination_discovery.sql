-- Dynamic, Maps-grounded destination discovery and cross-user load control.
-- The destinations table becomes a cache and safety registry rather than a
-- fixed recommendation catalogue.

alter table public.destinations
  add column if not exists google_maps_uri text,
  add column if not exists formatted_address text,
  add column if not exists primary_type text,
  add column if not exists google_rating numeric(2, 1)
    check (google_rating is null or google_rating between 0 and 5),
  add column if not exists google_user_rating_count integer
    check (
      google_user_rating_count is null
      or google_user_rating_count >= 0
    ),
  add column if not exists business_status text,
  add column if not exists safety_status text not null default 'pending'
    check (
      safety_status in (
        'pending',
        'automated_review',
        'curated',
        'suspended',
        'rejected'
      )
    ),
  add column if not exists safety_score numeric(4, 3)
    check (safety_score is null or safety_score between 0 and 1),
  add column if not exists discovery_score numeric(4, 3)
    check (discovery_score is null or discovery_score between 0 and 1),
  add column if not exists capacity_per_slot integer not null default 1
    check (capacity_per_slot > 0),
  add column if not exists daylight_only boolean not null default false,
  add column if not exists source_metadata jsonb not null default '{}'::jsonb,
  add column if not exists last_place_sync_at timestamptz;

-- Existing coursework seed destinations were manually curated.
update public.destinations
set
  safety_status = 'curated',
  safety_score = coalesce(safety_score, 1),
  discovery_score = coalesce(
    discovery_score,
    greatest(0, least(1, 1 - coalesce(popularity_score, 0) / 10))
  )
where external_place_id like 'starter:%';

create index if not exists destinations_external_safety_idx
  on public.destinations (external_place_id, safety_status, active);

create index if not exists destinations_discovery_idx
  on public.destinations (discovery_score desc)
  where active and safety_status in ('automated_review', 'curated');

create table public.destination_safety_reviews (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null
    references public.destinations(id) on delete cascade,
  review_type text not null
    check (review_type in ('automated', 'manual', 'incident')),
  status text not null
    check (status in ('approved', 'needs_review', 'suspended', 'rejected')),
  score numeric(4, 3) check (score is null or score between 0 and 1),
  evidence jsonb not null default '{}'::jsonb,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz not null default now(),
  expires_at timestamptz
);

create index destination_safety_reviews_latest_idx
  on public.destination_safety_reviews (destination_id, reviewed_at desc);

-- A short reservation is created when a recommendation is shown. The unique
-- live index prevents two concurrent recommendation requests from holding the
-- same destination. Expired reservations are marked before each generation.
create table public.destination_allocations (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null
    references public.destinations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null
    references public.mission_requests(id) on delete cascade,
  recommendation_id uuid
    references public.mission_recommendations(id) on delete cascade,
  status text not null default 'reserved'
    check (
      status in ('reserved', 'active', 'completed', 'released', 'expired')
    ),
  reserved_at timestamptz not null default now(),
  expires_at timestamptz not null,
  released_at timestamptz,
  created_at timestamptz not null default now(),
  check (expires_at > reserved_at),
  check (
    (status in ('released', 'expired') and released_at is not null)
    or
    (status in ('reserved', 'active', 'completed'))
  )
);

create unique index destination_one_live_allocation_idx
  on public.destination_allocations (destination_id)
  where status in ('reserved', 'active');

create index destination_allocations_user_history_idx
  on public.destination_allocations (user_id, created_at desc);

create index destination_allocations_expiry_idx
  on public.destination_allocations (expires_at)
  where status = 'reserved';

alter table public.destination_safety_reviews enable row level security;
alter table public.destination_allocations enable row level security;

-- These two tables are intentionally server-only. Edge Functions use the
-- service role and no client grants or policies are added.
