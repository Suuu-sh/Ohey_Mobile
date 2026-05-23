-- Security hardening for RLS and private photo access.
-- Keep authorization in Supabase policies even when clients call Supabase directly.

-- Profiles are visible to authenticated users for friend search/feed joins, but
-- writes must stay scoped to the signed-in profile.
alter table public.profiles enable row level security;

create or replace function public.profile_is_plus_unchanged(
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

revoke all on function public.profile_is_plus_unchanged(uuid, boolean) from public;
grant execute on function public.profile_is_plus_unchanged(uuid, boolean) to authenticated;

drop policy if exists profiles_select_authenticated on public.profiles;
create policy profiles_select_authenticated
  on public.profiles
  for select
  to authenticated
  using (true);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
  on public.profiles
  for insert
  to authenticated
  with check (id = auth.uid() and is_plus = false);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and public.profile_is_plus_unchanged(id, is_plus)
  );

-- Drink logs must be visible only to the owner, friends, or everyone when the
-- row is an official backend-created post.
alter table public.drink_logs enable row level security;

drop policy if exists drink_logs_select_feed_visible on public.drink_logs;
drop policy if exists "drink_logs_select_feed_visible" on public.drink_logs;
create policy drink_logs_select_feed_visible
  on public.drink_logs
  for select
  to authenticated
  using (
    is_official = true
    or owner_user_id = auth.uid()
    or exists (
      select 1
      from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = drink_logs.owner_user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = drink_logs.owner_user_id)
    )
  );

drop policy if exists drink_logs_insert_own on public.drink_logs;
create policy drink_logs_insert_own
  on public.drink_logs
  for insert
  to authenticated
  with check (owner_user_id = auth.uid());

drop policy if exists drink_logs_insert_non_official_only on public.drink_logs;
drop policy if exists drink_logs_non_official_insert_only on public.drink_logs;
drop policy if exists "drink_logs_non_official_insert_only" on public.drink_logs;
create policy drink_logs_insert_non_official_only
  on public.drink_logs
  as restrictive
  for insert
  to authenticated
  with check (is_official = false);

drop policy if exists drink_logs_update_own on public.drink_logs;
create policy drink_logs_update_own
  on public.drink_logs
  for update
  to authenticated
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

drop policy if exists drink_logs_update_non_official_only on public.drink_logs;
drop policy if exists drink_logs_non_official_update_only on public.drink_logs;
drop policy if exists "drink_logs_non_official_update_only" on public.drink_logs;
create policy drink_logs_update_non_official_only
  on public.drink_logs
  as restrictive
  for update
  to authenticated
  using (is_official = false)
  with check (is_official = false);

drop policy if exists drink_logs_delete_own on public.drink_logs;
drop policy if exists "drink_logs_delete_own" on public.drink_logs;
create policy drink_logs_delete_own
  on public.drink_logs
  for delete
  to authenticated
  using (owner_user_id = auth.uid() and is_official = false);

-- Tagged friends can only be attached to a drink log owned by the signed-in user,
-- and the tagged profile must already be a friend.
alter table public.drink_log_friends enable row level security;

drop policy if exists drink_log_friends_select_visible on public.drink_log_friends;
create policy drink_log_friends_select_visible
  on public.drink_log_friends
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.drink_logs dl
      where dl.id = drink_log_friends.drink_log_id
        and (
          dl.is_official = true
          or dl.owner_user_id = auth.uid()
          or exists (
            select 1
            from public.friendships f
            where (f.user_a_id = auth.uid() and f.user_b_id = dl.owner_user_id)
               or (f.user_b_id = auth.uid() and f.user_a_id = dl.owner_user_id)
          )
        )
    )
  );

drop policy if exists drink_log_friends_insert_owner_friend on public.drink_log_friends;
create policy drink_log_friends_insert_owner_friend
  on public.drink_log_friends
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.drink_logs dl
      where dl.id = drink_log_friends.drink_log_id
        and dl.owner_user_id = auth.uid()
        and dl.is_official = false
    )
    and exists (
      select 1
      from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = drink_log_friends.friend_user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = drink_log_friends.friend_user_id)
    )
  );

drop policy if exists drink_log_friends_delete_owner on public.drink_log_friends;
create policy drink_log_friends_delete_owner
  on public.drink_log_friends
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.drink_logs dl
      where dl.id = drink_log_friends.drink_log_id
        and dl.owner_user_id = auth.uid()
        and dl.is_official = false
    )
  );

-- Daily status is visible to the owner and friends, and writable only by owner.
alter table public.daily_statuses enable row level security;

drop policy if exists daily_statuses_select_owner_or_friend on public.daily_statuses;
create policy daily_statuses_select_owner_or_friend
  on public.daily_statuses
  for select
  to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1
      from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = daily_statuses.user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = daily_statuses.user_id)
    )
  );

drop policy if exists daily_statuses_insert_own on public.daily_statuses;
create policy daily_statuses_insert_own
  on public.daily_statuses
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists daily_statuses_update_own on public.daily_statuses;
create policy daily_statuses_update_own
  on public.daily_statuses
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Replace bucket-wide read access with owner/feed-visibility based access.
drop policy if exists nomo_photos_authenticated_select on storage.objects;
drop policy if exists "nomo_photos_authenticated_select" on storage.objects;
create policy nomo_photos_select_visible
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'nomo-photos'
    and (
      name like ('users/' || auth.uid()::text || '/%')
      or exists (
        select 1
        from public.drink_logs dl
        where dl.photo_path = storage.objects.name
          and (
            dl.is_official = true
            or dl.owner_user_id = auth.uid()
            or exists (
              select 1
              from public.friendships f
              where (f.user_a_id = auth.uid() and f.user_b_id = dl.owner_user_id)
                 or (f.user_b_id = auth.uid() and f.user_a_id = dl.owner_user_id)
            )
          )
      )
    )
  );
