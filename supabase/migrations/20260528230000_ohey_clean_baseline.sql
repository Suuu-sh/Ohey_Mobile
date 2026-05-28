-- Ohey clean destructive baseline.
-- Pre-release reset: dev/prod data are test data and may be removed.
-- This baseline replaces the historical drink_* migrations with the final
-- generic memories/invites domain schema.
-- Storage objects must be deleted via the Supabase Storage API, not SQL.

begin;

create extension if not exists pgcrypto;
create schema if not exists private;

drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists profiles_set_updated_at on public.profiles;
drop trigger if exists friend_requests_after_update on public.friend_requests;

-- Remove old Storage policies before dropping tables referenced by policy bodies.
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
drop policy if exists ohey_photos_update_own on storage.objects;
drop policy if exists ohey_photos_delete_own on storage.objects;

-- Drop all app-owned tables. This intentionally removes pre-release test data.
drop table if exists public.notification_outbox cascade;
drop table if exists public.notifications cascade;
drop table if exists public.memory_hides cascade;
drop table if exists public.memory_reports cascade;
drop table if exists public.memory_likes cascade;
drop table if exists public.memory_tagged_users cascade;
drop table if exists public.invites cascade;
drop table if exists public.memories cascade;
drop table if exists public.user_reports cascade;
drop table if exists public.user_mutes cascade;
drop table if exists public.user_blocks cascade;
drop table if exists public.friend_group_members cascade;
drop table if exists public.friend_groups cascade;
drop table if exists public.push_tokens cascade;
drop table if exists public.feed_hidden_drink_logs cascade;
drop table if exists public.drink_log_reports cascade;
drop table if exists public.drink_log_likes cascade;
drop table if exists public.drink_log_friends cascade;
drop table if exists public.drink_invites cascade;
drop table if exists public.drink_logs cascade;
drop table if exists public.daily_statuses cascade;
drop table if exists public.friend_requests cascade;
drop table if exists public.friendships cascade;
drop table if exists public.profiles cascade;
drop table if exists public.dev_seed_friends cascade;

-- Remove legacy helper functions left by old migrations/dev seeds.
drop function if exists public.raise_exception(text);
drop function if exists public.profile_is_plus_unchanged(uuid, boolean);
drop function if exists private.profile_is_plus_unchanged(uuid, boolean);
drop function if exists public.set_updated_at();
drop function if exists private.set_updated_at();
drop function if exists public.handle_new_user();
drop function if exists private.handle_new_user();
drop function if exists public.handle_friend_request_accepted();
drop function if exists private.handle_friend_request_accepted();

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

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

create or replace function private.handle_friend_request_accepted()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'accepted' and old.status is distinct from 'accepted' then
    insert into public.friendships (user_a_id, user_b_id)
    values (least(new.from_user_id, new.to_user_id), greatest(new.from_user_id, new.to_user_id))
    on conflict do nothing;
    new.responded_at = coalesce(new.responded_at, now());
  elsif new.status in ('rejected', 'cancelled') and old.status is distinct from new.status then
    new.responded_at = coalesce(new.responded_at, now());
  end if;

  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  user_id text not null unique,
  display_name text not null,
  gender text not null default 'unspecified',
  character_key text not null default 'icon_smile',
  avatar_url text,
  is_plus boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_user_id_format check (user_id ~ '^[a-zA-Z0-9_]{3,24}$'),
  constraint profiles_display_name_length check (char_length(display_name) between 1 and 40),
  constraint profiles_gender_check check (gender in ('unspecified', 'male', 'female'))
);

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

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function private.set_updated_at();

create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_user();

-- Backfill profiles for existing Auth users when this baseline is applied to
-- pre-release dev/prod projects. New users are handled by the Auth trigger above.
insert into public.profiles (id, user_id, display_name, character_key, avatar_url)
select
  u.id,
  'ohey_' || right(replace(u.id::text, '-', ''), 12),
  coalesce(
    nullif(substr(u.raw_user_meta_data->>'display_name', 1, 40), ''),
    nullif(substr(split_part(coalesce(u.email, ''), '@', 1), 1, 40), ''),
    'Ohey'
  ),
  coalesce(nullif(u.raw_user_meta_data->>'character_key', ''), 'icon_smile'),
  nullif(u.raw_user_meta_data->>'avatar_url', '')
