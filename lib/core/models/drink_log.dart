import 'nomo_avatar.dart';
import 'nomo_friend.dart';

class DrinkLog {
  const DrinkLog({
    required this.id,
    required this.date,
    required this.friends,
    required this.place,
    required this.memo,
    this.photoAssetPath,
    this.linkUrl,
    this.likeCount = 0,
    this.likedByMe = false,
    this.ownerUserId = '',
    this.ownerDisplayName = '',
    this.ownerAvatar,
    this.isOfficial = false,
    this.likedBy = const <NomoFriend>[],
  });

  final String id;
  final DateTime date;
  final List<NomoFriend> friends;
  final String place;
  final String memo;
  final String? photoAssetPath;
  final String? linkUrl;
  final int likeCount;
  final bool likedByMe;
  final String ownerUserId;
  final String ownerDisplayName;
  final NomoAvatar? ownerAvatar;
  final bool isOfficial;
  final List<NomoFriend> likedBy;

  DrinkLog copyWith({int? likeCount, bool? likedByMe}) => DrinkLog(
    id: id,
    date: date,
    friends: friends,
    place: place,
    memo: memo,
    photoAssetPath: photoAssetPath,
    linkUrl: linkUrl,
    likeCount: likeCount ?? this.likeCount,
    likedByMe: likedByMe ?? this.likedByMe,
    ownerUserId: ownerUserId,
    ownerDisplayName: ownerDisplayName,
    ownerAvatar: ownerAvatar,
    isOfficial: isOfficial,
    likedBy: likedBy,
  );

  bool isInMonth(DateTime month) =>
      date.year == month.year && date.month == month.month;

  bool isSameDay(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;

  String get friendNames => friends.map((friend) => friend.name).join(', ');
}
