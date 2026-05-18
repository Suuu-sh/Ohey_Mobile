-- Expand in-app notifications beyond likes.
-- Event notifications are created by the trusted Render backend with the service
-- role key. Clients can only select their own notifications and update read_at.

alter table public.notifications
  add column if not exists friend_request_id uuid references public.friend_requests(id) on delete cascade,
  add column if not exists drink_invite_id uuid references public.drink_invites(id) on delete cascade,
  add column if not exists notification_date date,
  add column if not exists system_key text;

alter table public.notifications
  drop constraint if exists notifications_kind_check;

alter table public.notifications
  add constraint notifications_kind_check check (
    kind in (
      'drink_log_like',
      'friend_request_received',
      'friend_request_accepted',
      'drink_invite_received',
      'drink_invite_accepted',
      'today_reservation_reminder',
      'drink_log_tagged',
      'system'
    )
  );

create unique index if not exists notifications_unique_friend_request_event
on public.notifications (recipient_user_id, friend_request_id, kind)
where friend_request_id is not null
  and kind in ('friend_request_received', 'friend_request_accepted');

create unique index if not exists notifications_unique_drink_invite_event
on public.notifications (recipient_user_id, drink_invite_id, kind)
where drink_invite_id is not null
  and kind in ('drink_invite_received', 'drink_invite_accepted');

create unique index if not exists notifications_unique_today_reservation_reminder
on public.notifications (recipient_user_id, drink_invite_id, notification_date, kind)
where drink_invite_id is not null
  and notification_date is not null
  and kind = 'today_reservation_reminder';

create unique index if not exists notifications_unique_drink_log_tagged
on public.notifications (recipient_user_id, drink_log_id, kind)
where drink_log_id is not null
  and kind = 'drink_log_tagged';

create unique index if not exists notifications_unique_system_key
on public.notifications (recipient_user_id, system_key, kind)
where system_key is not null
  and kind = 'system';

revoke update on public.notifications from authenticated;
grant select on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;
