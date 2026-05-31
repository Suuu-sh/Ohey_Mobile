-- Remove unused photo-posting storage/schema and the free-text reaction message.
-- QR image saving remains a client-only Photos add flow and does not use Supabase Storage.

drop policy if exists ohey_photos_select_visible on storage.objects;
drop policy if exists "ohey_photos_select_visible" on storage.objects;
drop policy if exists ohey_photos_authenticated_select on storage.objects;
drop policy if exists "ohey_photos_authenticated_select" on storage.objects;
drop policy if exists ohey_photos_owner_insert on storage.objects;
drop policy if exists "ohey_photos_owner_insert" on storage.objects;
drop policy if exists ohey_photos_owner_update on storage.objects;
drop policy if exists "ohey_photos_owner_update" on storage.objects;
drop policy if exists ohey_photos_owner_delete on storage.objects;
drop policy if exists "ohey_photos_owner_delete" on storage.objects;
drop policy if exists ohey_photos_insert_own on storage.objects;
drop policy if exists "ohey_photos_insert_own" on storage.objects;
drop policy if exists ohey_photos_select_own on storage.objects;
drop policy if exists "ohey_photos_select_own" on storage.objects;
drop policy if exists ohey_photos_update_own on storage.objects;
drop policy if exists "ohey_photos_update_own" on storage.objects;
drop policy if exists ohey_photos_delete_own on storage.objects;
drop policy if exists "ohey_photos_delete_own" on storage.objects;

alter table if exists public.memories
  drop column if exists caption_y,
  drop column if exists photo_path,
  drop column if exists marker_rarity;

alter table if exists public.yurubo_reactions
  drop column if exists message;

delete from storage.buckets
where id = 'ohey-photos'
  and not exists (
    select 1
    from storage.objects
    where bucket_id = 'ohey-photos'
  );
