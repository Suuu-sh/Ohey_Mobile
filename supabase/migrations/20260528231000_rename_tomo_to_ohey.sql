-- Rename persisted pre-release Tomo identifiers to Ohey.
-- Existing dev/prod projects may already have the Tomo-era baseline applied;
-- this migration moves persisted profile defaults, public profile identifiers,
-- avatar URIs, and Supabase Storage bucket/policies to the Ohey brand.

-- Auth profile defaults ------------------------------------------------------
create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  base_user_id text;
  candidate_user_id text;
  display_name_value text;
  suffix int := 0;
begin
  base_user_id := coalesce(
    nullif(regexp_replace(lower(new.raw_user_meta_data->>'user_id'), '[^a-z0-9_]', '', 'g'), ''),
    'ohey_' || substr(new.id::text, 1, 8)
  );

  if char_length(base_user_id) < 3 then
    base_user_id := base_user_id || '_' || substr(new.id::text, 1, 8);
  end if;

  base_user_id := substr(base_user_id, 1, 20);
  candidate_user_id := base_user_id;

  while exists (select 1 from public.profiles where user_id = candidate_user_id) loop
    suffix := suffix + 1;
    candidate_user_id := substr(base_user_id, 1, greatest(3, 24 - char_length('_' || suffix::text))) || '_' || suffix::text;
  end loop;

  display_name_value := nullif(substr(coalesce(new.raw_user_meta_data->>'display_name', ''), 1, 40), '');

  insert into public.profiles (id, user_id, display_name, character_key, avatar_url)
  values (
    new.id,
    candidate_user_id,
    coalesce(display_name_value, 'Ohey'),
    coalesce(nullif(new.raw_user_meta_data->>'character_key', ''), 'icon_smile'),
    nullif(new.raw_user_meta_data->>'avatar_url', '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

-- Profile rows ---------------------------------------------------------------
update public.profiles
set avatar_url = replace(avatar_url, 'tomo_avatar:', 'ohey_avatar:')
where avatar_url like 'tomo_avatar:%';

update public.profiles p
set user_id = 'ohey_' || substr(p.user_id, 6)
where p.user_id like 'tomo\_%' escape '\'
  and not exists (
    select 1
    from public.profiles p2
    where p2.user_id = 'ohey_' || substr(p.user_id, 6)
  );

update public.profiles
set user_id = 'ohey_official',
    display_name = 'Ohey公式'
where user_id = 'tomo_official';

update public.profiles
set display_name = 'Ohey公式'
where user_id = 'ohey_official';

-- Storage bucket / policies -------------------------------------------------
drop policy if exists tomo_photos_select_visible on storage.objects;
drop policy if exists "tomo_photos_select_visible" on storage.objects;
drop policy if exists tomo_photos_authenticated_select on storage.objects;
drop policy if exists "tomo_photos_authenticated_select" on storage.objects;
drop policy if exists tomo_photos_owner_insert on storage.objects;
drop policy if exists "tomo_photos_owner_insert" on storage.objects;
drop policy if exists tomo_photos_owner_update on storage.objects;
drop policy if exists "tomo_photos_owner_update" on storage.objects;
drop policy if exists tomo_photos_owner_delete on storage.objects;
drop policy if exists "tomo_photos_owner_delete" on storage.objects;
drop policy if exists tomo_photos_insert_own on storage.objects;
drop policy if exists "tomo_photos_insert_own" on storage.objects;
drop policy if exists tomo_photos_select_own on storage.objects;
drop policy if exists tomo_photos_update_own on storage.objects;
drop policy if exists tomo_photos_delete_own on storage.objects;

drop policy if exists ohey_photos_select_visible on storage.objects;
drop policy if exists ohey_photos_owner_insert on storage.objects;
drop policy if exists ohey_photos_owner_update on storage.objects;
drop policy if exists ohey_photos_owner_delete on storage.objects;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'ohey-photos',
  'ohey-photos',
  false,
  15728640,
  array['image/jpeg', 'image/png', 'image/heic', 'image/webp']
)
on conflict (id) do update set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

update storage.objects
set bucket_id = 'ohey-photos'
where bucket_id = 'tomo-photos';

-- Supabase protects direct deletion from storage tables in hosted projects.
-- Keep the legacy bucket row if it still exists; the app now uses ohey-photos.

create policy ohey_photos_select_visible
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'ohey-photos'
    and (
      name like ('users/' || auth.uid()::text || '/%')
      or exists (
        select 1
        from public.memories m
        where m.photo_path = storage.objects.name
          and (
            m.is_official = true
            or m.owner_user_id = auth.uid()
            or exists (
              select 1
              from public.friendships f
              where (f.user_a_id = auth.uid() and f.user_b_id = m.owner_user_id)
                 or (f.user_b_id = auth.uid() and f.user_a_id = m.owner_user_id)
            )
          )
      )
    )
  );

create policy ohey_photos_owner_insert
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'ohey-photos'
    and name like ('users/' || auth.uid()::text || '/%')
  );

create policy ohey_photos_owner_update
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'ohey-photos'
    and name like ('users/' || auth.uid()::text || '/%')
  )
  with check (
    bucket_id = 'ohey-photos'
    and name like ('users/' || auth.uid()::text || '/%')
  );

create policy ohey_photos_owner_delete
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'ohey-photos'
    and name like ('users/' || auth.uid()::text || '/%')
  );
