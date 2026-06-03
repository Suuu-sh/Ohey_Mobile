/// Shared environment constants for Ohey Mobile.
///
/// Keep public, non-secret environment identifiers here so backend, Supabase,
/// redirect, and scripts do not drift. Private values still belong in
/// `/Users/yota/Projects/Secrets/Ohey` and CI/Render secrets.
class OheyEnvironmentValues {
  const OheyEnvironmentValues._();

  static const environmentDefineKey = 'OHEY_ENV';
  static const backendUrlDefineKey = 'OHEY_BACKEND_URL';
  static const supabaseUrlDefineKey = 'SUPABASE_URL';
  static const supabasePublishableKeyDefineKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const supabaseAuthRedirectUrlDefineKey = 'SUPABASE_AUTH_REDIRECT_URL';

  static const devEnvironment = 'dev';
  static const productionEnvironment = 'production';

  static const devBackendUrl = 'https://dev-ohey-backend.onrender.com';
  static const productionBackendUrl = 'https://ohey-backend.onrender.com';

  static const devSupabaseUrl = 'https://wwyaftonswgxnjcceyfb.supabase.co';
  static const devSupabasePublishableKey =
      'sb_publishable_pPvKPrOvVmkKQIXKVWj2Rw_DlYkm0Ty';
  static const productionSupabaseUrl =
      'https://pwifgddolctqghygwxwj.supabase.co';
  static const productionSupabasePublishableKey =
      'sb_publishable_pezjPt7pYRECNFdydlon8A_RpSjNulk';

  static const devAuthRedirectUrl = 'app.ohey.com.dev://login-callback/';
  static const productionAuthRedirectUrl = 'app.ohey.com://login-callback/';

  static const mistypedProductionSupabaseUrl =
      'https://pwifgddolctqhygywxwj.supabase.co';
}
