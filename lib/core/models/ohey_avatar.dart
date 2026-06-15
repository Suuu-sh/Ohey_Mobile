import 'dart:math';

import 'package:ohey/core/theme/app_colors.dart';

class OheyAvatar {
  const OheyAvatar({
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
  static const ohetomoMomoBackdropBackground = 1;
  static const dreamRoomBackground = 2;
  static const nightFriendsBackground = 3;

  static const defaultAvatar = OheyAvatar(
    skin: 2,
    hair: 1,
    shirt: 0,
    eyes: 0,
    mouth: 0,
    accessory: 0,
    background: mascotBackdropBackground,
  );

  /// Mascot avatar used only for official Ohey posts.
  static const adminAvatar = OheyAvatar(
    skin: 5,
    hair: 5,
    shirt: 9,
    eyes: 2,
    mouth: 1,
    accessory: 1,
    background: nightFriendsBackground,
    isAdmin: true,
  );

  static OheyAvatar random() {
    final random = Random();
    return OheyAvatar(
      skin: random.nextInt(skinColors.length),
      hair: random.nextInt(hairStyles.length),
      shirt: random.nextInt(shirtColors.length),
      eyes: random.nextInt(eyeStyles.length),
      mouth: random.nextInt(mouthStyles.length),
      accessory: random.nextInt(accessoryStyles.length),
      background: random.nextInt(backgroundStyles.length),
    );
  }

  String encode() => isAdmin
      ? 'ohey_avatar:admin:v1'
      : 'ohey_avatar:v2:$skin:$hair:$shirt:$eyes:$mouth:$accessory:$background';

  static OheyAvatar? decode(String? value, {bool allowAdmin = false}) {
    if (value == 'ohey_avatar:admin:v1') {
      return allowAdmin ? adminAvatar : null;
    }
    if (value == null ||
        (!value.startsWith('ohey_avatar:v1:') &&
            !value.startsWith('ohey_avatar:v2:'))) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 8 && parts.length != 9) return null;
    int parse(int index, int max) {
      final raw = int.tryParse(parts[index]) ?? 0;
      return raw.clamp(0, max - 1).toInt();
    }

    return OheyAvatar(
      skin: parse(2, skinColors.length),
      hair: parse(3, hairStyles.length),
      shirt: parse(4, shirtColors.length),
      eyes: parse(5, eyeStyles.length),
      mouth: parse(6, mouthStyles.length),
      accessory: parse(7, accessoryStyles.length),
      background: parts.length >= 9 ? parse(8, backgroundStyles.length) : 0,
    );
  }

  OheyAvatar copyWith({
    int? skin,
    int? hair,
    int? shirt,
    int? eyes,
    int? mouth,
    int? accessory,
    int? background,
  }) {
    return OheyAvatar(
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

  static const backgroundStyles = ['Ohey pink', 'おへとも・もも'];

  static const backgroundGradients = [
    [AppColors.cFFFF7BBC, AppColors.cFFFFD2E3],
    [AppColors.cFFFF8FC8, AppColors.cFFFFDDEB],
  ];

  static bool usesMascotBackdrop(int background) =>
      imageBackdropAsset(background) != null;

  static String? imageBackdropAsset(int background) => switch (background) {
    mascotBackdropBackground =>
      'assets/images/profile_mascot_backdrop_scene.png',
    ohetomoMomoBackdropBackground =>
      'assets/images/profile_ohetomo_momo_backdrop_scene.png',
    _ => null,
  };

  static const skinColors = [
    AppColors.cFFFFD8C2,
    AppColors.cFFE9A985,
    AppColors.cFFB96B54,
    AppColors.cFF7B3F36,
    AppColors.cFF4A2824,
    AppColors.cFFFFC08A,
  ];

  static const hairColors = [
    AppColors.cFF2A1715,
    AppColors.cFF4E2A20,
    AppColors.cFF8A4B2E,
    AppColors.cFFD8A24C,
    AppColors.cFF111820,
    AppColors.cFFEFE8D8,
  ];

  static const shirtColors = [
    AppColors.cFFB777D9,
    AppColors.cFF2EA8FF,
    AppColors.cFF39C7D7,
    AppColors.cFF65B96B,
    AppColors.cFFFFD25B,
    AppColors.cFFFF9B38,
    AppColors.cFFFF6666,
    AppColors.cFFFF9FC7,
    AppColors.cFFF8F8F8,
    AppColors.cFF3D4850,
    AppColors.cFF7C5CFF,
    AppColors.cFF00B894,
    AppColors.cFFFF6B35,
    AppColors.cFF2F80ED,
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
    'ふわショート',
    'マッシュ',
    'ポニー',
  ];
  static const eyeStyles = ['まる目', 'にこ目', 'きらきら', 'ぱっちり', 'ウインク', 'たれ目', 'ジト目'];
  static const mouthStyles = ['スマイル', 'にっこり', 'むにゅ', 'おどろき', 'ほほえみ', 'ぷくっ'];
  static const accessoryStyles = [
    'なし',
    'メガネ',
    'マスク',
    'チーク',
    'そばかす',
    'ほくろ',
    'ヘッドホン',
    'ヘアピン',
  ];
}
