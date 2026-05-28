/// Admin-only Mobile configuration.
///
/// Values are supplied by dart-defines from local environment variables.
/// Do not hardcode private/admin account addresses in app code.
class AdminConfig {
  const AdminConfig._();

  static const _adminEmails = String.fromEnvironment('TOMO_ADMIN_EMAILS');

  static bool isAdminEmail(String? email) {
    final normalized = (email ?? '').trim().toLowerCase();
    if (normalized.isEmpty || _adminEmails.trim().isEmpty) return false;

    return _adminEmails
        .split(',')
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .contains(normalized);
  }
}
