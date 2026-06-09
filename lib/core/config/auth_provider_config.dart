import 'ohey_environment.dart';

class AuthProviderConfig {
  const AuthProviderConfig._();

  static const provider = String.fromEnvironment(
    OheyEnvironmentValues.authProviderDefineKey,
    defaultValue: 'supabase',
  );

  static const clerkPublishableKey = String.fromEnvironment(
    OheyEnvironmentValues.clerkPublishableKeyDefineKey,
  );

  static bool get isClerkEnabled =>
      provider.toLowerCase() == 'clerk' &&
      clerkPublishableKey.trim().isNotEmpty;

  static bool get isSupabaseEnabled => !isClerkEnabled;

  // Clerk mode should not initialize or access Supabase from Mobile.
  // Supabase mode is kept only as the migration fallback.
  static bool get shouldInitializeSupabase => isSupabaseEnabled;
}
