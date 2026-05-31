alter table public.yurubos drop constraint if exists yurubos_visibility_check;
alter table public.yurubos add constraint yurubos_visibility_check check (visibility in ('friends','group','private'));

create table if not exists public.yurubo_visibility_groups (
  id uuid primary key default gen_random_uuid(),
  yurubo_id uuid not null references public.yurubos(id) on delete cascade,
  group_id uuid not null references public.friend_groups(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (yurubo_id, group_id)
);

create index if not exists yurubo_visibility_groups_yurubo_idx on public.yurubo_visibility_groups(yurubo_id);
create index if not exists yurubo_visibility_groups_group_idx on public.yurubo_visibility_groups(group_id);

alter table public.yurubo_visibility_groups enable row level security;

drop policy if exists yurubos_select_owner_or_friend on public.yurubos;
create policy yurubos_select_owner_friend_or_group
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
    or (
      visibility = 'group'
      and exists (
        select 1
        from public.yurubo_visibility_groups yvg
        join public.friend_group_members fgm on fgm.group_id = yvg.group_id
        where yvg.yurubo_id = yurubos.id
          and fgm.friend_user_id = auth.uid()
      )
    )
  );

create policy yurubo_visibility_groups_select_owner_or_member
  on public.yurubo_visibility_groups for select to authenticated
  using (
    exists (select 1 from public.yurubos y where y.id = yurubo_visibility_groups.yurubo_id and y.owner_user_id = auth.uid())
    or exists (select 1 from public.friend_group_members fgm where fgm.group_id = yurubo_visibility_groups.group_id and fgm.friend_user_id = auth.uid())
  );

create policy yurubo_visibility_groups_insert_yurubo_owner
  on public.yurubo_visibility_groups for insert to authenticated
  with check (
    exists (select 1 from public.yurubos y where y.id = yurubo_visibility_groups.yurubo_id and y.owner_user_id = auth.uid())
    and exists (select 1 from public.friend_groups g where g.id = yurubo_visibility_groups.group_id and g.owner_user_id = auth.uid())
  );

create policy yurubo_visibility_groups_delete_yurubo_owner
  on public.yurubo_visibility_groups for delete to authenticated
  using (exists (select 1 from public.yurubos y where y.id = yurubo_visibility_groups.yurubo_id and y.owner_user_id = auth.uid()));

grant select, insert, delete on public.yurubo_visibility_groups to authenticated;
