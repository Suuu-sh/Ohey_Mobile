-- Remove legacy permissive policies that would weaken the hardened policies, and
-- move the helper used by RLS out of the exposed public schema.

create schema if not exists private;

create or replace function private.profile_is_plus_unchanged(
  profile_id uuid,
  requested_is_plus boolean
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select p.is_plus = requested_is_plus
      from public.profiles p
      where p.id = profile_id
    ),
    false
  );
$$;

revoke all on function private.profile_is_plus_unchanged(uuid, boolean) from public;
grant usage on schema private to authenticated;
grant execute on function private.profile_is_plus_unchanged(uuid, boolean) to authenticated;

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and private.profile_is_plus_unchanged(id, is_plus)
  );

drop function if exists public.profile_is_plus_unchanged(uuid, boolean);

-- Legacy policy allowed attaching any UUID to an owned drink log. The hardened
-- replacement additionally requires an existing friendship.
drop policy if exists drink_log_friends_insert_owner on public.drink_log_friends;

-- Legacy owner-only read is redundant; keep the feed-visible policy as the
-- single read model for drink log friend links.
drop policy if exists drink_log_friends_select_owner on public.drink_log_friends;

-- Legacy owner-only Storage policies used a pre-`users/<uuid>/...` folder shape
-- and are now redundant. Keep the explicit `users/<auth.uid>/...` owner policies
-- plus `nomo_photos_select_visible`.
drop policy if exists nomo_photos_select_own on storage.objects;
drop policy if exists nomo_photos_update_own on storage.objects;
drop policy if exists nomo_photos_delete_own on storage.objects;
