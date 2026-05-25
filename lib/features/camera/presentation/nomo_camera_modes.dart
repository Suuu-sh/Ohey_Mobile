part of 'nomo_camera_screen.dart';

enum _CameraFilter {
  original,
  avatar,
  natural;

  bool get usesArFaceTracking => this != original;

  String get modeName => switch (this) {
    original => 'original',
    avatar => 'avatar',
    natural => 'natural',
  };

  String get label => switch (this) {
    original => 'Original',
    avatar => 'Tomo AR',
    natural => 'Natural',
  };

  String get resultName => switch (this) {
    original => _NomoCameraScreenState._plainFilterName,
    avatar => _NomoCameraScreenState._avatarFilterName,
    natural => _NomoCameraScreenState._naturalFilterName,
  };

  IconData get icon => switch (this) {
    original => CupertinoIcons.sparkles,
    avatar => CupertinoIcons.person_crop_circle_fill,
    natural => CupertinoIcons.wand_stars,
  };

  Color get buttonColor => switch (this) {
    original => Colors.black.withValues(alpha: .42),
    avatar => const Color(0xFFFF4FA2).withValues(alpha: .92),
    natural => const Color(0xFF47C9B6).withValues(alpha: .92),
  };
}

enum _CameraFraming {
  square,
  landscape;

  bool get allowsArFilters => this == square;

  String get label => switch (this) {
    square => '1:1',
    landscape => '16:9',
  };

  String get description => switch (this) {
    square => '縦撮り',
    landscape => '横撮り',
  };

  double get frameAspectRatio => switch (this) {
    square => 1,
    landscape => 16 / 9,
  };

  String get semanticLabel => switch (this) {
    square => '縦撮り 1対1',
    landscape => '横撮り 16対9',
  };
}
