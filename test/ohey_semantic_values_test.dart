import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/models/ohey_friend_request_status.dart';
import 'package:ohey/core/models/ohey_invite.dart';
import 'package:ohey/core/models/ohey_moderation_status.dart';
import 'package:ohey/core/models/ohey_visibility.dart';
import 'package:ohey/core/models/yurubo.dart';

void main() {
  test('yurubo reaction meaning is centralized', () {
    expect(oheyApprovedYuruboReactionKey.isApprovedYuruboReaction, isTrue);
    expect(oheyYuruboInterestedReactionKey.isApprovedYuruboReaction, isFalse);
    expect(oheyPendingYuruboCompanionKey.isPendingYuruboCompanion, isTrue);
    expect(
      oheyYuruboReactionTypeFromKey('unknown').isPendingParticipation,
      isTrue,
    );
  });

  test('visibility meaning is centralized', () {
    expect(OheyVisibility.private.key, oheyPrivateVisibilityKey);
    expect(OheyVisibility.group.requiresGroup, isTrue);
    expect(OheyVisibility.yuruboSelectable, contains(OheyVisibility.group));
    expect(
      OheyVisibility.wishItemSelectable,
      isNot(contains(OheyVisibility.group)),
    );
    expect(oheyVisibilityFromKey('unknown'), OheyVisibility.private);
  });

  test('friend request response meaning is centralized', () {
    expect(OheyFriendRequestStatus.accepted.isAccepted, isTrue);
    expect(OheyFriendRequestStatus.accepted.isResponseAction, isTrue);
    expect(OheyFriendRequestStatus.rejected.responseToastMessage, '申請を見送りました');
    expect(OheyFriendRequestStatus.pending.isResponseAction, isFalse);
  });

  test('invite response meaning is centralized', () {
    expect(OheyInviteStatus.accepted.isAccepted, isTrue);
    expect(OheyInviteStatus.rejected.isResponseAction, isTrue);
    expect(OheyInviteStatus.rejected.responseToastMessage, '招待を見送りました。');
    expect(OheyInviteStatus.cancelled.isResponseAction, isFalse);
  });

  test('moderation status meaning is centralized', () {
    expect(
      oheyModerationStatusFromKey(oheyModerationReviewingKey).label,
      '対応中',
    );
    expect(OheyModerationStatus.actions, [
      OheyModerationStatus.reviewing,
      OheyModerationStatus.resolved,
      OheyModerationStatus.dismissed,
    ]);
    expect(OheyModerationStatus.dismissed.isDestructiveAction, isTrue);
  });
}
