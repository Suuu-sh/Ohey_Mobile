-- Expire scheduled yurubos after their scheduled day, and unscheduled yurubos after 30 days.

update public.yurubos
set expires_at = case
  when starts_at is not null then date_trunc('day', starts_at at time zone 'UTC') at time zone 'UTC' + interval '1 day'
  else created_at + interval '30 days'
end;

alter table public.yurubos
  alter column expires_at set default (now() + interval '30 days');
