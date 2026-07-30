-- A removed member may receive and accept a new invitation later.
alter table public.invitations
  drop constraint if exists invitations_session_id_invitee_id_key;

create unique index if not exists invitations_session_invitee_pending_idx
  on public.invitations (session_id, invitee_id)
  where invitee_id is not null and status = 'pending';
