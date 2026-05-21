-- Official posts must be created through the trusted admin backend only.
-- Regular authenticated clients may still create normal drink logs, but cannot
-- insert or update rows into official posts. The service-role admin backend
-- bypasses RLS and remains the only path that can set is_official = true.

alter table public.drink_logs
  add column if not exists is_official boolean not null default false;

drop policy if exists "drink_logs_non_official_insert_only" on public.drink_logs;
create policy "drink_logs_non_official_insert_only"
  on public.drink_logs
  as restrictive
  for insert
  to authenticated
  with check (is_official = false);

drop policy if exists "drink_logs_non_official_update_only" on public.drink_logs;
create policy "drink_logs_non_official_update_only"
  on public.drink_logs
  as restrictive
  for update
  to authenticated
  using (is_official = false)
  with check (is_official = false);
