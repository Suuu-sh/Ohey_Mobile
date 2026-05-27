-- Backend-owned moderation state and custom friend groups.
-- User-facing APIs still use caller JWT + RLS; admin moderation uses service role.

-- Drink log reports become both a moderation queue item and a per-user hide signal.
update public.drink_log_reports
set reason = 'other'
where reason is null
   or reason not in ('spam', 'harassment', 'inappropriate', 'violence', 'minor_safety', 'other');

alter table public.drink_log_reports
  add column if not exists status text not null default 'pending',
  add column if not exists hidden_at timestamptz not null default now(),
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by_user_id uuid references public.profiles(id) on delete set null,
  add column if not exists moderation_note text;

alter table public.drink_log_reports
  drop constraint if exists drink_log_reports_reason_check;

alter table public.drink_log_reports
  add constraint drink_log_reports_reason_check
  check (reason in ('spam', 'harassment', 'inappropriate', 'violence', 'minor_safety', 'other'));

alter table public.drink_log_reports
  drop constraint if exists drink_log_reports_status_check;

alter table public.drink_log_reports
  add constraint drink_log_reports_status_check
  check (status in ('pending', 'reviewing', 'resolved', 'dismissed'));

create index if not exists drink_log_reports_status_created_at_idx
  on public.drink_log_reports(status, created_at desc);

create index if not exists drink_log_reports_reporter_hidden_idx
  on public.drink_log_reports(reporter_user_id, hidden_at desc);

-- Custom friend groups are normalized so multi-device sync works now and
-- shared groups can be added later without rewriting the public API.
create table if not exists public.friend_groups (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  client_id text not null,
  name text not null,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint friend_groups_client_id_format check (client_id ~ '^[A-Za-z0-9_-]{1,64}$'),
  constraint friend_groups_name_length check (char_length(name) between 1 and 24),
  unique (owner_user_id, client_id)
);

create table if not exists public.friend_group_members (
  group_id uuid not null references public.friend_groups(id) on delete cascade,
  friend_user_id uuid not null references public.profiles(id) on delete cascade,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  primary key (group_id, friend_user_id)
);

create index if not exists friend_groups_owner_sort_idx
  on public.friend_groups(owner_user_id, sort_order, created_at);

create index if not exists friend_group_members_friend_idx
  on public.friend_group_members(friend_user_id);

alter table public.friend_groups enable row level security;
alter table public.friend_group_members enable row level security;

drop policy if exists friend_groups_select_owner on public.friend_groups;
create policy friend_groups_select_owner
  on public.friend_groups
  for select
  to authenticated
  using (owner_user_id = auth.uid());

drop policy if exists friend_groups_insert_owner on public.friend_groups;
create policy friend_groups_insert_owner
  on public.friend_groups
  for insert
  to authenticated
  with check (owner_user_id = auth.uid());

drop policy if exists friend_groups_update_owner on public.friend_groups;
create policy friend_groups_update_owner
  on public.friend_groups
  for update
  to authenticated
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

drop policy if exists friend_groups_delete_owner on public.friend_groups;
create policy friend_groups_delete_owner
  on public.friend_groups
  for delete
  to authenticated
  using (owner_user_id = auth.uid());

drop policy if exists friend_group_members_select_owner on public.friend_group_members;
create policy friend_group_members_select_owner
  on public.friend_group_members
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.friend_groups g
      where g.id = friend_group_members.group_id
        and g.owner_user_id = auth.uid()
    )
  );

drop policy if exists friend_group_members_insert_owner_friend on public.friend_group_members;
create policy friend_group_members_insert_owner_friend
  on public.friend_group_members
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.friend_groups g
      where g.id = friend_group_members.group_id
        and g.owner_user_id = auth.uid()
    )
    and exists (
      select 1
      from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = friend_group_members.friend_user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = friend_group_members.friend_user_id)
    )
  );

drop policy if exists friend_group_members_delete_owner on public.friend_group_members;
create policy friend_group_members_delete_owner
  on public.friend_group_members
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.friend_groups g
      where g.id = friend_group_members.group_id
        and g.owner_user_id = auth.uid()
    )
  );

grant select, insert, update, delete on public.friend_groups to authenticated;
grant select, insert, delete on public.friend_group_members to authenticated;
