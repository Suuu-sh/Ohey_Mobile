-- Destructive pre-release domain cleanup.
-- Nomo is no longer drink-specific, so the public app schema is reset from
-- drink_logs/drink_invites naming to memories/invites naming.
-- Existing app rows and Storage object metadata are test data and are removed.

begin;

-- Remove test-only app data that references the old domain names.
delete from public.notification_outbox where aggregate_type in ('drink_log', 'drink_invite', 'memory', 'invite');
delete from public.notifications;
delete from storage.objects where bucket_id = 'nomo-photos';

-- Daily availability status values become generic.
alter table public.daily_statuses
  drop constraint if exists daily_statuses_status_check;

update public.daily_statuses
set status = case status
  when 'want_drink' then 'available'
  when 'can_drink_today' then 'available'
  when 'light_drink' then 'maybe_available'
  when 'non_alcohol' then 'maybe_available'
  when 'want_drink_hard' then 'depends_on_time'
  when 'liver_rest' then 'depends_on_time'
  when 'busy' then 'has_plans'
  else status
end;

alter table public.daily_statuses
  add constraint daily_statuses_status_check
  check (status in ('unselected', 'available', 'maybe_available', 'depends_on_time', 'has_plans'));

-- Notifications now reference memories/invites only.
alter table public.notifications
  drop constraint if exists notifications_unique_like,
  drop constraint if exists notifications_kind_check;

drop index if exists public.notifications_unique_memory_like;
drop index if exists public.notifications_unique_memory_tagged;
drop index if exists public.notifications_unique_drink_invite_event;
drop index if exists public.notifications_unique_invite_event;
drop index if exists public.notifications_unique_today_reservation_reminder;

alter table public.notifications
  drop column if exists drink_log_id cascade,
  drop column if exists drink_invite_id cascade;

-- Old and partially-created new domain tables are all test data at this stage.
drop table if exists public.memory_hides cascade;
drop table if exists public.memory_reports cascade;
drop table if exists public.memory_likes cascade;
drop table if exists public.memory_tagged_users cascade;
drop table if exists public.memories cascade;
drop table if exists public.invites cascade;
drop table if exists public.feed_hidden_drink_logs cascade;
drop table if exists public.drink_log_reports cascade;
drop table if exists public.drink_log_likes cascade;
drop table if exists public.drink_log_friends cascade;
drop table if exists public.drink_invites cascade;
drop table if exists public.drink_logs cascade;

create table public.memories (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  happened_at timestamptz not null default now(),
  place_name text,
  place_lat double precision,
  place_lng double precision,
  memo text,
  caption_y double precision not null default 0.5,
  photo_path text,
  link_url text,
  marker_rarity text not null default 'normal',
  is_official boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint memories_marker_rarity_check
    check (marker_rarity in ('normal', 'uncommon', 'rare', 'super_rare', 'ultra_rare', 'secret')),
  constraint memories_caption_y_check check (caption_y >= 0 and caption_y <= 1)
);

create index memories_owner_happened_at_idx
  on public.memories(owner_user_id, happened_at desc);

create index memories_official_happened_at_idx
  on public.memories(happened_at desc)
  where is_official = true;

alter table public.memories enable row level security;

create policy memories_select_feed_visible
  on public.memories
  for select
  to authenticated
  using (
    is_official = true
    or owner_user_id = auth.uid()
    or exists (
      select 1
      from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = memories.owner_user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = memories.owner_user_id)
    )
  );

create policy memories_insert_own
  on public.memories
  for insert
  to authenticated
  with check (owner_user_id = auth.uid());

create policy memories_insert_non_official_only
  on public.memories
  as restrictive
  for insert
  to authenticated
  with check (is_official = false);

create policy memories_update_own
  on public.memories
  for update
  to authenticated
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

create policy memories_update_non_official_only
  on public.memories
  as restrictive
  for update
  to authenticated
  using (is_official = false)
  with check (is_official = false);

create policy memories_delete_own
  on public.memories
  for delete
  to authenticated
  using (owner_user_id = auth.uid() and is_official = false);

grant select, insert, update, delete on public.memories to authenticated;

create table public.memory_tagged_users (
  memory_id uuid not null references public.memories(id) on delete cascade,
  tagged_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (memory_id, tagged_user_id)
);

create index memory_tagged_users_user_idx
  on public.memory_tagged_users(tagged_user_id);

alter table public.memory_tagged_users enable row level security;

create policy memory_tagged_users_select_visible
  on public.memory_tagged_users
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.memories m
      where m.id = memory_tagged_users.memory_id
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
  );

create policy memory_tagged_users_insert_owner_friend
  on public.memory_tagged_users
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.memories m
      where m.id = memory_tagged_users.memory_id
        and m.owner_user_id = auth.uid()
        and m.is_official = false
    )
    and exists (
      select 1
      from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = memory_tagged_users.tagged_user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = memory_tagged_users.tagged_user_id)
    )
  );

create policy memory_tagged_users_delete_owner
  on public.memory_tagged_users
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.memories m
      where m.id = memory_tagged_users.memory_id
        and m.owner_user_id = auth.uid()
        and m.is_official = false
    )
  );

grant select, insert, delete on public.memory_tagged_users to authenticated;

