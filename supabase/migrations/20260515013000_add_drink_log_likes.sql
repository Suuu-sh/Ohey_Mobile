create table if not exists public.drink_log_likes (
  drink_log_id uuid not null references public.drink_logs(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (drink_log_id, user_id)
);

create index if not exists drink_log_likes_user_id_idx
  on public.drink_log_likes(user_id);

alter table public.drink_log_likes enable row level security;

drop policy if exists "drink_log_likes_select_authenticated" on public.drink_log_likes;
create policy "drink_log_likes_select_authenticated"
  on public.drink_log_likes
  for select
  to authenticated
  using (true);

drop policy if exists "drink_log_likes_insert_own" on public.drink_log_likes;
create policy "drink_log_likes_insert_own"
  on public.drink_log_likes
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "drink_log_likes_delete_own" on public.drink_log_likes;
create policy "drink_log_likes_delete_own"
  on public.drink_log_likes
  for delete
  to authenticated
  using (auth.uid() = user_id);
