-- Notifications delivered to users when someone reacts to their content.
-- Likes are created by the Render backend with the service role key; clients can
-- only read their own notifications and mark those notifications as read.

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  actor_user_id uuid references public.profiles(id) on delete set null,
  drink_log_id uuid references public.drink_logs(id) on delete cascade,
  kind text not null check (kind in ('drink_log_like')),
  title text not null,
  message text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  constraint notifications_no_self_actor check (actor_user_id is null or actor_user_id <> recipient_user_id),
  constraint notifications_unique_like unique (recipient_user_id, actor_user_id, drink_log_id, kind)
);

create index if not exists notifications_recipient_created_at_idx
on public.notifications (recipient_user_id, created_at desc);

create index if not exists notifications_recipient_unread_idx
on public.notifications (recipient_user_id, created_at desc)
where read_at is null;

alter table public.notifications enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
on public.notifications
for select
to authenticated
using (auth.uid() = recipient_user_id);

drop policy if exists "notifications_update_own_read_state" on public.notifications;
create policy "notifications_update_own_read_state"
on public.notifications
for update
to authenticated
using (auth.uid() = recipient_user_id)
with check (auth.uid() = recipient_user_id);

grant select, update on public.notifications to authenticated;
