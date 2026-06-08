alter table public.notifications drop constraint if exists notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check check (
  kind in (
    'friend_request_received',
    'friend_request_accepted',
    'invite_received',
    'invite_accepted',
    'today_reservation_reminder',
    'yurubo_created',
    'system'
  )
);

create unique index if not exists notifications_unique_yurubo_created
  on public.notifications(recipient_user_id, system_key, kind)
  where system_key is not null and kind = 'yurubo_created';
