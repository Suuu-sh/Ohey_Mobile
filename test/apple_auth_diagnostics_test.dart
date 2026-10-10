import 'package:clerk_auth/clerk_auth.dart' as clerk;
// ignore: implementation_imports
import 'package:clerk_auth/src/models/api/external_error.dart' as clerk_errors;
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/data/apple_auth_diagnostics.dart';

void main() {
  test('logs only allowlisted Clerk rejected parameter names', () {
    final error = clerk.ClerkError(
      code: clerk.ClerkErrorCode.serverErrorResponse,
      message: 'private',
      errors: const clerk_errors.ExternalErrorCollection(
        errors: [
          clerk_errors.ExternalError(
            message: 'private',
            meta: {'param_name': 'strategy', 'value': 'private-value'},
          ),
          clerk_errors.ExternalError(
            message: 'private',
            meta: {'param_name': 'user@example.com'},
          ),
          clerk_errors.ExternalError(
            message: 'private',
            meta: {'param_name': 'token', 'token': 'private-token'},
          ),
        ],
      ),
    );
    final diagnostic = formatAppleAuthFailureDiagnostic(
      stage: AppleAuthDiagnosticStage.clerkIdTokenExchange,
      error: error,
    );
    expect(diagnostic, contains('clerkRejectedParams=strategy,token'));
    expect(diagnostic, isNot(contains('private')));
    expect(diagnostic, isNot(contains('user@example.com')));
  });

  test('formats only safe structured Clerk error fields', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature';
    final error = clerk.ClerkError(
      code: clerk.ClerkErrorCode.serverErrorResponse,
      message: 'Rejected $jwt for user@example.com',
      argument: 'authorization_code=private-code',
      errors: const clerk_errors.ExternalErrorCollection(
        errors: [
          clerk_errors.ExternalError(
            message: 'Private server detail',
            code: 'form_param_format_invalid',
          ),
          clerk_errors.ExternalError(
            message: 'Another private detail',
            code: 'user@example.com',
          ),
        ],
      ),
    );

    final diagnostic = formatAppleAuthFailureDiagnostic(
      stage: AppleAuthDiagnosticStage.clerkIdTokenExchange,
      error: error,
      safeReason: 'invalid_response',
    );

    expect(diagnostic, contains('stage=clerkIdTokenExchange'));
    expect(diagnostic, contains('type=ClerkError'));
    expect(diagnostic, contains('clerkCode=serverErrorResponse'));
    expect(
      diagnostic,
      contains('clerkExternalCodes=form_param_format_invalid'),
    );
    expect(diagnostic, contains('reason=invalid_response'));
    expect(diagnostic, isNot(contains(jwt)));
    expect(diagnostic, isNot(contains('user@example.com')));
    expect(diagnostic, isNot(contains('private-code')));
    expect(diagnostic, isNot(contains('Private server detail')));
  });

  test('redacts JWT, email, identity fields, and token-like values', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature';
    const token = 'appleidtokenvalue12345678901234567890';
    const code = 'appleauthorizationcodevalue1234567890';
    const nonce = 'randomnoncevalue12345678901234567890';
    const bearer = 'bearersecretvalue12345678901234567890';

    final sanitized = [
      sanitizeAppleAuthDiagnosticReason('jwt=$jwt email=user@example.com'),
      sanitizeAppleAuthDiagnosticReason(
        'id_token=$token authorization_code=$code nonce=$nonce given_name=Alice',
      ),
      sanitizeAppleAuthDiagnosticReason('Bearer $bearer $token'),
    ].join(' ');

    expect(sanitized, contains('[redacted-jwt]'));
    expect(sanitized, contains('[redacted-email]'));
    expect(sanitized, contains('id_token=[redacted]'));
    expect(sanitized, contains('authorization_code=[redacted]'));
    expect(sanitized, contains('nonce=[redacted]'));
    expect(sanitized, contains('given_name=[redacted]'));
    expect(sanitized, contains('Bearer [redacted]'));
    expect(sanitized, isNot(contains(jwt)));
    expect(sanitized, isNot(contains('user@example.com')));
    expect(sanitized, isNot(contains(token)));
    expect(sanitized, isNot(contains(code)));
    expect(sanitized, isNot(contains(nonce)));
    expect(sanitized, isNot(contains('Alice')));
    expect(sanitized, isNot(contains(bearer)));
  });

  test('sanitized diagnostic reasons are truncated', () {
    final sanitized = sanitizeAppleAuthDiagnosticReason(
      List.filled(30, 'reason').join(' '),
    );

    expect(sanitized, isNotNull);
    expect(sanitized!.length, 121);
    expect(sanitized, endsWith('…'));
  });
}
