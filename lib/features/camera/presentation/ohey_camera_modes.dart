part of 'ohey_camera_screen.dart';

enum _CameraFilter {
  original,
  avatar;

  bool get usesArFaceTracking => this != original;

  String get modeName => switch (this) {
    original => 'original',
    avatar => 'avatar',
  };

  String get label => switch (this) {
    original => 'Original',
    avatar => 'Ohey AR',
  };

  String get resultName => switch (this) {
    original => _OheyCameraScreenState._plainFilterName,
    avatar => _OheyCameraScreenState._avatarFilterName,
  };

  IconData get icon => switch (this) {
    original => CupertinoIcons.sparkles,
    avatar => CupertinoIcons.person_crop_circle_fill,
  };

  Color get buttonColor => switch (this) {
    original => Colors.black.withValues(alpha: .42),
    avatar => const Color(0xFFFF4FA2).withValues(alpha: .92),
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
