-- Expand the daily status choices used by the production profile page.
-- Existing legacy rows are normalized before the stricter check is applied.

update public.daily_statuses
set status = 'can_drink_today'
where status = 'want_drink';

update public.daily_statuses
set status = 'liver_rest'
where status = 'busy';

alter table public.daily_statuses
  drop constraint if exists daily_statuses_status_check;

alter table public.daily_statuses
  add constraint daily_statuses_status_check
  check (
    status in (
      'unselected',
      'can_drink_today',
      'light_drink',
      'want_drink_hard',
      'non_alcohol',
      'liver_rest',
      'waiting_invite',
      'has_plans'
    )
  );
