-- Add an optional activity label so invites can say what the plan is.

alter table public.invites
  add column if not exists activity_label text;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'invites_activity_label_length'
      and conrelid = 'public.invites'::regclass
  ) then
    alter table public.invites
      add constraint invites_activity_label_length
      check (
        activity_label is null
        or char_length(activity_label) between 1 and 40
      );
  end if;
end $$;
