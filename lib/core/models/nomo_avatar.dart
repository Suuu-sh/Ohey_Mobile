import 'dart:math';

import 'package:flutter/material.dart';

import '../config/admin_config.dart';
import 'nomo_gender.dart';

class NomoAvatar {
  const NomoAvatar({
    required this.skin,
    required this.hair,
    required this.shirt,
    required this.eyes,
    required this.mouth,
    required this.accessory,
    this.background = 0,
    this.isAdmin = false,
  });

  final int skin;
  final int hair;
  final int shirt;
  final int eyes;
  final int mouth;
  final int accessory;
  final int background;
  final bool isAdmin;

  static const mascotBackdropBackground = 0;
  static const dreamRoomBackground = 1;
  static const nightFriendsBackground = 2;

  static const defaultAvatar = NomoAvatar(
    skin: 2,
    hair: 1,
    shirt: 0,
    eyes: 0,
    mouth: 0,
    accessory: 0,
    background: mascotBackdropBackground,
  );

  /// Mascot avatar used only for official Nomo posts.
  static const adminAvatar = NomoAvatar(
    skin: 5,
    hair: 5,
    shirt: 9,
    eyes: 2,
    mouth: 1,
    accessory: 1,
    background: nightFriendsBackground,
    isAdmin: true,
  );

  static bool isAdminEmail(String? email) => AdminConfig.isAdminEmail(email);

  static NomoAvatar random({NomoGender gender = NomoGender.unspecified}) {
    final random = Random();
    final hairOptions = selectableHairIndicesForGender(gender);
    return NomoAvatar(
      skin: random.nextInt(skinColors.length),
      hair: hairOptions[random.nextInt(hairOptions.length)],
      shirt: random.nextInt(shirtColors.length),
      eyes: random.nextInt(eyeStyles.length),
      mouth: random.nextInt(mouthStyles.length),
      accessory: random.nextInt(accessoryStyles.length),
      background: random.nextInt(backgroundStyles.length),
    );
  }

  String encode() => isAdmin
      ? 'nomo_avatar:admin:v1'
      : 'nomo_avatar:v2:$skin:$hair:$shirt:$eyes:$mouth:$accessory:$background';

  static NomoAvatar? decode(String? value, {bool allowAdmin = false}) {
    if (value == 'nomo_avatar:admin:v1') {
      return allowAdmin ? adminAvatar : null;
    }
    if (value == null ||
        (!value.startsWith('nomo_avatar:v1:') &&
            !value.startsWith('nomo_avatar:v2:'))) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 8 && parts.length != 9) return null;
    int parse(int index, int max) {
      final raw = int.tryParse(parts[index]) ?? 0;
      return raw.clamp(0, max - 1).toInt();
    }

    return NomoAvatar(
      skin: parse(2, skinColors.length),
      hair: parse(3, hairStyles.length),
      shirt: parse(4, shirtColors.length),
      eyes: parse(5, eyeStyles.length),
      mouth: parse(6, mouthStyles.length),
      accessory: parse(7, accessoryStyles.length),
      background: parts.length >= 9 ? parse(8, backgroundStyles.length) : 0,
    );
  }

  NomoAvatar copyWith({
    int? skin,
    int? hair,
    int? shirt,
    int? eyes,
    int? mouth,
    int? accessory,
    int? background,
  }) {
    return NomoAvatar(
      skin: skin ?? this.skin,
      hair: hair ?? this.hair,
      shirt: shirt ?? this.shirt,
      eyes: eyes ?? this.eyes,
      mouth: mouth ?? this.mouth,
      accessory: accessory ?? this.accessory,
      background: background ?? this.background,
      isAdmin: isAdmin,
    );
  }

  NomoAvatar normalizedForGender(NomoGender gender) {
    if (isAdmin) return this;
    final hairOptions = selectableHairIndicesForGender(gender);
    if (hairOptions.contains(hair)) return this;
    return copyWith(hair: hairOptions.first);
  }

  static const backgroundStyles = ['Tomola pink'];

  static const backgroundGradients = [
    [Color(0xFFFF7BBC), Color(0xFFFFD2E3)],
  ];

  static bool usesMascotBackdrop(int background) =>
      background == mascotBackdropBackground;

  static const skinColors = [
    Color(0xFFFFD8C2),
    Color(0xFFE9A985),
    Color(0xFFB96B54),
    Color(0xFF7B3F36),
    Color(0xFF4A2824),
    Color(0xFFFFC08A),
  ];

  static const hairColors = [
    Color(0xFF2A1715),
    Color(0xFF4E2A20),
    Color(0xFF8A4B2E),
    Color(0xFFD8A24C),
    Color(0xFF111820),
    Color(0xFFEFE8D8),
  ];

  static const shirtColors = [
    Color(0xFFB777D9),
    Color(0xFF2EA8FF),
    Color(0xFF39C7D7),
    Color(0xFF65B96B),
    Color(0xFFFFD25B),
    Color(0xFFFF9B38),
    Color(0xFFFF6666),
    Color(0xFFFF9FC7),
    Color(0xFFF8F8F8),
    Color(0xFF3D4850),
  ];

  static const hairStyles = [
    'なし',
    'カーリー',
    'ショート',
    'サイド',
    'おだんご',
    'キャップ',
    'ボブ',
    'ロング',
    'ツイン',
  ];
  static const eyeStyles = ['まる目', 'にこ目', 'きらきら', 'ぱっちり'];
  static const mouthStyles = ['スマイル', 'にっこり', 'むにゅ'];
  static const accessoryStyles = ['なし', 'メガネ', 'マスク', 'チーク'];

  static const maleHairIndices = [0, 1, 2, 3, 5];
  static const femaleHairIndices = [1, 4, 6, 7, 8];

  static List<int> selectableHairIndicesForGender(NomoGender gender) =>
      switch (gender) {
        NomoGender.male => maleHairIndices,
        NomoGender.female => femaleHairIndices,
        NomoGender.unspecified => [
          for (var i = 0; i < hairStyles.length; i++) i,
        ],
      };
}
