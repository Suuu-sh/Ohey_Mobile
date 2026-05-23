part of 'create_user_dialog.dart';

String _oauthScopes(OAuthProvider provider) {
  switch (provider) {
    case OAuthProvider.apple:
      return 'name email';
    case OAuthProvider.google:
      return 'email profile';
    default:
      return '';
  }
}

bool _hasValidPassword(String password) =>
    password.length >= _minPasswordLength;

String? _displayNameFromOAuth(User user) {
  final metadata = user.userMetadata;
  final candidates = [
    metadata?['display_name'],
    metadata?['full_name'],
    metadata?['name'],
    user.email?.split('@').first,
  ];
  for (final candidate in candidates) {
    final value = candidate?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
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
