import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Guards against using a cached Supabase session from another project.
///
/// During development we switch between `tomo` and `dev-nomo`. Supabase stores
/// the session locally, so an old production JWT can otherwise be sent to the
/// dev PostgREST API and produce `PGRST301: No suitable key` on calendar/friend
/// screens.
class AuthSessionGuard {
  const AuthSessionGuard._();

  static Future<void> clearIfProjectMismatch(SupabaseClient supabase) async {
    final token = supabase.auth.currentSession?.accessToken;
    if (token == null || token.isEmpty) return;
    if (isTokenForCurrentProject(token)) return;

    await supabase.auth.signOut(scope: SignOutScope.local);
  }

  static bool isTokenForCurrentProject(String token) {
    final issuer = issuerFromAccessToken(token);
    if (issuer == null || issuer.isEmpty) return false;
    return issuer == SupabaseConfig.expectedAuthIssuer;
  }

  static String? issuerFromAccessToken(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded['iss'] is String) {
        return decoded['iss'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