from auth.users u
where not exists (
  select 1
  from public.profiles p
  where p.id = u.id
)
on conflict (id) do nothing;

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_a_id uuid not null references public.profiles(id) on delete cascade,
  user_b_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  is_favorite boolean not null default false,
  constraint friendships_no_self check (user_a_id <> user_b_id),
  constraint friendships_ordered check (user_a_id < user_b_id),
  unique (user_a_id, user_b_id)
);

create index idx_friendships_user_b_id on public.friendships(user_b_id);
create index idx_friendships_user_a_favorite on public.friendships(user_a_id, is_favorite);
create index idx_friendships_user_b_favorite on public.friendships(user_b_id, is_favorite);

create table public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references public.profiles(id) on delete cascade,
  to_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint friend_requests_no_self check (from_user_id <> to_user_id)
);

create index idx_friend_requests_from_user_id on public.friend_requests(from_user_id);
create index idx_friend_requests_to_user_id on public.friend_requests(to_user_id);
create unique index friend_requests_unique_pending
  on public.friend_requests (least(from_user_id, to_user_id), greatest(from_user_id, to_user_id))
  where status = 'pending';

create trigger friend_requests_after_update
before update on public.friend_requests
for each row execute function private.handle_friend_request_accepted();

create table public.daily_statuses (
  user_id uuid not null references public.profiles(id) on delete cascade,
  status_date date not null default current_date,
  status text not null default 'unselected'
    check (status in ('unselected', 'available', 'maybe_available', 'depends_on_time', 'has_plans')),
  updated_at timestamptz not null default now(),
  primary key (user_id, status_date)
);

create table public.friend_groups (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  client_id text not null,
  name text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_user_id, client_id),
  constraint friend_groups_client_id_format check (client_id ~ '^[A-Za-z0-9_-]{1,64}$'),
  constraint friend_groups_name_length check (char_length(name) between 1 and 24)
);

create index friend_groups_owner_sort_idx on public.friend_groups(owner_user_id, sort_order, created_at);

create table public.friend_group_members (
  group_id uuid not null references public.friend_groups(id) on delete cascade,
  friend_user_id uuid not null references public.profiles(id) on delete cascade,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  primary key (group_id, friend_user_id)
);

create index friend_group_members_friend_idx on public.friend_group_members(friend_user_id, created_at desc);

create table public.user_blocks (
  blocker_user_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  primary key (blocker_user_id, blocked_user_id),
  constraint user_blocks_no_self check (blocker_user_id <> blocked_user_id)
);

create index user_blocks_blocked_idx on public.user_blocks(blocked_user_id, created_at desc);

create table public.user_mutes (
  muter_user_id uuid not null references public.profiles(id) on delete cascade,
  muted_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (muter_user_id, muted_user_id),
  constraint user_mutes_no_self check (muter_user_id <> muted_user_id)
);

create index user_mutes_muted_idx on public.user_mutes(muted_user_id, created_at desc);

create table public.user_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references public.profiles(id) on delete cascade,
  reported_user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null default 'other',
  status text not null default 'pending',
  reviewed_at timestamptz,
  reviewed_by_user_id uuid references public.profiles(id) on delete set null,
  moderation_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (reporter_user_id, reported_user_id),
  constraint user_reports_no_self check (reporter_user_id <> reported_user_id),
  constraint user_reports_reason_check
    check (reason in ('spam', 'harassment', 'inappropriate', 'violence', 'minor_safety', 'other')),
  constraint user_reports_status_check
    check (status in ('pending', 'reviewing', 'resolved', 'dismissed'))
);

create index user_reports_status_created_at_idx on public.user_reports(status, created_at desc);
create index user_reports_reported_created_at_idx on public.user_reports(reported_user_id, created_at desc);

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

create index memories_owner_happened_at_idx on public.memories(owner_user_id, happened_at desc);
create index memories_official_happened_at_idx on public.memories(happened_at desc) where is_official = true;

create table public.memory_tagged_users (
  memory_id uuid not null references public.memories(id) on delete cascade,
  tagged_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (memory_id, tagged_user_id)
);

create index memory_tagged_users_user_idx on public.memory_tagged_users(tagged_user_id);

