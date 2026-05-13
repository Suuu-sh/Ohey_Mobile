import 'package:flutter/material.dart';

/// Renders the official Nomo character from pose-by-pose PNG assets.
///
/// Each pose is stored as a standalone generated image under
/// `assets/characters/nomo/`. We avoid cropping from a sheet so
/// labels, neighboring characters, and guide lines cannot leak into runtime UI.
class NomoCharacter extends StatelessWidget {
  const NomoCharacter({
    super.key,
    this.pose = NomoCharacterPose.standingSmile,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final NomoCharacterPose pose;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      pose.assetPath,
      width: width ?? 120,
      height: height ?? width ?? 120,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}

enum NomoCharacterPose {
  standingSmile,
  standingWave,
  standingBeer,
  standingShy,
  standingSurprised,
  standingHands,
  sittingPhone,
  sittingBeer,
  sittingSmile,
  sittingSnack,
  sittingLaptop,
  sleepingBlanket,
  sleepingSide,
  reactionHappy,
  reactionLaugh,
  reactionTeary,
  reactionAngry,
  reactionWorried,
  reactionWink,
  reactionCool,
  iconSmile,
  iconWink,
  memu,
  saigou,
  chi,
  uo,
  aren,
}

extension NomoCharacterPoseX on NomoCharacterPose {
  static const _edamame = 'assets/characters/edamame';
  String get assetPath => switch (this) {
    NomoCharacterPose.standingSmile => '$_edamame/edamame_standing_smile.png',
    NomoCharacterPose.standingWave => '$_edamame/edamame_waving.png',
    NomoCharacterPose.standingBeer => '$_edamame/edamame_beer_mug.png',
    NomoCharacterPose.standingShy => '$_edamame/edamame_wink.png',
    NomoCharacterPose.standingSurprised => '$_edamame/edamame_surprised.png',
    NomoCharacterPose.standingHands => '$_edamame/edamame_cheer.png',
    NomoCharacterPose.sittingPhone => '$_edamame/edamame_phone_invite.png',
    NomoCharacterPose.sittingBeer => '$_edamame/edamame_clinking_mug.png',
    NomoCharacterPose.sittingSmile => '$_edamame/edamame_standing_smile.png',
    NomoCharacterPose.sittingSnack => '$_edamame/edamame_beer_mug.png',
    NomoCharacterPose.sittingLaptop => '$_edamame/edamame_phone_invite.png',
    NomoCharacterPose.sleepingBlanket => '$_edamame/edamame_sleepy.png',
    NomoCharacterPose.sleepingSide => '$_edamame/edamame_sleepy.png',
    NomoCharacterPose.reactionHappy => '$_edamame/edamame_cheer.png',
    NomoCharacterPose.reactionLaugh => '$_edamame/edamame_dancing.png',
    NomoCharacterPose.reactionTeary => '$_edamame/edamame_surprised.png',
    NomoCharacterPose.reactionAngry => '$_edamame/edamame_surprised.png',
    NomoCharacterPose.reactionWorried => '$_edamame/edamame_sleepy.png',
    NomoCharacterPose.reactionWink => '$_edamame/edamame_wink.png',
    NomoCharacterPose.reactionCool => '$_edamame/edamame_dancing.png',
    NomoCharacterPose.iconSmile => '$_edamame/edamame_standing_smile.png',
    NomoCharacterPose.iconWink => '$_edamame/edamame_wink.png',
    NomoCharacterPose.memu => '$_edamame/edamame_standing_smile.png',
    NomoCharacterPose.saigou =>
      'assets/characters/saigou/saigou_standing_smile.png',
    NomoCharacterPose.chi => 'assets/characters/chi/chi_standing_smile.png',
    NomoCharacterPose.uo => 'assets/characters/uo/uo_standing_smile.png',
    NomoCharacterPose.aren => 'assets/characters/aren/aren_standing_smile.png',
  };
}

NomoCharacterPose nomoPoseForDrinkCount(int count) {
  if (count == 0) return NomoCharacterPose.standingSmile;
  if (count <= 2) return NomoCharacterPose.standingWave;
  if (count <= 5) return NomoCharacterPose.standingBeer;
  if (count <= 8) return NomoCharacterPose.reactionHappy;
  return NomoCharacterPose.reactionHappy;
}
