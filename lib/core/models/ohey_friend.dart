import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'ohey_avatar.dart';
import 'ohey_gender.dart';

enum OheyFriendKind { bunny, cat, bear, penguin, puppy, cloud }

enum OheyFriendPalette { peach, sky, lemon, lavender, mint, blush }

class OheyFriend {
  const OheyFriend({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.vibe,
    required this.characterAssetPath,
    required this.kind,
    required this.palette,
    this.gender = OheyGender.unspecified,
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
  final OheyFriendKind kind;
  final OheyFriendPalette palette;
  final OheyGender gender;
  final OheyAvatar? avatar;
  final int? monthlyCount;
  final int? totalMemoryCount;
  final DateTime? lastMemoryAt;
  final String? statusKey;
  final bool? isOnline;
  final bool isFavorite;

  Color get accentColor => switch (palette) {
    OheyFriendPalette.peach => AppColors.peach,
    OheyFriendPalette.sky => AppColors.sky,
    OheyFriendPalette.lemon => AppColors.lemon,
    OheyFriendPalette.lavender => AppColors.lavender,
    OheyFriendPalette.mint => AppColors.mint,
    OheyFriendPalette.blush => AppColors.blush,
  };

  Color get ringColor => switch (palette) {
    OheyFriendPalette.peach => AppColors.orange,
    OheyFriendPalette.sky => AppColors.blue,
    OheyFriendPalette.lemon => const Color(0xFFE4A63D),
    OheyFriendPalette.lavender => AppColors.lilac,
    OheyFriendPalette.mint => AppColors.green,
    OheyFriendPalette.blush => AppColors.coral,
  };
}

String oheyFriendStatusLabel(int count) {
  if (count == 0) return 'まだ静かなおなか';
  if (count <= 2) return 'にこにこメモリー';
  if (count <= 5) return '盛り上がり中';
  return '今月の主役級！';
}

String oheyFriendStatusMessage(OheyFriend friend, int count) {
  if (count == 0) return '${friend.name}と思い出を増やす？';
  if (count <= 2) return '${friend.name}と思い出が増えてきたね。';
  if (count <= 5) return '${friend.name}との思い出、増えてるよ。';
  return '${friend.name}とは今月かなり仲良し。';
}
