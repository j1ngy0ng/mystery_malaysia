-- Mystery Malaysia initial schema
-- Supabase Auth owns credentials. Public tables use RLS. Hidden destinations,
-- canonical clues, answers, hints, recommendation routes, and command receipts
-- remain server-only and are accessed through protected Edge Functions.

create extension if not exists pgcrypto;

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- User and Profile

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text,
  display_name text not null check (char_length(display_name) between 1 and 80),
  avatar_path text,
  bio text check (bio is null or char_length(bio) <= 300),
  hometown text,
  profile_visibility text not null default 'private'
    check (profile_visibility in ('private', 'participants', 'public')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index profiles_username_lower_idx
  on public.profiles (lower(username))
  where username is not null;

-- Mission Discovery

-- A destination remains hidden from a player until that player has a verified
-- visit. Recommendation Edge Functions use the service role to query it.
create table public.destinations (
  id uuid primary key default gen_random_uuid(),
  external_place_id text unique,
  name text not null,
  state text not null,
  city text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  categories text[] not null default '{}',
  estimated_budget_myr numeric(10, 2)
    check (estimated_budget_myr is null or estimated_budget_myr >= 0),
  estimated_duration_minutes integer
    check (estimated_duration_minutes is null or estimated_duration_minutes > 0),
  opening_hours jsonb not null default '{}'::jsonb,
  availability jsonb not null default '{}'::jsonb,
  accessibility jsonb not null default '{}'::jsonb,
  visitor_information jsonb not null default '{}'::jsonb,
  facts jsonb not null default '[]'::jsonb,
  popularity_score numeric(6, 3)
    check (popularity_score is null or popularity_score >= 0),
  active boolean not null default true,
  source_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Server-only. destination_id is the primary key, enforcing at most one
-- canonical clue row per destination. hint_text is nullable, so each clue has
-- zero or one optional additional hint.
create table public.destination_clues (
  destination_id uuid primary key references public.destinations(id) on delete cascade,
  clue_type text not null
    check (clue_type in ('text', 'photo', 'observation', 'multiple_choice', 'qr')),
  title text not null,
  prompt text not null,
  options jsonb,
  media_path text,
  answer_hash text,
  accepted_answers jsonb not null default '[]'::jsonb,
  validation_rules jsonb not null default '{}'::jsonb,
  hint_text text,
  clue_xp_reward integer not null default 0 check (clue_xp_reward >= 0),
  hint_xp_cost integer not null default 0 check (hint_xp_cost >= 0),
  ai_model text,
  prompt_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (hint_text is not null or hint_xp_cost = 0)
);

create table public.mission_templates (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  theme text not null,
  difficulty text not null check (difficulty in ('easy', 'moderate', 'hard')),
  minimum_stops smallint not null default 1 check (minimum_stops > 0),
  maximum_stops smallint not null default 1 check (maximum_stops >= minimum_stops),
  minimum_duration_minutes integer not null check (minimum_duration_minutes > 0),
  maximum_duration_minutes integer not null
    check (maximum_duration_minutes >= minimum_duration_minutes),
  minimum_budget_myr numeric(10, 2) not null default 0 check (minimum_budget_myr >= 0),
  maximum_budget_myr numeric(10, 2)
    check (maximum_budget_myr is null or maximum_budget_myr >= minimum_budget_myr),
  prompt_rules jsonb not null default '{}'::jsonb,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- A request is an immutable snapshot of the constraints used to generate a
-- recommendation. Later requests do not alter earlier request records.
create table public.mission_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  origin_latitude double precision not null check (origin_latitude between -90 and 90),
  origin_longitude double precision not null check (origin_longitude between -180 and 180),
  intended_start_at timestamptz,
  available_minutes integer not null check (available_minutes > 0),
  budget_myr numeric(10, 2) not null check (budget_myr >= 0),
  maximum_distance_km numeric(8, 2) not null check (maximum_distance_km > 0),
  categories text[] not null default '{}',
  preferred_state text,
  travel_style text,
  group_type text not null check (group_type in ('solo', 'couple', 'family', 'friends')),
  accessibility_requirements jsonb not null default '{}'::jsonb,
  status text not null default 'pending'
    check (status in ('pending', 'generating', 'ready', 'no_match', 'failed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Player-visible recommendation data contains no destination identity.
create table public.mission_recommendations (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.mission_requests(id) on delete cascade,
  title text not null,
  story_hook text not null,
  explanation text not null,
  partially_satisfied_constraints jsonb not null default '[]'::jsonb,
  estimated_duration_minutes integer not null check (estimated_duration_minutes > 0),
  estimated_budget_myr numeric(10, 2) not null check (estimated_budget_myr >= 0),
  total_distance_km numeric(8, 2) check (total_distance_km is null or total_distance_km >= 0),
  difficulty text not null check (difficulty in ('easy', 'moderate', 'hard')),
  xp_reward integer not null default 0 check (xp_reward >= 0),
  tags text[] not null default '{}',
  recommendation_rank smallint not null check (recommendation_rank between 1 and 3),
  created_at timestamptz not null default now(),
  unique (request_id, recommendation_rank)
);

-- Server-only ordered route. A recommendation can contain many destinations,
-- but the same destination cannot appear twice in one recommendation.
create table public.mission_recommendation_stops (
  recommendation_id uuid not null
    references public.mission_recommendations(id) on delete cascade,
  stop_number smallint not null check (stop_number > 0),
  destination_id uuid not null references public.destination_clues(destination_id),
  template_id uuid references public.mission_templates(id),
  travel_distance_km numeric(8, 2)
    check (travel_distance_km is null or travel_distance_km >= 0),
  travel_minutes integer check (travel_minutes is null or travel_minutes >= 0),
  created_at timestamptz not null default now(),
  primary key (recommendation_id, stop_number),
  unique (recommendation_id, destination_id)
);

-- Server-only AI and regeneration audit trail. Recommendation frequency is
-- derived by counting mission_recommendation_stops by destination.
create table public.recommendation_events (
  id bigint generated always as identity primary key,
  request_id uuid not null references public.mission_requests(id) on delete cascade,
  recommendation_id uuid references public.mission_recommendations(id) on delete cascade,
  event_type text not null
    check (event_type in ('generated', 'stop_regenerated', 'accepted', 'rejected', 'failed')),
  ai_model text,
  prompt_version text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Active Mission and Collaborative Travel

create table public.mission_sessions (
  id uuid primary key default gen_random_uuid(),
  recommendation_id uuid unique
    references public.mission_recommendations(id) on delete set null,
  title text not null,
  mode text not null check (mode in ('solo', 'collaborative')),
  travel_type text not null check (travel_type in ('solo', 'couple', 'family', 'friends')),
  status text not null default 'waiting'
    check (status in ('waiting', 'active', 'paused', 'completed', 'abandoned')),
  current_stage smallint not null default 1 check (current_stage > 0),
  version integer not null default 1 check (version > 0),
  started_at timestamptz,
  paused_at timestamptz,
  completed_at timestamptz,
  abandoned_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (mode = 'solo' and travel_type = 'solo')
    or
    (mode = 'collaborative' and travel_type in ('couple', 'family', 'friends'))
  ),
  check ((status = 'waiting' and started_at is null) or status <> 'waiting'),
  check ((status = 'completed' and completed_at is not null) or status <> 'completed'),
  check ((status = 'abandoned' and abandoned_at is not null) or status <> 'abandoned')
);

create table public.mission_participants (
  session_id uuid not null references public.mission_sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('host', 'member')),
  ready boolean not null default false,
  status text not null default 'joined'
    check (
      status in (
        'joined',
        'ready',
        'navigating',
        'arrived',
        'reflection_submitted',
        'completed',
        'disconnected',
        'left'
      )
    ),
  joined_at timestamptz not null default now(),
  last_seen_at timestamptz,
  completed_at timestamptz,
  primary key (session_id, user_id)
);

create unique index one_active_host_per_session_idx
  on public.mission_participants (session_id)
  where role = 'host' and status <> 'left';

-- One row per user enforces one waiting/active/paused mission at a time.
create table public.user_current_missions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  session_id uuid not null references public.mission_sessions(id) on delete cascade,
  updated_at timestamptz not null default now(),
  foreign key (session_id, user_id)
    references public.mission_participants(session_id, user_id) on delete cascade
);

-- Player-visible ordered stages reveal sequence and progress, but not destination.
create table public.mission_stages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.mission_sessions(id) on delete cascade,
  stage_number smallint not null check (stage_number > 0),
  status text not null default 'locked'
    check (status in ('locked', 'active', 'completed')),
  unlocked_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (session_id, stage_number),
  unique (id, session_id),
  check (
    (status = 'locked' and unlocked_at is null and completed_at is null)
    or
    (status = 'active' and unlocked_at is not null and completed_at is null)
    or
    (status = 'completed' and unlocked_at is not null and completed_at is not null)
  )
);

create unique index one_active_stage_per_session_idx
  on public.mission_stages (session_id)
  where status = 'active';

-- Server-only destination mapping and geofence snapshot for each stage.
create table public.mission_stage_secrets (
  stage_id uuid primary key,
  session_id uuid not null,
  destination_id uuid not null references public.destination_clues(destination_id),
  arrival_latitude double precision not null check (arrival_latitude between -90 and 90),
  arrival_longitude double precision not null check (arrival_longitude between -180 and 180),
  arrival_radius_metres integer not null default 75
    check (arrival_radius_metres between 20 and 500),
  created_at timestamptz not null default now(),
  unique (session_id, destination_id),
  unique (stage_id, session_id, destination_id),
  foreign key (stage_id, session_id)
    references public.mission_stages(id, session_id) on delete cascade
);

-- Safe player-visible copy of the destination's single canonical clue.
create table public.mission_clue_reveals (
  stage_id uuid primary key references public.mission_stages(id) on delete cascade,
  clue_type text not null
    check (clue_type in ('text', 'photo', 'observation', 'multiple_choice', 'qr')),
  title text not null,
  prompt text not null,
  options jsonb,
  media_path text,
  revealed_at timestamptz not null default now()
);

-- One primary-key row means one user can reveal at most one additional hint
-- for a stage/destination during that mission.
create table public.clue_hint_reveals (
  stage_id uuid not null references public.mission_stages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  revealed_text text not null,
  xp_cost integer not null default 0 check (xp_cost >= 0),
  requested_at timestamptz not null default now(),
  primary key (stage_id, user_id)
);

create table public.clue_progress (
  stage_id uuid not null references public.mission_stages(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'viewed'
    check (status in ('viewed', 'attempted', 'solved')),
  attempts integer not null default 0 check (attempts >= 0),
  hint_used boolean not null default false,
  solved_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (stage_id, user_id),
  check ((status = 'solved' and solved_at is not null) or status <> 'solved')
);

-- Latest participant coordinates support server-side group-distance checks.
-- They are private to the owning user at the client and should be deleted when
-- the mission finishes.
create table public.participant_locations (
  session_id uuid not null,
  user_id uuid not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_metres numeric(8, 2) not null check (accuracy_metres >= 0),
  recorded_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (session_id, user_id),
  foreign key (session_id, user_id)
    references public.mission_participants(session_id, user_id) on delete cascade
);

-- Server-written arrival evidence. Destination identity is resolved through
-- mission_stage_secrets and is not duplicated in this client-readable table.
create table public.verified_visits (
  id uuid primary key default gen_random_uuid(),
  stage_id uuid not null,
  session_id uuid not null,
  user_id uuid not null,
  verified_latitude double precision not null check (verified_latitude between -90 and 90),
  verified_longitude double precision not null check (verified_longitude between -180 and 180),
  gps_accuracy_metres numeric(8, 2) not null check (gps_accuracy_metres >= 0),
  distance_to_target_metres numeric(10, 2) not null
    check (distance_to_target_metres >= 0),
  verified_at timestamptz not null default now(),
  unique (stage_id, user_id),
  foreign key (stage_id, session_id)
    references public.mission_stages(id, session_id) on delete cascade,
  foreign key (session_id, user_id)
    references public.mission_participants(session_id, user_id) on delete cascade
);

create table public.mission_session_events (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.mission_sessions(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.mission_sessions(id) on delete cascade,
  inviter_id uuid not null references auth.users(id) on delete cascade,
  invitee_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'expired', 'cancelled')),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (inviter_id <> invitee_id),
  unique (session_id, invitee_id),
  foreign key (session_id, inviter_id)
    references public.mission_participants(session_id, user_id) on delete cascade
);

create table public.mission_messages (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.mission_sessions(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  message_type text not null default 'text'
    check (message_type in ('text', 'reaction', 'system')),
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now(),
  foreign key (session_id, sender_id)
    references public.mission_participants(session_id, user_id) on delete cascade
);

-- Passport and Diary

create table public.stamp_definitions (
  id uuid primary key default gen_random_uuid(),
  destination_id uuid not null unique references public.destinations(id),
  name text not null,
  artwork_path text not null,
  rarity text not null default 'common'
    check (rarity in ('common', 'rare', 'legendary')),
  created_at timestamptz not null default now(),
  unique (id, destination_id)
);

-- A user earns a destination stamp once, even if the destination is revisited.
create table public.user_stamps (
  user_id uuid not null references auth.users(id) on delete cascade,
  stamp_id uuid not null,
  destination_id uuid not null,
  session_id uuid not null references public.mission_sessions(id),
  stage_id uuid not null,
  earned_at timestamptz not null default now(),
  primary key (user_id, stamp_id),
  foreign key (stamp_id, destination_id)
    references public.stamp_definitions(id, destination_id),
  foreign key (stage_id, session_id, destination_id)
    references public.mission_stage_secrets(stage_id, session_id, destination_id)
);

create table public.badge_definitions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null,
  artwork_path text,
  criteria jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.user_badges (
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_id uuid not null references public.badge_definitions(id),
  session_id uuid references public.mission_sessions(id),
  earned_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

create table public.xp_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid references public.mission_sessions(id),
  stage_id uuid,
  amount integer not null check (amount <> 0),
  reason text not null check (char_length(reason) > 0),
  created_at timestamptz not null default now(),
  foreign key (stage_id, session_id)
    references public.mission_stages(id, session_id)
);

-- Each participant can submit one reflection for a completed session.
create table public.reflections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid not null references public.mission_sessions(id) on delete cascade,
  mood text,
  favourite_moment text,
  learned text,
  spending_myr numeric(10, 2)
    check (spending_myr is null or spending_myr >= 0),
  rating smallint check (rating is null or rating between 1 and 5),
  private_notes text,
  photo_paths text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, session_id)
);

-- Individual sessions can have one diary per user. Collaborative sessions can
-- additionally have exactly one shared diary with no owner_user_id.
create table public.diary_entries (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.mission_sessions(id) on delete cascade,
  owner_user_id uuid references auth.users(id) on delete cascade,
  diary_type text not null check (diary_type in ('individual', 'shared')),
  title text not null,
  content jsonb not null,
  visibility text not null default 'private'
    check (visibility in ('private', 'participants', 'public')),
  ai_model text,
  prompt_version text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (diary_type = 'individual' and owner_user_id is not null)
    or
    (diary_type = 'shared' and owner_user_id is null and visibility = 'participants')
  )
);

