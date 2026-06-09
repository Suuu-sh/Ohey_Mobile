-- Prepare profiles for Clerk auth subjects while preserving existing UUID profile IDs.
-- Clerk user IDs are text (for example, user_...), so profiles keep their UUID
-- primary key and store the Clerk subject in clerk_user_id.

alter table public.profiles
  add column if not exists clerk_user_id text;

create unique index if not exists profiles_clerk_user_id_key
  on public.profiles (clerk_user_id)
  where clerk_user_id is not null;

alter table public.profiles
  alter column id set default gen_random_uuid();

alter table public.profiles
  drop constraint if exists profiles_id_fkey;
