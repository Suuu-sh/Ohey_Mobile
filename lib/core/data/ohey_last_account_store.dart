import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ohey_avatar.dart';

class OheyLastAccount {
  const OheyLastAccount({required this.name, required this.email, this.avatar});

  final String name;
  final String email;
  final OheyAvatar? avatar;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    if (avatar != null) 'avatar': avatar!.encode(),
  };

  static OheyLastAccount? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final email = (raw['email'] as String?)?.trim();
    if (email == null || email.isEmpty) return null;
    final name = (raw['name'] as String?)?.trim();
    return OheyLastAccount(
      name: name == null || name.isEmpty ? _fallbackName(email) : name,
      email: email,
      avatar: OheyAvatar.decode(raw['avatar'] as String?),
    );
  }
}

class OheyLastAccountStore {
  const OheyLastAccountStore._();

  static const onboardingSeenKey = 'ohey_onboarding_seen';
  static const nameKey = 'ohey_last_account_name';
  static const emailKey = 'ohey_last_account_email';
  static const avatarKey = 'ohey_last_account_avatar';
  static const accountsKey = 'ohey_last_accounts_v1';
  static const sessionRestoreSuppressedKey = 'ohey_session_restore_suppressed';
  static const maxAccounts = 3;

  static Future<OheyLastAccount?> load() async {
    final accounts = await loadAccounts();
    return accounts.isEmpty ? null : accounts.first;
  }

  static Future<List<OheyLastAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = <OheyLastAccount>[];
    final encoded = prefs.getString(accountsKey);
    if (encoded != null && encoded.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          for (final raw in decoded) {
            final account = OheyLastAccount.fromJson(raw);
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
    required OheyAvatar? avatar,
  }) async {
    final normalizedEmail = email?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final normalizedName = name?.trim();
    final account = OheyLastAccount(
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

  static Future<void> setSessionRestoreSuppressed(bool suppressed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sessionRestoreSuppressedKey, suppressed);
  }

  static Future<bool> isSessionRestoreSuppressed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(sessionRestoreSuppressedKey) ?? false;
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

  static OheyLastAccount? _legacyAccountFromPrefs(SharedPreferences prefs) {
    final email = prefs.getString(emailKey)?.trim();
    if (email == null || email.isEmpty) return null;
    final name = prefs.getString(nameKey)?.trim();
    return OheyLastAccount(
      name: name == null || name.isEmpty ? _fallbackName(email) : name,
      email: email,
      avatar: OheyAvatar.decode(prefs.getString(avatarKey)),
    );
  }

  static void _upsert(List<OheyLastAccount> accounts, OheyLastAccount account) {
    accounts.removeWhere(
      (item) => item.email.toLowerCase() == account.email.toLowerCase(),
    );
    accounts.insert(0, account);
    if (accounts.length > maxAccounts) {
      accounts.removeRange(maxAccounts, accounts.length);
    }
  }

  static void _appendUnique(
    List<OheyLastAccount> accounts,
    OheyLastAccount account,
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
  return localPart.isEmpty ? 'Oheyユーザー' : localPart;
}
