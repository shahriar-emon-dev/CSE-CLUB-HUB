class EnvConfig {
  EnvConfig._();

  // Development defaults — override via --dart-define-from-file=.env/dev.json
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ptlmzzfwbvyohtwfdqlj.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_UOKzCkOzKMHruHX6JlYh8g_ugviSW25',
  );

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw const FormatException(
        'Missing Supabase keys. Provide SUPABASE_URL and SUPABASE_ANON_KEY via:\n'
        '  flutter run --dart-define-from-file=.env/dev.json',
      );
    }
  }
}
