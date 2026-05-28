import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/config/backend_config.dart';
import 'package:tomo/core/config/supabase_config.dart';

void main() {
  test('debug/test builds use dev Supabase and dev Render backend', () {
    expect(SupabaseConfig.url, 'https://wwyaftonswgxnjcceyfb.supabase.co');
    expect(
      SupabaseConfig.authRedirectUrl,
      'app.tomo.tomo.dev://login-callback/',
    );
    expect(BackendConfig.baseUrl, 'https://dev-nomo-backend.onrender.com');
    expect(
      SupabaseConfig.expectedAuthIssuer,
      '${SupabaseConfig.uri.origin}/auth/v1',
    );
  });
}
