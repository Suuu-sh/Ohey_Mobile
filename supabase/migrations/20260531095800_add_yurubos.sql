create table if not exists public.yurubos (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null default '',
  category text not null default 'other' check (category in ('food','drink','cafe','sauna','work','walk','drive','event','other')),
  place_text text not null default '',
  place_lat double precision,
  place_lng double precision,
  time_label text not null default '',
  starts_at timestamptz,
  ends_at timestamptz,
  status text not null default 'open' check (status in ('open','closed','expired','cancelled','scheduled')),
  visibility text not null default 'friends' check (visibility in ('friends','private')),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.yurubo_reactions (
  id uuid primary key default gen_random_uuid(),
  yurubo_id uuid not null references public.yurubos(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reaction_type text not null default 'interested' check (reaction_type in ('interested','available','another_day')),
  message text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (yurubo_id, user_id)
);

create table if not exists public.hidden_yurubos (
  id uuid primary key default gen_random_uuid(),
  yurubo_id uuid not null references public.yurubos(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (yurubo_id, user_id)
);

create index if not exists yurubos_owner_created_idx on public.yurubos(owner_user_id, created_at desc);
create index if not exists yurubos_status_expires_idx on public.yurubos(status, expires_at);
create index if not exists yurubo_reactions_yurubo_idx on public.yurubo_reactions(yurubo_id);
create index if not exists hidden_yurubos_user_idx on public.hidden_yurubos(user_id);

alter table public.yurubos enable row level security;
alter table public.yurubo_reactions enable row level security;
alter table public.hidden_yurubos enable row level security;

create policy yurubos_select_owner_or_friend
  on public.yurubos for select to authenticated
  using (
    owner_user_id = auth.uid()
    or (
      visibility = 'friends'
      and exists (
        select 1 from public.friendships f
        where (f.user_a_id = auth.uid() and f.user_b_id = yurubos.owner_user_id)
           or (f.user_b_id = auth.uid() and f.user_a_id = yurubos.owner_user_id)
      )
    )
  );

create policy yurubos_insert_owner
  on public.yurubos for insert to authenticated
  with check (owner_user_id = auth.uid());

create policy yurubos_update_owner
  on public.yurubos for update to authenticated
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

create policy yurubos_delete_owner
  on public.yurubos for delete to authenticated
  using (owner_user_id = auth.uid());

create policy yurubo_reactions_select_visible_yurubo
  on public.yurubo_reactions for select to authenticated
  using (exists (select 1 from public.yurubos y where y.id = yurubo_reactions.yurubo_id));

create policy yurubo_reactions_insert_own_visible_yurubo
  on public.yurubo_reactions for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.yurubos y where y.id = yurubo_reactions.yurubo_id)
  );

create policy yurubo_reactions_update_own
  on public.yurubo_reactions for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy yurubo_reactions_delete_own
  on public.yurubo_reactions for delete to authenticated
  using (user_id = auth.uid());

create policy hidden_yurubos_select_own
  on public.hidden_yurubos for select to authenticated
  using (user_id = auth.uid());

create policy hidden_yurubos_insert_own
  on public.hidden_yurubos for insert to authenticated
  with check (user_id = auth.uid());

create policy hidden_yurubos_delete_own
  on public.hidden_yurubos for delete to authenticated
  using (user_id = auth.uid());

grant select, insert, update, delete on public.yurubos to authenticated;
grant select, insert, update, delete on public.yurubo_reactions to authenticated;
grant select, insert, delete on public.hidden_yurubos to authenticated;
