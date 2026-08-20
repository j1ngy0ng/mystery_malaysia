-- Reject the 51st Auth user regardless of which client attempts signup.
create or replace function public.enforce_auth_user_limit(event jsonb)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  auth_user_count bigint;
begin
  -- Serialize concurrent signups so two requests cannot both claim slot 50.
  perform pg_catalog.pg_advisory_xact_lock(5060660);

  select count(*)
  into auth_user_count
  from auth.users;

  if auth_user_count >= 50 then
    return jsonb_build_object(
      'error', jsonb_build_object(
        'http_code', 403,
        'message', 'Registration is full. Mystery Malaysia currently supports a maximum of 50 users.'
      )
    );
  end if;

  return '{}'::jsonb;
end;
$$;

grant usage on schema public to supabase_auth_admin;
grant execute on function public.enforce_auth_user_limit(jsonb)
  to supabase_auth_admin;
revoke execute on function public.enforce_auth_user_limit(jsonb)
  from anon, authenticated, public;

comment on function public.enforce_auth_user_limit(jsonb) is
  'Before User Created Auth Hook that caps this project at 50 auth.users rows.';
