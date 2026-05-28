-- Notification outbox foundation, user safety controls, and per-feed hide state.
-- Backend writes the outbox with service role. User-facing safety APIs use caller JWT + RLS.

create table if not exists public.notification_outbox (
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

create index if not exists notification_outbox_status_next_attempt_idx
  on public.notification_outbox(status, next_attempt_at, created_at);

create index if not exists notification_outbox_event_idx
  on public.notification_outbox(event_kind, created_at desc);

alter table public.notification_outbox enable row level security;
revoke all on public.notification_outbox from anon, authenticated;
grant all on public.notification_outbox to service_role;

create table if not exists public.user_blocks (
  blocker_user_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid not null references public.profiles(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  primary key (blocker_user_id, blocked_user_id),
  constraint user_blocks_no_self check (blocker_user_id <> blocked_user_id)
);

create index if not exists user_blocks_blocked_idx
  on public.user_blocks(blocked_user_id, created_at desc);

alter table public.user_blocks enable row level security;

drop policy if exists user_blocks_select_participant on public.user_blocks;
create policy user_blocks_select_participant
  on public.user_blocks
  for select
  to authenticated
  using (blocker_user_id = auth.uid() or blocked_user_id = auth.uid());

drop policy if exists user_blocks_insert_owner on public.user_blocks;
create policy user_blocks_insert_owner
  on public.user_blocks
  for insert
  to authenticated
  with check (blocker_user_id = auth.uid() and blocked_user_id <> auth.uid());

drop policy if exists user_blocks_delete_owner on public.user_blocks;
create policy user_blocks_delete_owner
  on public.user_blocks
  for delete
  to authenticated
  using (blocker_user_id = auth.uid());

create table if not exists public.user_mutes (
  muter_user_id uuid not null references public.profiles(id) on delete cascade,
  muted_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (muter_user_id, muted_user_id),
  constraint user_mutes_no_self check (muter_user_id <> muted_user_id)
);

create index if not exists user_mutes_muted_idx
  on public.user_mutes(muted_user_id, created_at desc);

alter table public.user_mutes enable row level security;

drop policy if exists user_mutes_select_owner on public.user_mutes;
create policy user_mutes_select_owner
  on public.user_mutes
  for select
  to authenticated
  using (muter_user_id = auth.uid());

drop policy if exists user_mutes_insert_owner on public.user_mutes;
create policy user_mutes_insert_owner
  on public.user_mutes
  for insert
  to authenticated
  with check (muter_user_id = auth.uid() and muted_user_id <> auth.uid());

drop policy if exists user_mutes_delete_owner on public.user_mutes;
create policy user_mutes_delete_owner
  on public.user_mutes
  for delete
  to authenticated
  using (muter_user_id = auth.uid());

create table if not exists public.feed_hidden_drink_logs (
  user_id uuid not null references public.profiles(id) on delete cascade,
  drink_log_id uuid not null references public.drink_logs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, drink_log_id)
);

create index if not exists feed_hidden_drink_logs_log_idx
  on public.feed_hidden_drink_logs(drink_log_id, created_at desc);

alter table public.feed_hidden_drink_logs enable row level security;

drop policy if exists feed_hidden_drink_logs_select_owner on public.feed_hidden_drink_logs;
create policy feed_hidden_drink_logs_select_owner
  on public.feed_hidden_drink_logs
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists feed_hidden_drink_logs_insert_owner on public.feed_hidden_drink_logs;
create policy feed_hidden_drink_logs_insert_owner
  on public.feed_hidden_drink_logs
  for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists feed_hidden_drink_logs_delete_owner on public.feed_hidden_drink_logs;
create policy feed_hidden_drink_logs_delete_owner
  on public.feed_hidden_drink_logs
  for delete
  to authenticated
  using (user_id = auth.uid());

grant select, insert, delete on public.user_blocks to authenticated;
grant select, insert, delete on public.user_mutes to authenticated;
grant select, insert, delete on public.feed_hidden_drink_logs to authenticated;
