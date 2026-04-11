class EnvConfig {
  EnvConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw const FormatException(
        'Missing Supabase keys. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }
  }
}