create table public.memory_likes (
  memory_id uuid not null references public.memories(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (memory_id, user_id)
);

create index memory_likes_user_id_idx on public.memory_likes(user_id);

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

create index memory_reports_status_created_at_idx on public.memory_reports(status, created_at desc);
create index memory_reports_reporter_hidden_idx on public.memory_reports(reporter_user_id, hidden_at desc);

create table public.memory_hides (
  user_id uuid not null references public.profiles(id) on delete cascade,
  memory_id uuid not null references public.memories(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, memory_id)
);

create index memory_hides_memory_idx on public.memory_hides(memory_id, created_at desc);

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

create index invites_inviter_user_idx on public.invites(inviter_user_id, scheduled_date desc, status);
create index invites_invitee_user_idx on public.invites(invitee_user_id, scheduled_date desc, status);
create unique index invites_unique_active_day
  on public.invites (
    least(inviter_user_id, invitee_user_id),
    greatest(inviter_user_id, invitee_user_id),
    scheduled_date
  )
  where status in ('pending', 'accepted');

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  kind text not null,
  title text not null,
  message text not null,
  friend_request_id uuid references public.friend_requests(id) on delete cascade,
  memory_id uuid references public.memories(id) on delete cascade,
  invite_id uuid references public.invites(id) on delete cascade,
  notification_date date,
  system_key text,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  constraint notifications_no_self_actor check (actor_user_id is null or actor_user_id <> recipient_user_id),
  constraint notifications_kind_check check (
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
  )
);

create index notifications_recipient_created_at_idx on public.notifications(recipient_user_id, created_at desc);
create index notifications_recipient_unread_idx on public.notifications(recipient_user_id, created_at desc) where read_at is null;
create unique index notifications_unique_friend_request_event
  on public.notifications(recipient_user_id, friend_request_id, kind)
  where friend_request_id is not null
    and kind in ('friend_request_received', 'friend_request_accepted');
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
create unique index notifications_unique_system_key
  on public.notifications(recipient_user_id, system_key, kind)
  where system_key is not null and kind = 'system';

create table public.push_tokens (
  token text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create index push_tokens_user_id_idx on public.push_tokens(user_id);

create table public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  event_kind text not null,
  aggregate_type text not null,
  aggregate_id uuid,
  actor_user_id uuid references public.profiles(id) on delete set null,
  recipient_user_id uuid references public.profiles(id) on delete set null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending',
  attempts integer not null default 0,
  last_error text,
  next_attempt_at timestamptz,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notification_outbox_status_check
    check (status in ('pending', 'processing', 'processed', 'failed')),
  constraint notification_outbox_attempts_check check (attempts >= 0)
);

create index notification_outbox_status_next_attempt_idx on public.notification_outbox(status, next_attempt_at, created_at);
create index notification_outbox_event_idx on public.notification_outbox(event_kind, created_at desc);

-- RLS -----------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.friend_requests enable row level security;
alter table public.daily_statuses enable row level security;
alter table public.friend_groups enable row level security;
alter table public.friend_group_members enable row level security;
alter table public.user_blocks enable row level security;
alter table public.user_mutes enable row level security;
alter table public.user_reports enable row level security;
alter table public.memories enable row level security;
alter table public.memory_tagged_users enable row level security;
alter table public.memory_likes enable row level security;
alter table public.memory_reports enable row level security;
alter table public.memory_hides enable row level security;
alter table public.invites enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;
alter table public.notification_outbox enable row level security;

create policy profiles_select_authenticated
  on public.profiles
  for select
  to authenticated
  using (true);

create policy profiles_insert_own
  on public.profiles
  for insert
  to authenticated
  with check (id = auth.uid() and is_plus = false);

create policy profiles_update_own
  on public.profiles
  for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and private.profile_is_plus_unchanged(id, is_plus));

create policy friendships_select_own
  on public.friendships
  for select
  to authenticated
  using (auth.uid() = user_a_id or auth.uid() = user_b_id);

create policy friendships_insert_own_ordered
  on public.friendships
  for insert
  to authenticated
  with check (
    user_a_id < user_b_id
    and (auth.uid() = user_a_id or auth.uid() = user_b_id)
  );

create policy friendships_update_own
  on public.friendships
  for update
  to authenticated
  using (auth.uid() = user_a_id or auth.uid() = user_b_id)
  with check (
    user_a_id < user_b_id
    and (auth.uid() = user_a_id or auth.uid() = user_b_id)
  );

