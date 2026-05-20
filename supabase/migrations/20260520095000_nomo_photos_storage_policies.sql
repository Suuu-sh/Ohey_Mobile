-- Allow authenticated Nomo users to upload their own drink-log photos and view
-- private photo objects referenced by the feed.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'nomo-photos',
  'nomo-photos',
  false,
  15728640,
  array['image/jpeg', 'image/png', 'image/heic', 'image/webp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "nomo_photos_authenticated_select" on storage.objects;
drop policy if exists "nomo_photos_owner_insert" on storage.objects;
drop policy if exists "nomo_photos_owner_update" on storage.objects;
drop policy if exists "nomo_photos_owner_delete" on storage.objects;

create policy "nomo_photos_authenticated_select"
on storage.objects
for select
to authenticated
using (bucket_id = 'nomo-photos');

create policy "nomo_photos_owner_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'nomo-photos'
  and name like ('users/' || auth.uid()::text || '/%')
);

create policy "nomo_photos_owner_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'nomo-photos'
  and name like ('users/' || auth.uid()::text || '/%')
)
with check (
  bucket_id = 'nomo-photos'
  and name like ('users/' || auth.uid()::text || '/%')
);

create policy "nomo_photos_owner_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'nomo-photos'
  and name like ('users/' || auth.uid()::text || '/%')
);