create table public.memory_likes (
  memory_id uuid not null references public.memories(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (memory_id, user_id)
);

create index memory_likes_user_id_idx
  on public.memory_likes(user_id);

alter table public.memory_likes enable row level security;

create policy memory_likes_select_authenticated
  on public.memory_likes
  for select
  to authenticated
  using (true);

create policy memory_likes_insert_own
  on public.memory_likes
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy memory_likes_delete_own
  on public.memory_likes
  for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, delete on public.memory_likes to authenticated;

create table public.memory_reports (
  id uuid primary key default gen_random_uuid(),
  memory_id uuid not null references public.memories(id) on delete cascade,
  reporter_user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null default 'other',
  status text not null default 'pending',
  hidden_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by_user_id uuid references public.profiles(id) on delete set null,
  moderation_note text not null default '',
  created_at timestamptz not null default now(),
  unique (memory_id, reporter_user_id),
  constraint memory_reports_reason_check
    check (reason in ('spam', 'harassment', 'inappropriate', 'violence', 'minor_safety', 'other')),
  constraint memory_reports_status_check
    check (status in ('pending', 'reviewing', 'resolved', 'dismissed'))
);

create index memory_reports_status_created_at_idx
  on public.memory_reports(status, created_at desc);

create index memory_reports_reporter_hidden_idx
  on public.memory_reports(reporter_user_id, hidden_at desc);

alter table public.memory_reports enable row level security;

create policy memory_reports_insert_own
  on public.memory_reports
  for insert
  to authenticated
  with check (auth.uid() = reporter_user_id);

create policy memory_reports_select_own
  on public.memory_reports
  for select
  to authenticated
  using (auth.uid() = reporter_user_id);

grant select, insert on public.memory_reports to authenticated;

create table public.memory_hides (
  user_id uuid not null references public.profiles(id) on delete cascade,
  memory_id uuid not null references public.memories(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, memory_id)
);

create index memory_hides_memory_idx
  on public.memory_hides(memory_id, created_at desc);

alter table public.memory_hides enable row level security;

create policy memory_hides_select_owner
  on public.memory_hides
  for select
  to authenticated
  using (user_id = auth.uid());

create policy memory_hides_insert_owner
  on public.memory_hides
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy memory_hides_delete_owner
  on public.memory_hides
  for delete
  to authenticated
  using (user_id = auth.uid());

grant select, insert, delete on public.memory_hides to authenticated;

create table public.invites (
  id uuid primary key default gen_random_uuid(),
  inviter_user_id uuid not null references public.profiles(id) on delete cascade,
  invitee_user_id uuid not null references public.profiles(id) on delete cascade,
  scheduled_date date not null default current_date,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint invites_no_self check (inviter_user_id <> invitee_user_id)
);

create index invites_inviter_user_idx
  on public.invites(inviter_user_id, scheduled_date desc, status);

create index invites_invitee_user_idx
  on public.invites(invitee_user_id, scheduled_date desc, status);

create unique index invites_unique_active_day
  on public.invites (
    least(inviter_user_id, invitee_user_id),
    greatest(inviter_user_id, invitee_user_id),
    scheduled_date
  )
  where status in ('pending', 'accepted');

alter table public.invites enable row level security;

create policy invites_select_own
  on public.invites
  for select
  to authenticated
  using (auth.uid() = inviter_user_id or auth.uid() = invitee_user_id);

create policy invites_insert_inviter
  on public.invites
  for insert
  to authenticated
  with check (
    auth.uid() = inviter_user_id
    and exists (
      select 1
      from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = invitee_user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = invitee_user_id)
    )
  );

create policy invites_update_participants
  on public.invites
  for update
  to authenticated
  using (auth.uid() = inviter_user_id or auth.uid() = invitee_user_id)
  with check (auth.uid() = inviter_user_id or auth.uid() = invitee_user_id);

grant select, insert, update on public.invites to authenticated;

alter table public.notifications
  add column if not exists memory_id uuid references public.memories(id) on delete cascade,
  add column if not exists invite_id uuid references public.invites(id) on delete cascade,
  add column if not exists notification_date date,
  add column if not exists system_key text;

alter table public.notifications
  add constraint notifications_kind_check check (
    kind in (
      'memory_like',
      'friend_request_received',
      'friend_request_accepted',
      'invite_received',
      'invite_accepted',
      'today_reservation_reminder',
      'memory_tagged',
      'system'
    )
  );

create unique index notifications_unique_memory_like
  on public.notifications(recipient_user_id, actor_user_id, memory_id, kind)
  where memory_id is not null and kind = 'memory_like';

create unique index notifications_unique_memory_tagged
  on public.notifications(recipient_user_id, memory_id, kind)
  where memory_id is not null and kind = 'memory_tagged';

create unique index notifications_unique_invite_event
  on public.notifications(recipient_user_id, invite_id, kind)
  where invite_id is not null
    and kind in ('invite_received', 'invite_accepted');

create unique index notifications_unique_today_reservation_reminder
  on public.notifications(recipient_user_id, invite_id, notification_date, kind)
  where invite_id is not null
    and notification_date is not null
    and kind = 'today_reservation_reminder';

-- Storage visibility now follows memory visibility. Upload paths use
-- users/<auth.uid>/memories/<file>.
drop policy if exists nomo_photos_select_visible on storage.objects;
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

commit;
