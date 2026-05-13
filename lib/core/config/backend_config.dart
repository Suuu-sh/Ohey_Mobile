/// Go backend environment configuration for Nomo.
///
/// Auth is handled by Supabase Auth in Flutter. App data is routed through the
/// Go backend so server-side validation/business rules can be added without
/// changing the app UI later.
class BackendConfig {
  const BackendConfig._();

  static const baseUrl = String.fromEnvironment(
    'NOMO_BACKEND_URL',
    defaultValue: 'https://dev-nomo-backend.onrender.com',
  );
}
