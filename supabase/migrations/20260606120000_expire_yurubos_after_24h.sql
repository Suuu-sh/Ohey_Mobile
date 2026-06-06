-- Keep yurubo listings fresh and bounded by expiring them 24 hours after creation.

update public.yurubos
set expires_at = created_at + interval '24 hours'
where expires_at is null;

alter table public.yurubos
  alter column expires_at set default (now() + interval '24 hours');