create policy friendships_delete_own
  on public.friendships
  for delete
  to authenticated
  using (auth.uid() = user_a_id or auth.uid() = user_b_id);

create policy friend_requests_select_own
  on public.friend_requests
  for select
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

create policy friend_requests_insert_outgoing_pending
  on public.friend_requests
  for insert
  to authenticated
  with check (
    auth.uid() = from_user_id
    and from_user_id <> to_user_id
    and status = 'pending'
    and not exists (
      select 1
      from public.user_blocks b
      where (b.blocker_user_id = from_user_id and b.blocked_user_id = to_user_id)
         or (b.blocker_user_id = to_user_id and b.blocked_user_id = from_user_id)
    )
  );

create policy friend_requests_update_own_pending
  on public.friend_requests
  for update
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id)
  with check (
    from_user_id <> to_user_id
    and (
      (auth.uid() = to_user_id and status in ('accepted', 'rejected'))
      or (auth.uid() = from_user_id and status = 'cancelled')
    )
  );

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

create policy daily_statuses_insert_own
  on public.daily_statuses
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy daily_statuses_update_own
  on public.daily_statuses
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy friend_groups_select_owner
  on public.friend_groups
  for select
  to authenticated
  using (owner_user_id = auth.uid());

create policy friend_groups_insert_owner
  on public.friend_groups
  for insert
  to authenticated
  with check (owner_user_id = auth.uid());

create policy friend_groups_update_owner
  on public.friend_groups
  for update
  to authenticated
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

create policy friend_groups_delete_owner
  on public.friend_groups
  for delete
  to authenticated
  using (owner_user_id = auth.uid());

create policy friend_group_members_select_owner
  on public.friend_group_members
  for select
  to authenticated
  using (
    exists (
      select 1 from public.friend_groups g
      where g.id = friend_group_members.group_id
        and g.owner_user_id = auth.uid()
    )
  );

create policy friend_group_members_insert_owner_friend
  on public.friend_group_members
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.friend_groups g
      where g.id = friend_group_members.group_id
        and g.owner_user_id = auth.uid()
    )
    and exists (
      select 1 from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = friend_group_members.friend_user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = friend_group_members.friend_user_id)
    )
  );

create policy friend_group_members_delete_owner
  on public.friend_group_members
  for delete
  to authenticated
  using (
    exists (
      select 1 from public.friend_groups g
      where g.id = friend_group_members.group_id
        and g.owner_user_id = auth.uid()
    )
  );

create policy user_blocks_select_participant
  on public.user_blocks
  for select
  to authenticated
  using (blocker_user_id = auth.uid() or blocked_user_id = auth.uid());

create policy user_blocks_insert_owner
  on public.user_blocks
  for insert
  to authenticated
  with check (blocker_user_id = auth.uid() and blocked_user_id <> auth.uid());

create policy user_blocks_delete_owner
  on public.user_blocks
  for delete
  to authenticated
  using (blocker_user_id = auth.uid());

create policy user_mutes_select_owner
  on public.user_mutes
  for select
  to authenticated
  using (muter_user_id = auth.uid());

create policy user_mutes_insert_owner
  on public.user_mutes
  for insert
  to authenticated
  with check (muter_user_id = auth.uid() and muted_user_id <> auth.uid());

create policy user_mutes_delete_owner
  on public.user_mutes
  for delete
  to authenticated
  using (muter_user_id = auth.uid());

create policy user_reports_select_reporter
  on public.user_reports
  for select
  to authenticated
  using (reporter_user_id = auth.uid());

create policy user_reports_insert_reporter
  on public.user_reports
  for insert
  to authenticated
  with check (
    reporter_user_id = auth.uid()
    and reported_user_id <> auth.uid()
    and status = 'pending'
  );

