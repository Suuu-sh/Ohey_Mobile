-- User-level reports from friend detail / safety menus.
-- Keep the table protected with RLS even though writes go through the backend.

create table if not exists public.user_reports (
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

create index if not exists user_reports_status_created_at_idx
  on public.user_reports(status, created_at desc);

create index if not exists user_reports_reported_created_at_idx
  on public.user_reports(reported_user_id, created_at desc);

alter table public.user_reports enable row level security;

drop policy if exists user_reports_select_reporter on public.user_reports;
create policy user_reports_select_reporter
  on public.user_reports
  for select
  to authenticated
  using (reporter_user_id = (select auth.uid()));

drop policy if exists user_reports_insert_reporter on public.user_reports;
create policy user_reports_insert_reporter
  on public.user_reports
  for insert
  to authenticated
  with check (
    reporter_user_id = (select auth.uid())
    and reported_user_id <> (select auth.uid())
    and status = 'pending'
  );

drop policy if exists user_reports_update_reporter on public.user_reports;
create policy user_reports_update_reporter
  on public.user_reports
  for update
  to authenticated
  using (reporter_user_id = (select auth.uid()))
  with check (
    reporter_user_id = (select auth.uid())
    and reported_user_id <> (select auth.uid())
    and status = 'pending'
  );

grant select, insert, update on public.user_reports to authenticated;
grant all on public.user_reports to service_role;
