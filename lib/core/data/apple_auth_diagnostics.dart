import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:flutter/foundation.dart';

enum AppleAuthDiagnosticStage {
  availabilityProbe,
  credential,
  clerkInitialization,
  clerkIdTokenExchange,
  clerkSessionCompletion,
  profileSessionCompletion,
}

/// Logs only structured Apple auth diagnostics in debug builds.
///
/// Never pass exception messages, request data, or credential values as a
/// reason. [safeReason] is intended only for fixed labels or enum names.
void logAppleAuthFailure({
  required AppleAuthDiagnosticStage stage,
  required Object error,
  String? safeReason,
}) {
  if (!kDebugMode) return;
  debugPrint(
    formatAppleAuthFailureDiagnostic(
      stage: stage,
      error: error,
      safeReason: safeReason,
    ),
  );
}

/// Formats a diagnostic without reading `toString`, messages, arguments, or
/// stack traces from [error].
@visibleForTesting
String formatAppleAuthFailureDiagnostic({
  required AppleAuthDiagnosticStage stage,
  required Object error,
  String? safeReason,
}) {
  final fields = <String>[
    '[AppleAuth]',
    'stage=${stage.name}',
    'type=${error.runtimeType}',
  ];
  if (error case clerk.ClerkError(:final code)) {
    fields.add('clerkCode=${code.name}');
    final externalCodes = error.errors?.errors
        ?.map((externalError) => externalError.code)
        .whereType<String>()
        .where(_isSafeExternalCode)
        .take(3)
        .toList();
    if (externalCodes != null && externalCodes.isNotEmpty) {
      fields.add('clerkExternalCodes=${externalCodes.join(',')}');
    }
    // Error metadata can contain credentials; read only known field names.
    const allowedParams = {
      'strategy',
      'token',
      'nonce',
      'identifier',
      'client_id',
      'redirect_url',
      'first_name',
      'last_name',
    };
    final rejectedParams = error.errors?.errors
        ?.map((externalError) => externalError.meta?['param_name'])
        .whereType<String>()
        .where(allowedParams.contains)
        .take(3)
        .toList();
    if (rejectedParams != null && rejectedParams.isNotEmpty) {
      fields.add('clerkRejectedParams=${rejectedParams.join(',')}');
    }
  }
  final reason = sanitizeAppleAuthDiagnosticReason(safeReason);
  if (reason != null) fields.add('reason=$reason');
  return fields.join(' ');
}

bool _isSafeExternalCode(String code) =>
    code.length <= 64 && RegExp(r'^[A-Za-z][A-Za-z0-9_.-]*$').hasMatch(code);

/// Redacts credential/identity-like values before including a structured
/// reason. Callers should still pass only fixed labels or enum names.
@visibleForTesting
String? sanitizeAppleAuthDiagnosticReason(String? reason) {
  if (reason == null || reason.isEmpty) return null;

  var sanitized = reason.replaceAll(RegExp(r'[\r\n\t]'), ' ');
  sanitized = sanitized.replaceAll(
    RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b'),
    '[redacted-jwt]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(
      r'''\b(email)\b\s*[:=]\s*(?:"[^"]*"|'[^']*'|[^\s,;&]+)''',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}=[redacted-email]',
  );
  sanitized = sanitized.replaceAll(
    RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false),
    '[redacted-email]',
  );
  sanitized = sanitized.replaceAll(
    RegExp(r'\bBearer\s+[^\s,;]+', caseSensitive: false),
    'Bearer [redacted]',
  );
  sanitized = sanitized.replaceAllMapped(
    RegExp(
      r'''\b((?:id[_ -]?token|access[_ -]?token|refresh[_ -]?token|token|authorization[_ -]?code|auth[_ -]?code|code|nonce|name|given[_ -]?name|family[_ -]?name|first[_ -]?name|last[_ -]?name|full[_ -]?name|password|secret))\b\s*[:=]\s*(?:"[^"]*"|'[^']*'|[^\s,;&]+)''',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}=[redacted]',
  );
  sanitized = sanitized.replaceAll(
    RegExp(r'\b[A-Za-z0-9_+/=-]{24,}\b'),
    '[redacted-token]',
  );
  sanitized = sanitized.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  if (sanitized.isEmpty) return null;
  if (sanitized.length > 120) {
    sanitized = '${sanitized.substring(0, 120)}…';
  }
  return sanitized;
}
