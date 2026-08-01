-- A selected solo mission is persisted before the traveller starts it.
alter table public.mission_sessions
  drop constraint mission_sessions_status_check;

alter table public.mission_sessions
  add constraint mission_sessions_status_check
  check (status in ('ready', 'waiting', 'active', 'paused', 'completed', 'abandoned'));

comment on table public.user_current_missions is
  'One row per user enforces one ready, waiting, active, or paused mission at a time.';
