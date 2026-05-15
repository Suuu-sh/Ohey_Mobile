/// Go backend environment configuration for Nomo.
///
/// The default points to the dev backend so local builds without dart defines
/// cannot write to production by mistake. TestFlight/production builds must
/// pass an explicit production `NOMO_BACKEND_URL`.
class BackendConfig {
  const BackendConfig._();

  static const baseUrl = String.fromEnvironment(
    'NOMO_BACKEND_URL',
    defaultValue: 'https://dev-nomo-backend.onrender.com',
  );
}
