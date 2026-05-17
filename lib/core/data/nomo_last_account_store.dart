import 'package:shared_preferences/shared_preferences.dart';

import '../models/nomo_avatar.dart';

class NomoLastAccount {
  const NomoLastAccount({required this.name, required this.email, this.avatar});

  final String name;
  final String email;
  final NomoAvatar? avatar;
}

class NomoLastAccountStore {
  const NomoLastAccountStore._();

  static const onboardingSeenKey = 'nomo_onboarding_seen';
  static const nameKey = 'nomo_last_account_name';
  static const emailKey = 'nomo_last_account_email';
  static const avatarKey = 'nomo_last_account_avatar';

  static Future<NomoLastAccount?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(emailKey)?.trim();
    if (email == null || email.isEmpty) return null;

    final name = prefs.getString(nameKey)?.trim();
    return NomoLastAccount(
      name: name == null || name.isEmpty ? _fallbackName(email) : name,
      email: email,
      avatar: NomoAvatar.decode(prefs.getString(avatarKey)),
    );
  }

  static Future<void> save({
    required String? name,
    required String? email,
    required NomoAvatar? avatar,
  }) async {
    final normalizedEmail = email?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final normalizedName = name?.trim();
    await prefs.setString(
      nameKey,
      normalizedName == null || normalizedName.isEmpty
          ? _fallbackName(normalizedEmail)
          : normalizedName,
    );
    await prefs.setString(emailKey, normalizedEmail);
    if (avatar == null) {
      await prefs.remove(avatarKey);
    } else {
      await prefs.setString(avatarKey, avatar.encode());
    }
  }

  static String _fallbackName(String email) {
    final localPart = email.split('@').first.trim();
    return localPart.isEmpty ? 'Nomoユーザー' : localPart;
  }
}
