-- memory_like notifications are no longer generated or displayed.
-- Keep existing rows readable for history, but prevent new memory_like notification rows.

delete from public.notifications
where kind = 'memory_like';

drop index if exists public.notifications_unique_memory_like;

alter table public.notifications drop constraint if exists notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (
  kind in (
    'friend_request_received',
    'friend_request_accepted',
    'invite_received',
    'invite_accepted',
    'today_reservation_reminder',
    'memory_tagged',
    'yurubo_created',
    'system'
  )
);
