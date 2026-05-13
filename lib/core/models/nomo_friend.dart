import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
  });

  final String id;
  final String name;
  final String avatarEmoji;
  final String vibe;
  final String characterAssetPath;
  final NomiTomoKind kind;
  final NomiTomoPalette palette;

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
  if (count <= 2) return 'にこにこ乾杯';
  if (count <= 5) return '盛り上がり中';
  return '今月の主役級！';
}

String nomiTomoStatusMessage(NomoFriend friend, int count) {
  if (count == 0) return '${friend.name}とはまだ今月飲んでないよ。そろそろ誘ってみる？';
  if (count <= 2) return '${friend.name}との夜が少しずつ増えてきた。次もゆるく乾杯しよ。';
  if (count <= 5) return '${friend.name}との思い出がきらきら増殖中。いいペース！';
  return '${friend.name}とは今月かなり仲良し。飲み友メーター満タン！';
}
