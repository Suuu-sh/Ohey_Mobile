-- Prepare Nomo Plus entitlement flag without exposing paid features yet.

alter table public.profiles
  add column if not exists is_plus boolean not null default false;

comment on column public.profiles.is_plus is
  'Future Nomo Plus entitlement flag. Kept false for all users until monetization is introduced.';
