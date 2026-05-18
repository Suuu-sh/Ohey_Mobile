-- Official feed posts are stored as drink_logs so they can reuse feed rendering.
-- They are created only by the trusted backend/admin path and visible to every
-- authenticated user regardless of friendship.

alter table public.drink_logs
  add column if not exists is_official boolean not null default false;

create index if not exists drink_logs_official_drank_at_idx
on public.drink_logs (drank_at desc)
where is_official = true;

drop policy if exists "drink_logs_select_feed_visible" on public.drink_logs;
create policy "drink_logs_select_feed_visible"
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
