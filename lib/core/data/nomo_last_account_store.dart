import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/nomo_avatar.dart';

class NomoLastAccount {
  const NomoLastAccount({required this.name, required this.email, this.avatar});

  final String name;
  final String email;
  final NomoAvatar? avatar;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    if (avatar != null) 'avatar': avatar!.encode(),
  };

  static NomoLastAccount? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final email = (raw['email'] as String?)?.trim();
    if (email == null || email.isEmpty) return null;
    final name = (raw['name'] as String?)?.trim();
    return NomoLastAccount(
      name: name == null || name.isEmpty ? _fallbackName(email) : name,
      email: email,
      avatar: NomoAvatar.decode(raw['avatar'] as String?),
    );
  }
}

class NomoLastAccountStore {
  const NomoLastAccountStore._();

  static const onboardingSeenKey = 'nomo_onboarding_seen';
  static const nameKey = 'nomo_last_account_name';
  static const emailKey = 'nomo_last_account_email';
  static const avatarKey = 'nomo_last_account_avatar';
  static const accountsKey = 'nomo_last_accounts_v1';
  static const maxAccounts = 3;

  static Future<NomoLastAccount?> load() async {
    final accounts = await loadAccounts();
    return accounts.isEmpty ? null : accounts.first;
  }

  static Future<List<NomoLastAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = <NomoLastAccount>[];
    final encoded = prefs.getString(accountsKey);
    if (encoded != null && encoded.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          for (final raw in decoded) {
            final account = NomoLastAccount.fromJson(raw);
            if (account != null) _appendUnique(accounts, account);
          }
        }
      } catch (_) {
        // Corrupt cache should not block login. Fall back to legacy keys below.
      }
    }

    final legacyAccount = _legacyAccountFromPrefs(prefs);
    if (legacyAccount != null) _appendUnique(accounts, legacyAccount);
    return accounts.take(maxAccounts).toList(growable: false);
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
    final account = NomoLastAccount(
      name: normalizedName == null || normalizedName.isEmpty
          ? _fallbackName(normalizedEmail)
          : normalizedName,
      email: normalizedEmail,
      avatar: avatar,
    );
    final accounts = (await loadAccounts()).toList();
    _upsert(accounts, account);
    final capped = accounts.take(maxAccounts).toList(growable: false);
    await prefs.setString(
      accountsKey,
      jsonEncode(capped.map((item) => item.toJson()).toList(growable: false)),
    );

    // Keep latest account in legacy keys so existing installs and tests migrate safely.
    await prefs.setString(nameKey, account.name);
    await prefs.setString(emailKey, account.email);
    if (account.avatar == null) {
      await prefs.remove(avatarKey);
    } else {
      await prefs.setString(avatarKey, account.avatar!.encode());
    }
  }

  static Future<void> remove(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final accounts = (await loadAccounts())
        .where((item) => item.email.toLowerCase() != normalizedEmail)
        .take(maxAccounts)
        .toList(growable: false);
    await prefs.setString(
      accountsKey,
      jsonEncode(accounts.map((item) => item.toJson()).toList(growable: false)),
    );

    if (accounts.isEmpty) {
      await prefs.remove(nameKey);
      await prefs.remove(emailKey);
      await prefs.remove(avatarKey);
      return;
    }

    final latest = accounts.first;
    await prefs.setString(nameKey, latest.name);
    await prefs.setString(emailKey, latest.email);
    if (latest.avatar == null) {
      await prefs.remove(avatarKey);
    } else {
      await prefs.setString(avatarKey, latest.avatar!.encode());
    }
  }

  static NomoLastAccount? _legacyAccountFromPrefs(SharedPreferences prefs) {
    final email = prefs.getString(emailKey)?.trim();
    if (email == null || email.isEmpty) return null;
    final name = prefs.getString(nameKey)?.trim();
    return NomoLastAccount(
      name: name == null || name.isEmpty ? _fallbackName(email) : name,
      email: email,
      avatar: NomoAvatar.decode(prefs.getString(avatarKey)),
    );
  }

  static void _upsert(List<NomoLastAccount> accounts, NomoLastAccount account) {
    accounts.removeWhere(
      (item) => item.email.toLowerCase() == account.email.toLowerCase(),
    );
    accounts.insert(0, account);
    if (accounts.length > maxAccounts) {
      accounts.removeRange(maxAccounts, accounts.length);
    }
  }

  static void _appendUnique(
    List<NomoLastAccount> accounts,
    NomoLastAccount account,
  ) {
    final exists = accounts.any(
      (item) => item.email.toLowerCase() == account.email.toLowerCase(),
    );
    if (exists) return;
    accounts.add(account);
    if (accounts.length > maxAccounts) {
      accounts.removeRange(maxAccounts, accounts.length);
    }
  }
}

String _fallbackName(String email) {
  final localPart = email.split('@').first.trim();
  return localPart.isEmpty ? 'Tomoユーザー' : localPart;
}
