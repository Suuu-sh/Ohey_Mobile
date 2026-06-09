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

  // Temporary during the migration: several non-auth services still read
  // Supabase directly. Keep initialization on until those dependencies move
  // behind backend APIs / replacement services.
  static bool get shouldInitializeSupabase => true;
}
