-- Allow authenticated users to create and read their own friendship rows.
-- This fixes friend exchange/search where the client inserts the ordered
-- (user_a_id, user_b_id) pair after finding a profile by exact user_id.

alter table public.friendships enable row level security;

drop policy if exists "friendships_select_own" on public.friendships;
create policy "friendships_select_own"
on public.friendships
for select
to authenticated
using (auth.uid() = user_a_id or auth.uid() = user_b_id);

drop policy if exists "friendships_insert_own_ordered" on public.friendships;
create policy "friendships_insert_own_ordered"
on public.friendships
for insert
to authenticated
with check (
  user_a_id < user_b_id
  and user_a_id <> user_b_id
  and (auth.uid() = user_a_id or auth.uid() = user_b_id)
);

drop policy if exists "friendships_update_own" on public.friendships;
create policy "friendships_update_own"
on public.friendships
for update
to authenticated
using (auth.uid() = user_a_id or auth.uid() = user_b_id)
with check (
  user_a_id < user_b_id
  and user_a_id <> user_b_id
  and (auth.uid() = user_a_id or auth.uid() = user_b_id)
);
