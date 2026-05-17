-- Drink invitations become today's reservation once the invited friend accepts.

create table if not exists public.drink_invites (
  id uuid primary key default gen_random_uuid(),
  from_user_id uuid not null references public.profiles(id) on delete cascade,
  to_user_id uuid not null references public.profiles(id) on delete cascade,
  invite_date date not null default current_date,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint drink_invites_no_self check (from_user_id <> to_user_id)
);

create index if not exists drink_invites_from_user_idx
  on public.drink_invites (from_user_id, invite_date desc, status);

create index if not exists drink_invites_to_user_idx
  on public.drink_invites (to_user_id, invite_date desc, status);

create unique index if not exists drink_invites_unique_active_today
  on public.drink_invites (
    least(from_user_id, to_user_id),
    greatest(from_user_id, to_user_id),
    invite_date
  )
  where status in ('pending', 'accepted');

alter table public.drink_invites enable row level security;

drop policy if exists drink_invites_select_own on public.drink_invites;
create policy drink_invites_select_own
  on public.drink_invites
  for select
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id);

drop policy if exists drink_invites_insert_from_self on public.drink_invites;
create policy drink_invites_insert_from_self
  on public.drink_invites
  for insert
  to authenticated
  with check (
    auth.uid() = from_user_id
    and exists (
      select 1
      from public.friendships f
      where (
        (f.user_a_id = auth.uid() and f.user_b_id = to_user_id)
        or (f.user_b_id = auth.uid() and f.user_a_id = to_user_id)
      )
    )
  );

drop policy if exists drink_invites_update_participants on public.drink_invites;
create policy drink_invites_update_participants
  on public.drink_invites
  for update
  to authenticated
  using (auth.uid() = from_user_id or auth.uid() = to_user_id)
  with check (auth.uid() = from_user_id or auth.uid() = to_user_id);
