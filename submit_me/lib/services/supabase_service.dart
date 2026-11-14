import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// SUPABASE CONFIGURATION PLACEHOLDERS
// ============================================================================
// HOW TO INSERT YOUR CREDENTIALS:
// 1. Open your Supabase Dashboard: https://supabase.com/dashboard
// 2. Select your project.
// 3. Go to "Project Settings" (gear icon) -> "API".
// 4. Copy "Project URL" and paste it in `supabaseUrl` below.
// 5. Copy "Project API keys" -> "anon public" (Publishable Key) and paste it
//    in `supabasePublishableKey` below.
// CRITICAL SECURITY INSTRUCTION:
// NEVER use your `service_role` (secret) key here or anywhere in Flutter!
// ONLY use the public `anon` / `publishable` key.
// ============================================================================
const String supabaseUrl = 'https://ohpztbpeoffpnkmahxqe.supabase.co';
const String supabasePublishableKey = 'sb_publishable_GZD2CtIw1cZUoRvnEWOJHw_xp-b6HR8';

/// A simple, beginner-friendly helper service for Supabase.
/// This service provides straightforward static methods for Authentication,
/// avoiding complex architecture or unnecessary state management packages.
class SupabaseService {
  /// Checks whether actual credentials have been added instead of placeholders.
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('YOUR_SUPABASE') &&
        supabasePublishableKey.isNotEmpty &&
        !supabasePublishableKey.contains('YOUR_SUPABASE');
  }

  /// Direct reference to the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;

  /// Returns the currently authenticated Supabase user, or null if logged out.
  static User? get currentUser {
    if (!isConfigured) return null;
    return client.auth.currentUser;
  }

  /// Returns the current user's unique Supabase Auth UUID (user.id).
  /// This is used to enforce ownership and organize user folders in Storage.
  static String? get currentUserId {
    return currentUser?.id;
  }

  /// Returns the current user's email address.
  static String? get currentUserEmail {
    return currentUser?.email;
  }

  /// Returns the student's full name stored in user metadata,
  /// or falls back to the email prefix if not available.
  static String get currentUserName {
    final metadata = currentUser?.userMetadata;
    if (metadata != null &&
        metadata['full_name'] != null &&
        (metadata['full_name'] as String).isNotEmpty) {
      return metadata['full_name'] as String;
    }
    return currentUserEmail?.split('@').first ?? 'Student';
  }

  /// Returns true if an active session exists.
  static bool get isAuthenticated {
    if (!isConfigured) return false;
    return client.auth.currentSession != null;
  }

  /// Signs up a new student with Email, Password, and Full Name.
  /// The Full Name is stored in Supabase Auth user_metadata.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }

  /// Signs in an existing student with Email and Password.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user and clears the session.
  static Future<void> signOut() async {
    if (isConfigured) {
      await client.auth.signOut();
    }
  }

  // ============================================================================
  // DATABASE METHODS (public.assets table)
  // ============================================================================

  /// Returns the total number of files uploaded by the currently authenticated user.
  /// Queries: SELECT COUNT(*) FROM assets WHERE user_id = currentUser.id
  static Future<int> getUserAssetCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final count = await client
          .from('assets')
          .count(CountOption.exact)
          .eq('user_id', userId);
      return count;
    } catch (e) {
      // Return 0 if there was a network/database error
      return 0;
    }
  }

  /// Retrieves all assets uploaded by the current authenticated user.
  /// Strictly filters by `user_id = currentUserId` (enforced by RLS as well).
  static Future<List<Map<String, dynamic>>> getMyAssets() async {
    final userId = currentUserId;
    if (userId == null) return [];

    final List<dynamic> response = await client
        .from('assets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Retrieves shared assets across all authenticated users.
  /// Does not select uploader private data (like user_id/email) to preserve privacy.
  static Future<List<Map<String, dynamic>>> getPublicAssets() async {
    final List<dynamic> response = await client
        .from('assets')
        .select('id, topic_name, file_name, file_type, created_at')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
