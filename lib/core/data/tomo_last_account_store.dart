import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tomo_avatar.dart';

class TomoLastAccount {
  const TomoLastAccount({required this.name, required this.email, this.avatar});

  final String name;
  final String email;
  final TomoAvatar? avatar;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    if (avatar != null) 'avatar': avatar!.encode(),
  };

  static TomoLastAccount? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final email = (raw['email'] as String?)?.trim();
    if (email == null || email.isEmpty) return null;
    final name = (raw['name'] as String?)?.trim();
    return TomoLastAccount(
      name: name == null || name.isEmpty ? _fallbackName(email) : name,
      email: email,
      avatar: TomoAvatar.decode(raw['avatar'] as String?),
    );
  }
}

class TomoLastAccountStore {
  const TomoLastAccountStore._();

  static const onboardingSeenKey = 'tomo_onboarding_seen';
  static const nameKey = 'tomo_last_account_name';
  static const emailKey = 'tomo_last_account_email';
  static const avatarKey = 'tomo_last_account_avatar';
  static const accountsKey = 'tomo_last_accounts_v1';
  static const maxAccounts = 3;

  static Future<TomoLastAccount?> load() async {
    final accounts = await loadAccounts();
    return accounts.isEmpty ? null : accounts.first;
  }

  static Future<List<TomoLastAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = <TomoLastAccount>[];
    final encoded = prefs.getString(accountsKey);
    if (encoded != null && encoded.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          for (final raw in decoded) {
            final account = TomoLastAccount.fromJson(raw);
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
    required TomoAvatar? avatar,
  }) async {
    final normalizedEmail = email?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final normalizedName = name?.trim();
    final account = TomoLastAccount(
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

  static TomoLastAccount? _legacyAccountFromPrefs(SharedPreferences prefs) {
    final email = prefs.getString(emailKey)?.trim();
    if (email == null || email.isEmpty) return null;
    final name = prefs.getString(nameKey)?.trim();
    return TomoLastAccount(
      name: name == null || name.isEmpty ? _fallbackName(email) : name,
      email: email,
      avatar: TomoAvatar.decode(prefs.getString(avatarKey)),
    );
  }

  static void _upsert(List<TomoLastAccount> accounts, TomoLastAccount account) {
    accounts.removeWhere(
      (item) => item.email.toLowerCase() == account.email.toLowerCase(),
    );
    accounts.insert(0, account);
    if (accounts.length > maxAccounts) {
      accounts.removeRange(maxAccounts, accounts.length);
    }
  }

  static void _appendUnique(
    List<TomoLastAccount> accounts,
    TomoLastAccount account,
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
