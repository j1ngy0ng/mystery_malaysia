-- Fields and invitation metadata required by the final use cases.

alter table public.profiles
  add column if not exists gender text
    check (gender is null or gender in ('female', 'male', 'non_binary', 'prefer_not_to_say')),
  add column if not exists date_of_birth date
    check (date_of_birth is null or date_of_birth <= current_date),
  add column if not exists phone_number text
    check (phone_number is null or char_length(phone_number) between 7 and 30);

alter table public.invitations
  alter column invitee_id drop not null,
  add column if not exists invitee_email text,
  add column if not exists invitation_token uuid not null default gen_random_uuid(),
  add constraint invitations_invitee_target_check
    check (invitee_id is not null or invitee_email is not null);

create unique index if not exists invitations_token_idx
  on public.invitations (invitation_token);

create unique index if not exists invitations_session_email_idx
  on public.invitations (session_id, lower(invitee_email))
  where invitee_email is not null and status = 'pending';

insert into public.badge_definitions (code, name, description, artwork_path, criteria)
values
  ('first_steps', 'First Steps', 'Complete your first mystery mission.', 'badges/first-steps', '{"completed_missions":1}'),
  ('clue_cracker', 'Clue Cracker', 'Verify ten mystery destinations.', 'badges/clue-cracker', '{"verified_destinations":10}'),
  ('jalan_jalan', 'Jalan-Jalan', 'Explore three Malaysian states.', 'badges/jalan-jalan', '{"explored_states":3}'),
  ('team_spirit', 'Team Spirit', 'Complete a shared mystery mission.', 'badges/team-spirit', '{"shared_missions":1}')
on conflict (code) do update
set
  name = excluded.name,
  description = excluded.description,
  artwork_path = excluded.artwork_path,
  criteria = excluded.criteria,
  active = true;

create or replace function public.is_username_available(candidate text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not exists (
    select 1
    from public.profiles
    where lower(username) = lower(trim(candidate))
  );
$$;

grant execute on function public.is_username_available(text)
  to anon, authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (
    id,
    username,
    display_name,
    gender,
    date_of_birth,
    phone_number
  )
  values (
    new.id,
    nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      'Explorer'
    ),
    nullif(trim(new.raw_user_meta_data ->> 'gender'), ''),
    nullif(trim(new.raw_user_meta_data ->> 'date_of_birth'), '')::date,
    nullif(trim(new.raw_user_meta_data ->> 'phone_number'), '')
  )
  on conflict (id) do update
  set
    username = coalesce(excluded.username, public.profiles.username),
    display_name = excluded.display_name,
    gender = coalesce(excluded.gender, public.profiles.gender),
    date_of_birth = coalesce(excluded.date_of_birth, public.profiles.date_of_birth),
    phone_number = coalesce(excluded.phone_number, public.profiles.phone_number);
  return new;
end;
$$;
