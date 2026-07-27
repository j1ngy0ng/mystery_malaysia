-- Allow a sensible number of simultaneous missions per destination while
-- keeping reservation decisions atomic under concurrent requests.

drop index if exists public.destination_one_live_allocation_idx;

alter table public.destinations
  alter column capacity_per_slot set default 3,
  drop constraint if exists destinations_capacity_per_slot_check;

update public.destinations
set capacity_per_slot = case
  when 'Nature' = any(categories) then 6
  when 'Food' = any(categories) then 4
  else 3
end;

alter table public.destinations
  add constraint destinations_capacity_per_slot_check
    check (capacity_per_slot between 2 and 12);

create or replace function public.reserve_destination_capacity(
  p_destination_id uuid,
  p_user_id uuid,
  p_request_id uuid,
  p_recommendation_id uuid,
  p_expires_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  allocation_id uuid;
  destination_capacity integer;
  live_allocations integer;
begin
  if p_expires_at <= now() then
    raise exception 'Reservation expiry must be in the future';
  end if;

  -- The row lock makes the capacity check and insert one atomic decision.
  select capacity_per_slot
  into destination_capacity
  from public.destinations
  where id = p_destination_id and active
  for update;

  if destination_capacity is null then
    return null;
  end if;

  select count(*)
  into live_allocations
  from public.destination_allocations
  where destination_id = p_destination_id
    and status in ('reserved', 'active')
    and (status = 'active' or expires_at > now());

  if live_allocations >= destination_capacity then
    return null;
  end if;

  insert into public.destination_allocations (
    destination_id,
    user_id,
    request_id,
    recommendation_id,
    status,
    expires_at
  )
  values (
    p_destination_id,
    p_user_id,
    p_request_id,
    p_recommendation_id,
    'reserved',
    p_expires_at
  )
  returning id into allocation_id;

  return allocation_id;
end;
$$;

revoke all on function public.reserve_destination_capacity(
  uuid,
  uuid,
  uuid,
  uuid,
  timestamptz
) from public, anon, authenticated;

grant execute on function public.reserve_destination_capacity(
  uuid,
  uuid,
  uuid,
  uuid,
  timestamptz
) to service_role;
