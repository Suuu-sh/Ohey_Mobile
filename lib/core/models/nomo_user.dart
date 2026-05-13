import '../widgets/nomo_character.dart';

class NomoUser {
  const NomoUser({
    required this.name,
    required this.characterPose,
    this.isPlus = false,
  });

  final String name;
  final NomoCharacterPose characterPose;
  final bool isPlus;
}
