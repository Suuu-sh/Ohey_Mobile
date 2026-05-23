-- Add self-selected gender to profiles for friends filtering.

alter table public.profiles
  add column if not exists gender text not null default 'unspecified';

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_gender_valid'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_gender_valid
      check (gender in ('unspecified', 'male', 'female'));
  end if;
end $$;

comment on column public.profiles.gender is
  'Self-selected profile gender used for friend filtering: male, female, or unspecified.';
