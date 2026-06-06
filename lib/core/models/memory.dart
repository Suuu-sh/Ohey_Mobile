import 'ohey_avatar.dart';
import 'ohey_friend.dart';

class Memory {
  const Memory({
    required this.id,
    required this.date,
    required this.friends,
    required this.place,
    required this.memo,
    this.linkUrl,
    this.placeLatitude,
    this.placeLongitude,
    this.ownerUserId = '',
    this.ownerDisplayName = '',
    this.ownerAvatar,
    this.isOfficial = false,
    this.feedAuthorName = '',
    this.feedPostKind = '',
    this.feedDisplayable = true,
    this.feedCanReport = true,
    this.feedCanDelete = false,
    this.feedTilt,
    this.feedCursor = '',
  });

  final String id;
  final DateTime date;
  final List<OheyFriend> friends;
  final String place;
  final String memo;
  final String? linkUrl;
  final double? placeLatitude;
  final double? placeLongitude;
  final String ownerUserId;
  final String ownerDisplayName;
  final OheyAvatar? ownerAvatar;
  final bool isOfficial;
  final String feedAuthorName;
  final String feedPostKind;
  final bool feedDisplayable;
  final bool feedCanReport;
  final bool feedCanDelete;
  final double? feedTilt;
  final String feedCursor;

  bool isInMonth(DateTime month) =>
      date.year == month.year && date.month == month.month;

  bool isSameDay(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;

  bool get hasPlaceCoordinate =>
      placeLatitude != null &&
      placeLongitude != null &&
      placeLatitude!.isFinite &&
      placeLongitude!.isFinite;

  String get friendNames => friends.map((friend) => friend.name).join(', ');
}
