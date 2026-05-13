-- Nomo schema hardening and indexes.
-- Applied to both nomo and dev-nomo on 2026-05-12.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all on function public.set_updated_at() from public;
revoke all on function public.handle_new_user() from public;
revoke all on function public.handle_friend_request_accepted() from public;
revoke execute on function public.set_updated_at() from anon, authenticated;
revoke execute on function public.handle_new_user() from anon, authenticated;
revoke execute on function public.handle_friend_request_accepted() from anon, authenticated;

create index if not exists idx_friend_requests_from_user_id
  on public.friend_requests(from_user_id);
create index if not exists idx_friend_requests_to_user_id
  on public.friend_requests(to_user_id);
create index if not exists idx_friendships_user_b_id
  on public.friendships(user_b_id);
create index if not exists idx_drink_logs_owner_user_id
  on public.drink_logs(owner_user_id);
create index if not exists idx_drink_log_friends_friend_user_id
  on public.drink_log_friends(friend_user_id);
