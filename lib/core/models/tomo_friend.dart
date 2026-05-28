import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'tomo_avatar.dart';
import 'tomo_gender.dart';

enum TomoFriendKind { bunny, cat, bear, penguin, puppy, cloud }

enum TomoFriendPalette { peach, sky, lemon, lavender, mint, blush }

class TomoFriend {
  const TomoFriend({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.vibe,
    required this.characterAssetPath,
    required this.kind,
    required this.palette,
    this.gender = TomoGender.unspecified,
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
  final TomoFriendKind kind;
  final TomoFriendPalette palette;
  final TomoGender gender;
  final TomoAvatar? avatar;
  final int? monthlyCount;
  final int? totalMemoryCount;
  final DateTime? lastMemoryAt;
  final String? statusKey;
  final bool? isOnline;
  final bool isFavorite;

  Color get accentColor => switch (palette) {
    TomoFriendPalette.peach => AppColors.peach,
    TomoFriendPalette.sky => AppColors.sky,
    TomoFriendPalette.lemon => AppColors.lemon,
    TomoFriendPalette.lavender => AppColors.lavender,
    TomoFriendPalette.mint => AppColors.mint,
    TomoFriendPalette.blush => AppColors.blush,
  };

  Color get ringColor => switch (palette) {
    TomoFriendPalette.peach => AppColors.orange,
    TomoFriendPalette.sky => AppColors.blue,
    TomoFriendPalette.lemon => const Color(0xFFE4A63D),
    TomoFriendPalette.lavender => AppColors.lilac,
    TomoFriendPalette.mint => AppColors.green,
    TomoFriendPalette.blush => AppColors.coral,
  };
}

String tomoFriendStatusLabel(int count) {
  if (count == 0) return 'まだ静かなおなか';
  if (count <= 2) return 'にこにこメモリー';
  if (count <= 5) return '盛り上がり中';
  return '今月の主役級！';
}

String tomoFriendStatusMessage(TomoFriend friend, int count) {
  if (count == 0) return '${friend.name}と思い出を増やす？';
  if (count <= 2) return '${friend.name}と思い出が増えてきたね。';
  if (count <= 5) return '${friend.name}との思い出、増えてるよ。';
  return '${friend.name}とは今月かなり仲良し。';
}
