import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/config/backend_config.dart';
import 'package:ohey/core/config/supabase_config.dart';

void main() {
  test('debug/test builds use dev Supabase and dev Render backend', () {
    expect(SupabaseConfig.url, 'https://wwyaftonswgxnjcceyfb.supabase.co');
    expect(
      SupabaseConfig.authRedirectUrl,
      'app.ohey.ohey.dev://login-callback/',
    );
    expect(BackendConfig.baseUrl, 'https://dev-ohey-backend.onrender.com');
    expect(
      SupabaseConfig.expectedAuthIssuer,
      '${SupabaseConfig.uri.origin}/auth/v1',
    );
  });
}
