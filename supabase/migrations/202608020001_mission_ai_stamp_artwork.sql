alter table public.mission_sessions
  add column if not exists stamp_artwork_path text,
  add column if not exists stamp_ai_model text,
  add column if not exists stamp_prompt_version text;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'mission-stamps',
  'mission-stamps',
  false,
  10485760,
  array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

comment on column public.mission_sessions.stamp_artwork_path is
  'Private Supabase Storage path for one mission-specific AI stamp.';
