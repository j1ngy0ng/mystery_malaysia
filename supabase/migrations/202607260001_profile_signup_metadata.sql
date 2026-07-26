-- Keep the public profile aligned with metadata supplied during sign-up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    nullif(trim(new.raw_user_meta_data ->> 'username'), ''),
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''),
      'Explorer'
    )
  )
  on conflict (id) do update
  set
    username = coalesce(excluded.username, public.profiles.username),
    display_name = excluded.display_name;
  return new;
end;
$$;
