import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nomo_avatar.dart';
import 'nomo_gender.dart';

enum NomoFriendKind { bunny, cat, bear, penguin, puppy, cloud }

enum NomoFriendPalette { peach, sky, lemon, lavender, mint, blush }

class NomoFriend {
  const NomoFriend({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.vibe,
    required this.characterAssetPath,
    required this.kind,
    required this.palette,
    this.gender = NomoGender.unspecified,
    this.avatar,
    this.monthlyCount,
    this.totalMemoryCount,
    this.lastMemoryAt,
    this.statusKey,
    this.isOnline,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String avatarEmoji;
  final String vibe;
  final String characterAssetPath;
  final NomoFriendKind kind;
  final NomoFriendPalette palette;
  final NomoGender gender;
  final NomoAvatar? avatar;
  final int? monthlyCount;
  final int? totalMemoryCount;
  final DateTime? lastMemoryAt;
  final String? statusKey;
  final bool? isOnline;
  final bool isFavorite;

  Color get accentColor => switch (palette) {
    NomoFriendPalette.peach => AppColors.peach,
    NomoFriendPalette.sky => AppColors.sky,
    NomoFriendPalette.lemon => AppColors.lemon,
    NomoFriendPalette.lavender => AppColors.lavender,
    NomoFriendPalette.mint => AppColors.mint,
    NomoFriendPalette.blush => AppColors.blush,
  };

  Color get ringColor => switch (palette) {
    NomoFriendPalette.peach => AppColors.orange,
    NomoFriendPalette.sky => AppColors.blue,
    NomoFriendPalette.lemon => const Color(0xFFE4A63D),
    NomoFriendPalette.lavender => AppColors.lilac,
    NomoFriendPalette.mint => AppColors.green,
    NomoFriendPalette.blush => AppColors.coral,
  };
}

String nomoFriendStatusLabel(int count) {
  if (count == 0) return 'まだ静かなおなか';
  if (count <= 2) return 'にこにこメモリー';
  if (count <= 5) return '盛り上がり中';
  return '今月の主役級！';
}

String nomoFriendStatusMessage(NomoFriend friend, int count) {
  if (count == 0) return '${friend.name}と思い出を増やす？';
  if (count <= 2) return '${friend.name}と思い出が増えてきたね。';
  if (count <= 5) return '${friend.name}との思い出、増えてるよ。';
  return '${friend.name}とは今月かなり仲良し。';
}
