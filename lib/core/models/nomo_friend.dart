import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'nomo_avatar.dart';
import 'nomo_gender.dart';

enum NomiTomoKind { bunny, cat, bear, penguin, puppy, cloud }

enum NomiTomoPalette { peach, sky, lemon, lavender, mint, blush }

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
    this.totalDrinkCount,
    this.lastDrinkAt,
    this.statusKey,
    this.isOnline,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String avatarEmoji;
  final String vibe;
  final String characterAssetPath;
  final NomiTomoKind kind;
  final NomiTomoPalette palette;
  final NomoGender gender;
  final NomoAvatar? avatar;
  final int? monthlyCount;
  final int? totalDrinkCount;
  final DateTime? lastDrinkAt;
  final String? statusKey;
  final bool? isOnline;
  final bool isFavorite;

  Color get accentColor => switch (palette) {
    NomiTomoPalette.peach => AppColors.peach,
    NomiTomoPalette.sky => AppColors.sky,
    NomiTomoPalette.lemon => AppColors.lemon,
    NomiTomoPalette.lavender => AppColors.lavender,
    NomiTomoPalette.mint => AppColors.mint,
    NomiTomoPalette.blush => AppColors.blush,
  };

  Color get ringColor => switch (palette) {
    NomiTomoPalette.peach => AppColors.orange,
    NomiTomoPalette.sky => AppColors.blue,
    NomiTomoPalette.lemon => const Color(0xFFE4A63D),
    NomiTomoPalette.lavender => AppColors.lilac,
    NomiTomoPalette.mint => AppColors.green,
    NomiTomoPalette.blush => AppColors.coral,
  };
}

String nomiTomoStatusLabel(int count) {
  if (count == 0) return 'まだ静かなおなか';
  if (count <= 2) return 'にこにこメモリー';
  if (count <= 5) return '盛り上がり中';
  return '今月の主役級！';
}

String nomiTomoStatusMessage(NomoFriend friend, int count) {
  if (count == 0) return '${friend.name}と思い出を増やす？';
  if (count <= 2) return '${friend.name}と思い出が増えてきたね。';
  if (count <= 5) return '${friend.name}との思い出、増えてるよ。';
  return '${friend.name}とは今月かなり仲良し。';
}
