-- Friend requests are pending applications, not direct friendships.
-- Users can only see requests involving themselves and can only create
-- outgoing pending requests from their own account.

alter table public.friend_requests enable row level security;

drop policy if exists "friend_requests_select_own" on public.friend_requests;
create policy "friend_requests_select_own"
on public.friend_requests
for select
to authenticated
using (auth.uid() = from_user_id or auth.uid() = to_user_id);

drop policy if exists "friend_requests_insert_outgoing_pending" on public.friend_requests;
create policy "friend_requests_insert_outgoing_pending"
on public.friend_requests
for insert
to authenticated
with check (
  auth.uid() = from_user_id
  and from_user_id <> to_user_id
  and status = 'pending'
);

drop policy if exists "friend_requests_update_own_pending" on public.friend_requests;
create policy "friend_requests_update_own_pending"
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
