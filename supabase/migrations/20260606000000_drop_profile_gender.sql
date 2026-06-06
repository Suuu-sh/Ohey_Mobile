alter table public.profiles
  drop constraint if exists profiles_gender_check;

alter table public.profiles
  drop column if exists gender;