create unique index one_individual_diary_per_user_session_idx
  on public.diary_entries (session_id, owner_user_id)
  where diary_type = 'individual';

create unique index one_shared_diary_per_session_idx
  on public.diary_entries (session_id)
  where diary_type = 'shared';

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- Server-only idempotency record for protected mutations.
create table public.command_receipts (
  request_id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  command_name text not null,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Shared helpers used by RLS.

create function public.is_mission_participant(target_session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.mission_participants
    where session_id = target_session_id
      and user_id = (select auth.uid())
      and status <> 'left'
  );
$$;

create function public.can_view_profile(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    target_user_id = (select auth.uid())
    or exists (
      select 1
      from public.profiles
      where id = target_user_id
        and profile_visibility = 'public'
    )
    or exists (
      select 1
      from public.profiles profile
      join public.mission_participants theirs on theirs.user_id = profile.id
      join public.mission_participants mine on mine.session_id = theirs.session_id
      where profile.id = target_user_id
        and profile.profile_visibility = 'participants'
        and mine.user_id = (select auth.uid())
        and theirs.user_id = target_user_id
        and mine.status <> 'left'
        and theirs.status <> 'left'
    );
$$;

-- A destination can be read only after this user has a verified visit to its
-- mission stage. Service-role Edge Functions bypass this player restriction.
create function public.can_view_destination(target_destination_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.mission_stage_secrets secret
    join public.verified_visits visit on visit.stage_id = secret.stage_id
    where secret.destination_id = target_destination_id
      and visit.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_mission_participant(uuid) from public;
revoke all on function public.can_view_profile(uuid) from public;
revoke all on function public.can_view_destination(uuid) from public;

grant execute on function public.is_mission_participant(uuid) to authenticated;
grant execute on function public.can_view_profile(uuid) to authenticated;
grant execute on function public.can_view_destination(uuid) to authenticated;

-- Updated-at triggers.

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger destinations_set_updated_at
before update on public.destinations
for each row execute function public.set_updated_at();

create trigger destination_clues_set_updated_at
before update on public.destination_clues
for each row execute function public.set_updated_at();

create trigger mission_templates_set_updated_at
before update on public.mission_templates
for each row execute function public.set_updated_at();

create trigger mission_requests_set_updated_at
before update on public.mission_requests
for each row execute function public.set_updated_at();

create trigger mission_sessions_set_updated_at
before update on public.mission_sessions
for each row execute function public.set_updated_at();

create trigger participant_locations_set_updated_at
before update on public.participant_locations
for each row execute function public.set_updated_at();

create trigger clue_progress_set_updated_at
before update on public.clue_progress
for each row execute function public.set_updated_at();

create trigger reflections_set_updated_at
before update on public.reflections
for each row execute function public.set_updated_at();

create trigger diary_entries_set_updated_at
before update on public.diary_entries
for each row execute function public.set_updated_at();

-- Create application rows alongside a new Supabase Auth user.

insert into public.profiles (id, display_name)
select
  id,
  coalesce(nullif(raw_user_meta_data ->> 'display_name', ''), 'Explorer')
from auth.users
on conflict (id) do nothing;

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), 'Explorer')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create function public.clear_finished_current_missions()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status in ('completed', 'abandoned')
     and old.status is distinct from new.status then
    delete from public.user_current_missions where session_id = new.id;
    delete from public.participant_locations where session_id = new.id;
  end if;
  return new;
end;
$$;

create trigger mission_sessions_clear_current
after update of status on public.mission_sessions
for each row execute function public.clear_finished_current_missions();

-- Index foreign keys and common RLS/query columns.

create index destinations_city_active_idx
  on public.destinations (city, active);
create index destination_categories_idx
  on public.destinations using gin (categories);
create index mission_requests_user_created_idx
  on public.mission_requests (user_id, created_at desc);
create index recommendations_request_idx
  on public.mission_recommendations (request_id);
create index recommendation_stops_destination_idx
  on public.mission_recommendation_stops (destination_id);
create index recommendation_events_request_idx
  on public.recommendation_events (request_id, created_at desc);
create index participants_user_status_idx
  on public.mission_participants (user_id, status);
create index stages_session_status_idx
  on public.mission_stages (session_id, status, stage_number);
create index stage_secrets_destination_idx
  on public.mission_stage_secrets (destination_id);
create index verified_visits_user_idx
  on public.verified_visits (user_id, verified_at desc);
create index session_events_session_created_idx
  on public.mission_session_events (session_id, created_at);
create index invitations_invitee_status_idx
  on public.invitations (invitee_id, status);
create index invitations_inviter_idx
  on public.invitations (inviter_id);
create index messages_session_created_idx
  on public.mission_messages (session_id, created_at);
create index clue_progress_user_idx
  on public.clue_progress (user_id, status);
create index hint_reveals_user_idx
  on public.clue_hint_reveals (user_id, requested_at);
create index user_stamps_user_idx
  on public.user_stamps (user_id, earned_at desc);
create index user_badges_user_idx
  on public.user_badges (user_id, earned_at desc);
create index xp_ledger_user_created_idx
  on public.xp_ledger (user_id, created_at desc);
create unique index xp_ledger_session_award_once_idx
  on public.xp_ledger (user_id, session_id, reason)
  where session_id is not null and stage_id is null;
create unique index xp_ledger_stage_award_once_idx
  on public.xp_ledger (user_id, stage_id, reason)
  where stage_id is not null;
create index reflections_user_idx
  on public.reflections (user_id, created_at desc);
create index diary_entries_owner_idx
  on public.diary_entries (owner_user_id, created_at desc)
  where owner_user_id is not null;
create index notifications_user_unread_idx
  on public.notifications (user_id, created_at desc)
  where read_at is null;
create index command_receipts_user_idx
  on public.command_receipts (user_id, created_at desc);

-- Enable RLS on every public table.

alter table public.profiles enable row level security;
alter table public.destinations enable row level security;
alter table public.destination_clues enable row level security;
alter table public.mission_templates enable row level security;
alter table public.mission_requests enable row level security;
alter table public.mission_recommendations enable row level security;
alter table public.mission_recommendation_stops enable row level security;
alter table public.recommendation_events enable row level security;
alter table public.mission_sessions enable row level security;
alter table public.mission_participants enable row level security;
alter table public.user_current_missions enable row level security;
alter table public.mission_stages enable row level security;
alter table public.mission_stage_secrets enable row level security;
alter table public.mission_clue_reveals enable row level security;
alter table public.clue_hint_reveals enable row level security;
alter table public.clue_progress enable row level security;
alter table public.participant_locations enable row level security;
alter table public.verified_visits enable row level security;
alter table public.mission_session_events enable row level security;
alter table public.invitations enable row level security;
alter table public.mission_messages enable row level security;
alter table public.stamp_definitions enable row level security;
alter table public.user_stamps enable row level security;
alter table public.badge_definitions enable row level security;
alter table public.user_badges enable row level security;
alter table public.xp_ledger enable row level security;
alter table public.reflections enable row level security;
alter table public.diary_entries enable row level security;
alter table public.notifications enable row level security;
alter table public.command_receipts enable row level security;

-- Client grants. Tables not listed remain service-role only.

grant select, insert, update on public.profiles to authenticated;
grant select on public.destinations to authenticated;
grant select, insert, delete on public.mission_requests to authenticated;
grant select on public.mission_recommendations to authenticated;
grant select on public.mission_sessions to authenticated;
grant select on public.mission_participants to authenticated;
grant select on public.user_current_missions to authenticated;
grant select on public.mission_stages to authenticated;
grant select on public.mission_clue_reveals to authenticated;
grant select on public.clue_hint_reveals to authenticated;
grant select on public.clue_progress to authenticated;
grant select, insert, update on public.participant_locations to authenticated;
grant select on public.verified_visits to authenticated;
grant select on public.mission_session_events to authenticated;
grant select on public.invitations to authenticated;
grant select, insert on public.mission_messages to authenticated;
grant usage, select on sequence public.mission_messages_id_seq to authenticated;
grant select on public.stamp_definitions to authenticated;
grant select on public.user_stamps to authenticated;
grant select on public.badge_definitions to authenticated;
grant select on public.user_badges to authenticated;
grant select on public.xp_ledger to authenticated;
grant select, insert, update, delete on public.reflections to authenticated;
grant select, insert, update, delete on public.diary_entries to authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;

-- User and Profile policies.

create policy profiles_select
on public.profiles for select to authenticated
using ((select public.can_view_profile(id)));

create policy profiles_insert_own
on public.profiles for insert to authenticated
with check (id = (select auth.uid()));

create policy profiles_update_own
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- Mission Discovery policies.

create policy destinations_select_after_verified_visit
on public.destinations for select to authenticated
using ((select public.can_view_destination(id)));

create policy mission_requests_select_own
on public.mission_requests for select to authenticated
using (user_id = (select auth.uid()));

create policy mission_requests_insert_own
on public.mission_requests for insert to authenticated
with check (user_id = (select auth.uid()));

create policy mission_requests_delete_own
on public.mission_requests for delete to authenticated
using (
  user_id = (select auth.uid())
  and status in ('pending', 'ready', 'no_match', 'failed', 'cancelled')
);

create policy recommendations_select_own
on public.mission_recommendations for select to authenticated
using (
  exists (
    select 1
    from public.mission_requests request
    where request.id = request_id
      and request.user_id = (select auth.uid())
  )
);

-- Mission, Clue, Hint and Collaborative policies.

create policy sessions_select_participant
on public.mission_sessions for select to authenticated
using ((select public.is_mission_participant(id)));

create policy participants_select_session
on public.mission_participants for select to authenticated
using ((select public.is_mission_participant(session_id)));

create policy current_mission_select_own
on public.user_current_missions for select to authenticated
using (user_id = (select auth.uid()));

create policy stages_select_session
on public.mission_stages for select to authenticated
using ((select public.is_mission_participant(session_id)));

create policy clue_reveals_select_unlocked
on public.mission_clue_reveals for select to authenticated
using (
  exists (
    select 1
    from public.mission_stages stage
    where stage.id = stage_id
      and stage.unlocked_at is not null
      and (select public.is_mission_participant(stage.session_id))
  )
);

create policy hint_reveals_select_own
on public.clue_hint_reveals for select to authenticated
using (user_id = (select auth.uid()));

create policy clue_progress_select_session
on public.clue_progress for select to authenticated
using (
  exists (
    select 1
    from public.mission_stages stage
    where stage.id = stage_id
      and (select public.is_mission_participant(stage.session_id))
  )
);

create policy participant_locations_select_own
on public.participant_locations for select to authenticated
using (user_id = (select auth.uid()));

create policy participant_locations_insert_own
on public.participant_locations for insert to authenticated
with check (
  user_id = (select auth.uid())
  and (select public.is_mission_participant(session_id))
);

create policy participant_locations_update_own
on public.participant_locations for update to authenticated
using (user_id = (select auth.uid()))
with check (
  user_id = (select auth.uid())
  and (select public.is_mission_participant(session_id))
);

create policy verified_visits_select_own
on public.verified_visits for select to authenticated
using (user_id = (select auth.uid()));

create policy events_select_session
on public.mission_session_events for select to authenticated
using ((select public.is_mission_participant(session_id)));

create policy invitations_select_related
on public.invitations for select to authenticated
using (
  inviter_id = (select auth.uid())
  or invitee_id = (select auth.uid())
);

create policy messages_select_session
on public.mission_messages for select to authenticated
using ((select public.is_mission_participant(session_id)));

create policy messages_insert_self
on public.mission_messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and (select public.is_mission_participant(session_id))
  and message_type in ('text', 'reaction')
);

