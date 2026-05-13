import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/nomo_user.dart';
import '../widgets/nomo_character.dart';

final nomoUserProvider = NotifierProvider<NomoUserController, NomoUser?>(
  NomoUserController.new,
);

class NomoUserController extends Notifier<NomoUser?> {
  @override
  NomoUser? build() => null;

  Future<bool> loadFromSupabaseProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final row = await supabase
        .from('profiles')
        .select('display_name,character_key')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return false;

    state = NomoUser(
      name: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? row['display_name'] as String
          : 'mi-mu',
      characterPose: _poseFromKey(row['character_key'] as String?),
    );
    return true;
  }

  Future<void> createUser({
    required String name,
    required NomoCharacterPose pose,
  }) async {
    final supabase = Supabase.instance.client;
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      throw StateError('Login is required before creating a Nomo user.');
    }

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name is required.');
    }
    final existing = await supabase
        .from('profiles')
        .select('user_id')
        .eq('id', authUser.id)
        .maybeSingle();

    await supabase
        .from('profiles')
        .upsert(
          {
            'id': authUser.id,
            'user_id': existing?['user_id'] ?? _defaultUserId(authUser.id),
            'display_name': trimmed,
            'character_key': _keyForPose(pose),
          }..removeWhere((_, value) => value == null),
        );

    state = NomoUser(name: trimmed, characterPose: pose);
  }
}

String _defaultUserId(String authUserId) {
  final compact = authUserId.replaceAll('-', '');
  return 'nomo_${compact.substring(0, compact.length < 12 ? compact.length : 12)}';
}

String _keyForPose(NomoCharacterPose pose) => switch (pose) {
  NomoCharacterPose.standingSmile => 'standing_smile',
  NomoCharacterPose.standingWave => 'standing_wave',
  NomoCharacterPose.standingBeer => 'standing_beer',
  NomoCharacterPose.standingShy => 'standing_shy',
  NomoCharacterPose.standingSurprised => 'standing_surprised',
  NomoCharacterPose.standingHands => 'standing_hands',
  NomoCharacterPose.sittingPhone => 'sitting_phone',
  NomoCharacterPose.sittingBeer => 'sitting_beer',
  NomoCharacterPose.sittingSmile => 'sitting_smile',
  NomoCharacterPose.sittingSnack => 'sitting_snack',
  NomoCharacterPose.sittingLaptop => 'sitting_laptop',
  NomoCharacterPose.sleepingBlanket => 'sleeping_blanket',
  NomoCharacterPose.sleepingSide => 'sleeping_side',
  NomoCharacterPose.reactionHappy => 'reaction_happy',
  NomoCharacterPose.reactionLaugh => 'reaction_laugh',
  NomoCharacterPose.reactionTeary => 'reaction_teary',
  NomoCharacterPose.reactionAngry => 'reaction_angry',
  NomoCharacterPose.reactionWorried => 'reaction_worried',
  NomoCharacterPose.reactionWink => 'reaction_wink',
  NomoCharacterPose.reactionCool => 'reaction_cool',
  NomoCharacterPose.iconSmile => 'icon_smile',
  NomoCharacterPose.iconWink => 'icon_wink',
  NomoCharacterPose.memu => 'memu',
  NomoCharacterPose.saigou => 'saigou',
  NomoCharacterPose.chi => 'chi',
  NomoCharacterPose.uo => 'uo',
  NomoCharacterPose.aren => 'aren',
};

NomoCharacterPose _poseFromKey(String? key) => switch (key) {
  'standing_wave' => NomoCharacterPose.standingWave,
  'standing_beer' => NomoCharacterPose.standingBeer,
  'standing_shy' => NomoCharacterPose.standingShy,
  'standing_surprised' => NomoCharacterPose.standingSurprised,
  'standing_hands' => NomoCharacterPose.standingHands,
  'sitting_phone' => NomoCharacterPose.sittingPhone,
  'sitting_beer' => NomoCharacterPose.sittingBeer,
  'sitting_smile' => NomoCharacterPose.sittingSmile,
  'sitting_snack' => NomoCharacterPose.sittingSnack,
  'sitting_laptop' => NomoCharacterPose.sittingLaptop,
  'sleeping_blanket' => NomoCharacterPose.sleepingBlanket,
  'sleeping_side' => NomoCharacterPose.sleepingSide,
  'reaction_happy' => NomoCharacterPose.reactionHappy,
  'reaction_laugh' => NomoCharacterPose.reactionLaugh,
  'reaction_teary' => NomoCharacterPose.reactionTeary,
  'reaction_angry' => NomoCharacterPose.reactionAngry,
  'reaction_worried' => NomoCharacterPose.reactionWorried,
  'reaction_wink' => NomoCharacterPose.reactionWink,
  'reaction_cool' => NomoCharacterPose.reactionCool,
  'icon_wink' => NomoCharacterPose.iconWink,
  'memu' => NomoCharacterPose.memu,
  'saigou' => NomoCharacterPose.saigou,
  'chi' => NomoCharacterPose.chi,
  'uo' => NomoCharacterPose.uo,
  'aren' => NomoCharacterPose.aren,
  _ => NomoCharacterPose.iconSmile,
};
