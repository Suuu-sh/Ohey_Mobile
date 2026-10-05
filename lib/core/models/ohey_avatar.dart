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
    [AppColors.cFFFF86C8, AppColors.cFFFFE5F3],
    [AppColors.cFFFF86C8, AppColors.cFFFFE5F3],
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
    AppColors.cFFFFF0D5,
    AppColors.cFFFFC56B,
    AppColors.cFFFF9600,
    AppColors.cFF6E1515,
    AppColors.cFF2B3A41,
    AppColors.cFFFFC56B,
  ];

  static const hairColors = [
    AppColors.cFF1A272D,
    AppColors.cFF2B3A41,
    AppColors.cFFCD7900,
    AppColors.cFFFFAB33,
    AppColors.cFF131F24,
    AppColors.cFFE5E5E5,
  ];

  static const shirtColors = [
    AppColors.cFFA568CC,
    AppColors.cFF49C0F8,
    AppColors.cFF1CB0F6,
    AppColors.cFF89E219,
    AppColors.cFFFFE066,
    AppColors.cFFFFAB33,
    AppColors.cFFFF7878,
    AppColors.cFFFF9FD3,
    AppColors.cFFF7F7F7,
    AppColors.cFF37464F,
    AppColors.cFFCE82FF,
    AppColors.cFF00A47C,
    AppColors.cFFFFAB33,
    AppColors.cFF1CB0F6,
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