-- Passport and Diary policies.

create policy stamp_definitions_select_earned
on public.stamp_definitions for select to authenticated
using (
  exists (
    select 1
    from public.user_stamps earned
    where earned.stamp_id = id
      and earned.user_id = (select auth.uid())
  )
);

create policy user_stamps_select_own
on public.user_stamps for select to authenticated
using (user_id = (select auth.uid()));

create policy badge_definitions_select
on public.badge_definitions for select to authenticated
using (active);

create policy user_badges_select_own
on public.user_badges for select to authenticated
using (user_id = (select auth.uid()));

create policy xp_ledger_select_own
on public.xp_ledger for select to authenticated
using (user_id = (select auth.uid()));

create policy reflections_select_own
on public.reflections for select to authenticated
using (user_id = (select auth.uid()));

create policy reflections_insert_own
on public.reflections for insert to authenticated
with check (
  user_id = (select auth.uid())
  and (select public.is_mission_participant(session_id))
  and exists (
    select 1
    from public.mission_sessions session
    where session.id = session_id
      and session.status = 'completed'
  )
);

create policy reflections_update_own
on public.reflections for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy reflections_delete_own
on public.reflections for delete to authenticated
using (user_id = (select auth.uid()));

create policy diary_entries_select
on public.diary_entries for select to authenticated
using (
  owner_user_id = (select auth.uid())
  or (
    diary_type = 'shared'
    and (select public.is_mission_participant(session_id))
  )
  or visibility = 'public'
  or (
    visibility = 'participants'
    and (select public.is_mission_participant(session_id))
  )
);

