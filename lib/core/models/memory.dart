import 'ohey_avatar.dart';
import 'ohey_friend.dart';

enum MemoryRarity {
  normal('normal'),
  uncommon('uncommon'),
  rare('rare'),
  superRare('super_rare'),
  ultraRare('ultra_rare'),
  secret('secret');

  const MemoryRarity(this.key);

  final String key;

  static MemoryRarity fromKey(String? key) => switch (key?.trim()) {
    'uncommon' => MemoryRarity.uncommon,
    'rare' => MemoryRarity.rare,
    'super_rare' => MemoryRarity.superRare,
    'ultra_rare' => MemoryRarity.ultraRare,
    'secret' => MemoryRarity.secret,
    _ => MemoryRarity.normal,
  };
}

class Memory {
  const Memory({
    required this.id,
    required this.date,
    required this.friends,
    required this.place,
    required this.memo,
    this.photoAssetPath,
    this.linkUrl,
    this.captionY = .5,
    this.placeLatitude,
    this.placeLongitude,
    this.likeCount = 0,
    this.likedByMe = false,
    this.ownerUserId = '',
    this.ownerDisplayName = '',
    this.ownerAvatar,
    this.isOfficial = false,
    this.rarity = MemoryRarity.normal,
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
  final String? photoAssetPath;
  final String? linkUrl;
  final double captionY;
  final double? placeLatitude;
  final double? placeLongitude;
  final int likeCount;
  final bool likedByMe;
  final String ownerUserId;
  final String ownerDisplayName;
  final OheyAvatar? ownerAvatar;
  final bool isOfficial;
  final MemoryRarity rarity;
  final String feedAuthorName;
  final String feedPostKind;
  final bool feedDisplayable;
  final bool feedCanReport;
  final bool feedCanDelete;
  final double? feedTilt;
  final String feedCursor;

  Memory copyWith({int? likeCount, bool? likedByMe}) => Memory(
    id: id,
    date: date,
    friends: friends,
    place: place,
    memo: memo,
    photoAssetPath: photoAssetPath,
    linkUrl: linkUrl,
    captionY: captionY,
    placeLatitude: placeLatitude,
    placeLongitude: placeLongitude,
    likeCount: likeCount ?? this.likeCount,
    likedByMe: likedByMe ?? this.likedByMe,
    ownerUserId: ownerUserId,
    ownerDisplayName: ownerDisplayName,
    ownerAvatar: ownerAvatar,
    isOfficial: isOfficial,
    rarity: rarity,
    feedAuthorName: feedAuthorName,
    feedPostKind: feedPostKind,
    feedDisplayable: feedDisplayable,
    feedCanReport: feedCanReport,
    feedCanDelete: feedCanDelete,
    feedTilt: feedTilt,
    feedCursor: feedCursor,
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
