-- ==========================================
-- FIX AVATAR STORAGE RLS FOR PROFILE UPLOAD
-- ==========================================
-- Why this migration exists:
-- 1) Avatar upload uses a deterministic object path: <auth.uid()>/avatar.jpg.
-- 2) Owner-based checks can fail on legacy objects or upsert/update flows.
-- 3) Path-based checks are deterministic and idempotent across environments.

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update
set public = excluded.public;

-- Remove legacy avatar policy variants (safe if they do not exist).
drop policy if exists "Avatar images are publicly readable" on storage.objects;
drop policy if exists "Users can upload own avatar" on storage.objects;
drop policy if exists "Users can update own avatar" on storage.objects;
drop policy if exists "Users can delete own avatar" on storage.objects;
drop policy if exists "Authenticated can upload avatars" on storage.objects;
drop policy if exists "Users can update avatars by path" on storage.objects;
drop policy if exists "Users can delete avatars by path" on storage.objects;

create policy "Avatar images are publicly readable"
on storage.objects
for select
to public
using (bucket_id = 'avatars');

create policy "Authenticated can upload avatars"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can update avatars by path"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "Users can delete avatars by path"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