create policy diary_entries_insert_own
on public.diary_entries for insert to authenticated
with check (
  diary_type = 'individual'
  and owner_user_id = (select auth.uid())
  and (select public.is_mission_participant(session_id))
  and exists (
    select 1
    from public.mission_sessions session
    where session.id = session_id
      and session.status = 'completed'
  )
);

create policy diary_entries_update_own
on public.diary_entries for update to authenticated
using (
  diary_type = 'individual'
  and owner_user_id = (select auth.uid())
)
with check (
  diary_type = 'individual'
  and owner_user_id = (select auth.uid())
);

create policy diary_entries_delete_own
on public.diary_entries for delete to authenticated
using (
  diary_type = 'individual'
  and owner_user_id = (select auth.uid())
);

create policy notifications_select_own
on public.notifications for select to authenticated
using (user_id = (select auth.uid()));

create policy notifications_update_own
on public.notifications for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- Private Storage buckets. Shared media is delivered through short-lived signed
-- URLs created by a protected function after it verifies mission membership.

insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', false),
  ('mission-media', 'mission-media', false),
  ('diary-media', 'diary-media', false)
on conflict (id) do nothing;

create policy storage_select_owned
on storage.objects for select to authenticated
using (
  bucket_id in ('avatars', 'mission-media', 'diary-media')
  and owner_id = (select auth.uid())::text
);

create policy storage_insert_avatar
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy storage_insert_mission_media
on storage.objects for insert to authenticated
with check (
  bucket_id = 'mission-media'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);

create policy storage_insert_diary_media
on storage.objects for insert to authenticated
with check (
  bucket_id = 'diary-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy storage_update_owned
on storage.objects for update to authenticated
using (
  bucket_id in ('avatars', 'mission-media', 'diary-media')
  and owner_id = (select auth.uid())::text
)
with check (
  bucket_id in ('avatars', 'mission-media', 'diary-media')
  and owner_id = (select auth.uid())::text
);

create policy storage_delete_owned
on storage.objects for delete to authenticated
using (
  bucket_id in ('avatars', 'mission-media', 'diary-media')
  and owner_id = (select auth.uid())::text
);