create policy user_reports_update_reporter
  on public.user_reports
  for update
  to authenticated
  using (reporter_user_id = auth.uid())
  with check (
    reporter_user_id = auth.uid()
    and reported_user_id <> auth.uid()
    and status = 'pending'
  );

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
    and not exists (
      select 1
      from public.user_blocks b
      where (b.blocker_user_id = auth.uid() and b.blocked_user_id = memory_tagged_users.tagged_user_id)
         or (b.blocker_user_id = memory_tagged_users.tagged_user_id and b.blocked_user_id = auth.uid())
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

create policy memory_likes_select_visible
  on public.memory_likes
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.memories m
      where m.id = memory_likes.memory_id
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

create policy memory_reports_insert_own
  on public.memory_reports
  for insert
  to authenticated
  with check (
    auth.uid() = reporter_user_id
    and status = 'pending'
  );

create policy memory_reports_select_own
  on public.memory_reports
  for select
  to authenticated
  using (auth.uid() = reporter_user_id);

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
    and not exists (
      select 1
      from public.user_blocks b
      where (b.blocker_user_id = inviter_user_id and b.blocked_user_id = invitee_user_id)
         or (b.blocker_user_id = invitee_user_id and b.blocked_user_id = inviter_user_id)
    )
  );

create policy invites_update_participants
  on public.invites
  for update
  to authenticated
  using (auth.uid() = inviter_user_id or auth.uid() = invitee_user_id)
  with check (auth.uid() = inviter_user_id or auth.uid() = invitee_user_id);

create policy notifications_select_own
  on public.notifications
  for select
  to authenticated
  using (recipient_user_id = auth.uid());

create policy notifications_update_own_read_state
  on public.notifications
  for update
  to authenticated
  using (recipient_user_id = auth.uid())
  with check (recipient_user_id = auth.uid());

create policy push_tokens_select_own
  on public.push_tokens
  for select
  to authenticated
  using (user_id = auth.uid());

create policy push_tokens_insert_own
  on public.push_tokens
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy push_tokens_update_own
  on public.push_tokens
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Grants / Data API exposure ------------------------------------------------
revoke all on table
  public.profiles,
  public.friendships,
  public.friend_requests,
  public.daily_statuses,
  public.friend_groups,
  public.friend_group_members,
  public.user_blocks,
  public.user_mutes,
  public.user_reports,
  public.memories,
  public.memory_tagged_users,
  public.memory_likes,
  public.memory_reports,
  public.memory_hides,
  public.invites,
  public.notifications,
  public.push_tokens,
  public.notification_outbox
from anon, authenticated;

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update, delete on public.friendships to authenticated;
grant select, insert, update on public.friend_requests to authenticated;
grant select, insert, update on public.daily_statuses to authenticated;
grant select, insert, update, delete on public.friend_groups to authenticated;
grant select, insert, delete on public.friend_group_members to authenticated;
grant select, insert, delete on public.user_blocks to authenticated;
grant select, insert, delete on public.user_mutes to authenticated;
grant select, insert, update on public.user_reports to authenticated;
grant select, insert, update, delete on public.memories to authenticated;
grant select, insert, delete on public.memory_tagged_users to authenticated;
grant select, insert, delete on public.memory_likes to authenticated;
grant select, insert on public.memory_reports to authenticated;
grant select, insert, delete on public.memory_hides to authenticated;
grant select, insert, update on public.invites to authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;
grant select, insert, update on public.push_tokens to authenticated;

grant all on table
  public.profiles,
  public.friendships,
  public.friend_requests,
  public.daily_statuses,
  public.friend_groups,
  public.friend_group_members,
  public.user_blocks,
  public.user_mutes,
  public.user_reports,
  public.memories,
  public.memory_tagged_users,
  public.memory_likes,
  public.memory_reports,
  public.memory_hides,
  public.invites,
  public.notifications,
  public.push_tokens,
  public.notification_outbox
 to service_role;

revoke all on public.notification_outbox from anon, authenticated;
grant all on public.notification_outbox to service_role;

grant usage on schema private to authenticated, service_role;
revoke all on function private.set_updated_at() from public;
revoke all on function private.handle_new_user() from public;
revoke all on function private.handle_friend_request_accepted() from public;
revoke all on function private.profile_is_plus_unchanged(uuid, boolean) from public;
grant execute on function private.profile_is_plus_unchanged(uuid, boolean) to authenticated;

-- Storage -------------------------------------------------------------------
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

-- Custom migration history is kept by Suuu-sh/Shared apply_migrations.sh.
-- Wipe historical pre-baseline rows so the action records only this baseline.
create table if not exists public.app_schema_migrations (
  version text primary key,
  name text not null,
  applied_at timestamptz not null default now()
);

delete from public.app_schema_migrations;
revoke all on public.app_schema_migrations from anon, authenticated;
grant all on public.app_schema_migrations to service_role;

commit;
