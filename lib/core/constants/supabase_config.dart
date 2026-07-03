import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Replace with your actual Supabase project URL and anon key
  static const String supabaseUrl = 'https://naqzooqfueniqrgwveeg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_8ny5d9ZTDBSMB6iaTwRbkg_3y5T50Bs';

  // Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String eventCoversBucket = 'event-covers';
  static const String blogImagesBucket = 'blog-images';
  static const String galleryBucket = 'gallery';

  // Get the Supabase client singleton
  static SupabaseClient get client => Supabase.instance.client;

  // Get currently authenticated user
  static User? get currentUser => client.auth.currentUser;

  // Get current user ID
  static String? get currentUserId => currentUser?.id;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Get public URL for a file in a bucket
  static String getPublicUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  // Get signed URL for private buckets (like avatars)
  static Future<String> getSignedUrl(
    String bucket,
    String path, {
    int expiresIn = 3600,
  }) async {
    return client.storage.from(bucket).createSignedUrl(path, expiresIn);
  }
}
