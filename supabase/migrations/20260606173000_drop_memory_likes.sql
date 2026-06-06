-- The app no longer exposes memory likes. Remove the unused table and grants/policies.

drop table if exists public.memory_likes cascade;
