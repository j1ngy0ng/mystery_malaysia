-- Product requirement: show a field-level distinction between an unknown
-- email and an incorrect password before calling Supabase password login.
create or replace function public.is_email_registered(candidate text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users
    where lower(email) = lower(trim(candidate))
  );
$$;

revoke all on function public.is_email_registered(text) from public;
grant execute on function public.is_email_registered(text) to anon, authenticated;
