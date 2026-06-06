/// Wire values shared across Ohey Mobile models, requests, and UI.
///
/// These values are part of the backend contract. Keep labels/presentation
/// text elsewhere, but keep keys that cross the API boundary here.
class OheyStatusKeys {
  const OheyStatusKeys._();

  static const pending = 'pending';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';

  static const unselected = 'unselected';
  static const unset = 'unset';
  static const available = 'available';
  static const maybeAvailable = 'maybe_available';
  static const dependsOnTime = 'depends_on_time';
  static const hasPlans = 'has_plans';

  static const active = 'active';
  static const open = 'open';
  static const closed = 'closed';
  static const expired = 'expired';
  static const scheduled = 'scheduled';

  static const reviewing = 'reviewing';
  static const resolved = 'resolved';
  static const dismissed = 'dismissed';
  static const processed = 'processed';
  static const failed = 'failed';
  static const all = 'all';
}

class OheyVisibilityKeys {
  const OheyVisibilityKeys._();

  static const private = 'private';
  static const friends = 'friends';
  static const group = 'group';
}

class OheyCategoryKeys {
  const OheyCategoryKeys._();

  static const other = 'other';
}

class OheyReactionTypeKeys {
  const OheyReactionTypeKeys._();

  static const available = OheyStatusKeys.available;
  static const interested = 'interested';
  static const anotherDay = 'another_day';
  static const pendingYurubo = 'pending_yurubo';
}

class OheyRequestDirectionKeys {
  const OheyRequestDirectionKeys._();

  static const all = 'all';
  static const incoming = 'incoming';
  static const outgoing = 'outgoing';
}

class OheyRelationshipStateKeys {
  const OheyRelationshipStateKeys._();

  static const none = 'none';
  static const self = 'self';
  static const outgoing = OheyRequestDirectionKeys.outgoing;
  static const incoming = OheyRequestDirectionKeys.incoming;
}

class OheyReportReasonKeys {
  const OheyReportReasonKeys._();

  static const spam = 'spam';
  static const harassment = 'harassment';
  static const inappropriate = 'inappropriate';
  static const violence = 'violence';
  static const minorSafety = 'minor_safety';
  static const other = 'other';
}

class OheyNotificationKindKeys {
  const OheyNotificationKindKeys._();

  static const friendRequestReceived = 'friend_request_received';
  static const friendRequestAccepted = 'friend_request_accepted';
  static const inviteReceived = 'invite_received';
  static const inviteAccepted = 'invite_accepted';
  static const todayReservationReminder = 'today_reservation_reminder';
  static const memoryTagged = 'memory_tagged';
  static const yuruboCreated = 'yurubo_created';
  static const system = 'system';
}

class OheyFeedKeys {
  const OheyFeedKeys._();

  static const typeMemory = 'memory';
  static const postMine = 'mine';
  static const postFriend = 'friend';
  static const postOfficial = 'official';
  static const propMemory = 'memory';
}

class OheyPushPlatformKeys {
  const OheyPushPlatformKeys._();

  static const ios = 'ios';
  static const android = 'android';
}
