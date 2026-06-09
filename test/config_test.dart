import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/config/auth_provider_config.dart';
import 'package:ohey/core/config/backend_config.dart';

void main() {
  test('debug/test builds use dev Clerk redirect and dev Render backend', () {
    expect(AuthProviderConfig.redirectUrl, 'app.ohey.com://login-callback/');
    expect(BackendConfig.baseUrl, 'https://dev-ohey-backend.onrender.com');
  });
}
