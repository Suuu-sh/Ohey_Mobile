part of 'create_user_dialog.dart';

bool _hasValidPassword(String password) =>
    password.length >= _minPasswordLength;

bool _hasMatchingPasswords(String password, String confirmation) =>
    password == confirmation;

bool _hasValidSignupPasswords(String password, String confirmation) =>
    _hasValidPassword(password) &&
    _hasMatchingPasswords(password, confirmation);

const _emailInputRequirementMessage = '半角のメールアドレスを入力してね。';
const _passwordConfirmationRequirementMessage = 'パスワードが一致していません。';

bool _hasValidEmailAddress(String email) {
  final normalized = email.trim();
  if (normalized.isEmpty) return false;
  final asciiOnly = normalized.codeUnits.every(
    (unit) => unit >= 0x21 && unit <= 0x7E,
  );
  if (!asciiOnly) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
}

String _friendlyAuthError(String message) {
  final lower = message.toLowerCase();
  if (_isNetworkAuthError(lower)) {
    return _networkAuthErrorMessage;
  }
  if (lower.contains('invalid login credentials')) {
    return 'メールアドレスかパスワードを確認してね。';
  }
  if (lower.contains('email not confirmed')) {
    return '確認メールのリンクを開いてね。';
  }
  return message;
}

String _friendlyUnexpectedAuthError(Object error) {
  final lower = error.toString().toLowerCase();
  if (_isNetworkAuthError(lower)) return _networkAuthErrorMessage;
  return 'ログインに失敗しました。あとでもう一度試してね。';
}

const _networkAuthErrorMessage = '接続できなかったよ。通信環境を確認してね。';

bool _isNetworkAuthError(String lowerMessage) {
  return lowerMessage.contains('socketexception') ||
      lowerMessage.contains('clientexception') ||
      lowerMessage.contains('connection refused') ||
      lowerMessage.contains('failed host lookup') ||
      lowerMessage.contains('connection timed out');
}

Widget _fixedAuthPage({
  required BoxConstraints constraints,
  required EdgeInsets padding,
  required Widget child,
}) {
  final availableHeight = constraints.maxHeight.isFinite
      ? constraints.maxHeight - padding.vertical
      : 720.0;
  return Padding(
    padding: padding,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SizedBox(
          height: availableHeight > 0 ? availableHeight : 0,
          child: child,
        ),
      ),
    ),
  );
}
