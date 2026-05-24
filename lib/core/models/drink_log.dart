import 'nomo_avatar.dart';
import 'nomo_friend.dart';

enum DrinkLogRarity {
  normal('normal'),
  uncommon('uncommon'),
  rare('rare'),
  superRare('super_rare'),
  ultraRare('ultra_rare'),
  secret('secret');

  const DrinkLogRarity(this.key);

  final String key;

  static DrinkLogRarity fromKey(String? key) => switch (key?.trim()) {
    'uncommon' => DrinkLogRarity.uncommon,
    'rare' => DrinkLogRarity.rare,
    'super_rare' => DrinkLogRarity.superRare,
    'ultra_rare' => DrinkLogRarity.ultraRare,
    'secret' => DrinkLogRarity.secret,
    _ => DrinkLogRarity.normal,
  };
}

class DrinkLog {
  const DrinkLog({
    required this.id,
    required this.date,
    required this.friends,
    required this.place,
    required this.memo,
    this.photoAssetPath,
    this.linkUrl,
    this.placeLatitude,
    this.placeLongitude,
    this.likeCount = 0,
    this.likedByMe = false,
    this.ownerUserId = '',
    this.ownerDisplayName = '',
    this.ownerAvatar,
    this.isOfficial = false,
    this.rarity = DrinkLogRarity.normal,
  });

  final String id;
  final DateTime date;
  final List<NomoFriend> friends;
  final String place;
  final String memo;
  final String? photoAssetPath;
  final String? linkUrl;
  final double? placeLatitude;
  final double? placeLongitude;
  final int likeCount;
  final bool likedByMe;
  final String ownerUserId;
  final String ownerDisplayName;
  final NomoAvatar? ownerAvatar;
  final bool isOfficial;
  final DrinkLogRarity rarity;

  DrinkLog copyWith({int? likeCount, bool? likedByMe}) => DrinkLog(
    id: id,
    date: date,
    friends: friends,
    place: place,
    memo: memo,
    photoAssetPath: photoAssetPath,
    linkUrl: linkUrl,
    placeLatitude: placeLatitude,
    placeLongitude: placeLongitude,
    likeCount: likeCount ?? this.likeCount,
    likedByMe: likedByMe ?? this.likedByMe,
    ownerUserId: ownerUserId,
    ownerDisplayName: ownerDisplayName,
    ownerAvatar: ownerAvatar,
    isOfficial: isOfficial,
    rarity: rarity,
  );

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
