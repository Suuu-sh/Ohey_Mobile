-- Allow idempotent upserts for user safety relations.
-- Backend uses Supabase upsert with on_conflict for block/mute actions; PostgREST
-- requires update privilege/policy for that path even when the row is newly inserted.

create policy user_blocks_update_owner
  on public.user_blocks
  for update
  to authenticated
  using (blocker_user_id = auth.uid())
  with check (blocker_user_id = auth.uid() and blocked_user_id <> auth.uid());

create policy user_mutes_update_owner
  on public.user_mutes
  for update
  to authenticated
  using (muter_user_id = auth.uid())
  with check (muter_user_id = auth.uid() and muted_user_id <> auth.uid());

grant select, insert, update, delete on public.user_blocks to authenticated;
grant select, insert, update, delete on public.user_mutes to authenticated;
