/// Backend API paths used by Ohey Mobile.
///
/// Keep every `/v1/...` path here so endpoint renames are one-file changes on
/// the Mobile side. Dynamic path helpers URL-encode path parameters.
class OheyApiPaths {
  const OheyApiPaths._();

  static const authSignup = '/v1/auth/signup';

  static const meProfile = '/v1/me/profile';
  static const meAccount = '/v1/me/account';
  static const mePushToken = '/v1/me/push-token';

  static const dailyStatus = '/v1/daily-status';
  static const monthlyDailyStatuses = '/v1/daily-statuses/month';

  static const profilesByUserIdBase = '/v1/profiles/by-user-id';
  static String profileByUserId(String userId) =>
      '$profilesByUserIdBase/${Uri.encodeComponent(userId)}';

  static const friends = '/v1/friends';
  static String friend(String friendId) =>
      '$friends/${Uri.encodeComponent(friendId)}';
  static String friendFavorite(String friendId) =>
      '${friend(friendId)}/favorite';
  static String friendMonthlyDailyStatuses(String friendId) =>
      '${friend(friendId)}/daily-statuses/month';

  static const friendGroups = '/v1/friend-groups';
  static const friendRequests = '/v1/friend-requests';
  static const friendRequestStatus = '/v1/friend-requests/status';
  static String friendRequest(String requestId) =>
      '$friendRequests/${Uri.encodeComponent(requestId)}';

  static const homeFeed = '/v1/home/feed';

  static const wishItems = '/v1/wish-items';
  static String wishItem(String wishItemId) =>
      '$wishItems/${Uri.encodeComponent(wishItemId)}';
  static const wishItemsProfileBase = '/v1/wish-items/profile';
  static String profileWishItems(String profileId) =>
      '$wishItemsProfileBase/${Uri.encodeComponent(profileId)}';

  static const yurubos = '/v1/yurubos';
  static String yurubo(String yuruboId) =>
      '$yurubos/${Uri.encodeComponent(yuruboId)}';
  static String yuruboReaction(String yuruboId) =>
      '${yurubo(yuruboId)}/reaction';
  static String yuruboReactionApproval(String yuruboId, String userId) =>
      '${yurubo(yuruboId)}/reactions/${Uri.encodeComponent(userId)}';

  static const userBlocks = '/v1/user-blocks';
  static String userBlock(String userId) =>
      '$userBlocks/${Uri.encodeComponent(userId)}';
  static const userMutes = '/v1/user-mutes';
  static String userMute(String userId) =>
      '$userMutes/${Uri.encodeComponent(userId)}';
  static const userReports = '/v1/user-reports';

  static const notifications = '/v1/notifications';
  static const notificationsReadAll = '/v1/notifications/read-all';

  static const invites = '/v1/invites';
  static String invite(String inviteId) =>
      '$invites/${Uri.encodeComponent(inviteId)}';
  static const todayReservations = '/v1/invites/today-reservations';
  static const incomingPendingInvites = '/v1/invites/incoming-pending';
  static const outgoingActiveInvites = '/v1/invites/outgoing-active';

  static const adminMe = '/v1/admin/me';
  static const adminUsers = '/v1/admin/users';
  static String adminUser(String userId) =>
      '$adminUsers/${Uri.encodeComponent(userId)}';
  static const adminYurubos = '/v1/admin/yurubos';
  static String adminYurubo(String yuruboId) =>
      '$adminYurubos/${Uri.encodeComponent(yuruboId)}';
  static const adminNotificationOutbox = '/v1/admin/notification-outbox';
  static const adminNotificationOutboxProcess =
      '/v1/admin/notification-outbox/process';
  static const adminNotifications = '/v1/admin/notifications';
}
