class EnvConfig {
  EnvConfig._();

  static const _fallbackSupabaseUrl =
      'https://ptlmzzfwbvyohtwfdqlj.supabase.co';
  static const _fallbackSupabaseAnonKey =
      'sb_publishable_UOKzCkOzKMHruHX6JlYh8g_ugviSW25';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _fallbackSupabaseUrl,
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _fallbackSupabaseAnonKey,
  );

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw const FormatException(
        'Missing Supabase keys. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }
  }
}
