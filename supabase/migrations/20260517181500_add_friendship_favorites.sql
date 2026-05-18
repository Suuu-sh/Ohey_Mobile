alter table public.friendships
  add column if not exists is_favorite boolean not null default false;

create index if not exists idx_friendships_user_a_favorite
  on public.friendships(user_a_id, is_favorite);

create index if not exists idx_friendships_user_b_favorite
  on public.friendships(user_b_id, is_favorite);
