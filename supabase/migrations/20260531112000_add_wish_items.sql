create table if not exists public.wish_items (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  note text not null default '',
  category text not null default 'other' check (category in ('food','drink','cafe','sauna','work','walk','drive','event','other')),
  place_text text not null default '',
  place_url text not null default '',
  visibility text not null default 'private' check (visibility in ('private','friends','group')),
  status text not null default 'active' check (status in ('active','archived','done')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.yurubos add column if not exists wish_item_id uuid references public.wish_items(id) on delete set null;

create index if not exists wish_items_owner_created_idx on public.wish_items(owner_user_id, created_at desc);
create index if not exists yurubos_wish_item_idx on public.yurubos(wish_item_id);

alter table public.wish_items enable row level security;

drop policy if exists wish_items_select_owner_or_friend on public.wish_items;
create policy wish_items_select_owner_or_friend
  on public.wish_items for select to authenticated
  using (
    owner_user_id = auth.uid()
    or (
      visibility = 'friends'
      and exists (
        select 1 from public.friendships f
        where (f.user_a_id = auth.uid() and f.user_b_id = wish_items.owner_user_id)
           or (f.user_b_id = auth.uid() and f.user_a_id = wish_items.owner_user_id)
      )
    )
  );

drop policy if exists wish_items_insert_owner on public.wish_items;
create policy wish_items_insert_owner
  on public.wish_items for insert to authenticated
  with check (owner_user_id = auth.uid());

drop policy if exists wish_items_update_owner on public.wish_items;
create policy wish_items_update_owner
  on public.wish_items for update to authenticated
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

drop policy if exists wish_items_delete_owner on public.wish_items;
create policy wish_items_delete_owner
  on public.wish_items for delete to authenticated
  using (owner_user_id = auth.uid());

grant select, insert, update, delete on public.wish_items to authenticated;
