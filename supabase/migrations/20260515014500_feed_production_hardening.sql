create index if not exists drink_logs_owner_drank_at_idx
  on public.drink_logs(owner_user_id, drank_at desc);

create table if not exists public.drink_log_reports (
  id uuid primary key default gen_random_uuid(),
  drink_log_id uuid not null references public.drink_logs(id) on delete cascade,
  reporter_user_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null default 'other',
  created_at timestamptz not null default now(),
  unique (drink_log_id, reporter_user_id)
);

alter table public.drink_log_reports enable row level security;

drop policy if exists "drink_log_reports_insert_own" on public.drink_log_reports;
create policy "drink_log_reports_insert_own"
  on public.drink_log_reports
  for insert
  to authenticated
  with check (auth.uid() = reporter_user_id);

drop policy if exists "drink_log_reports_select_own" on public.drink_log_reports;
create policy "drink_log_reports_select_own"
  on public.drink_log_reports
  for select
  to authenticated
  using (auth.uid() = reporter_user_id);

grant select, insert on public.drink_log_reports to authenticated;
grant select, insert, delete on public.drink_log_likes to authenticated;

drop policy if exists "drink_logs_select_feed_visible" on public.drink_logs;
create policy "drink_logs_select_feed_visible"
  on public.drink_logs
  for select
  to authenticated
  using (
    owner_user_id = auth.uid()
    or exists (
      select 1
      from public.friendships f
      where (f.user_a_id = auth.uid() and f.user_b_id = drink_logs.owner_user_id)
         or (f.user_b_id = auth.uid() and f.user_a_id = drink_logs.owner_user_id)
    )
  );

drop policy if exists "drink_logs_delete_own" on public.drink_logs;
create policy "drink_logs_delete_own"
  on public.drink_logs
  for delete
  to authenticated
  using (owner_user_id = auth.uid());

grant select, delete on public.drink_logs to authenticated;
grant select on public.drink_log_friends to authenticated;
