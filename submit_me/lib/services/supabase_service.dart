import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// SUPABASE CONFIGURATION
// ============================================================================
const String supabaseUrl = 'https://ohpztbpeoffpnkmahxqe.supabase.co';
const String supabasePublishableKey = 'sb_publishable_GZD2CtIw1cZUoRvnEWOJHw_xp-b6HR8';

/// A simple, beginner-friendly helper service for Supabase Authentication,
/// PostgreSQL Database queries, and Storage operations.
class SupabaseService {
  /// Name of the private Supabase Storage bucket for assets
  static const String storageBucket = 'submitme-assets';

  /// Maximum file size allowed: 10 MB (10 * 1024 * 1024 bytes)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

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

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  /// Signs up a new student with Email, Password, and Full Name.
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
      debugPrint('Error getting asset count: $e');
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
  /// Preserves privacy: does NOT select user_id or uploader email.
  static Future<List<Map<String, dynamic>>> getPublicAssets() async {
    final List<dynamic> response = await client
        .from('assets')
        .select('id, topic_name, file_name, file_path, file_type, created_at')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================================================
  // STORAGE & UPLOAD/DOWNLOAD/DELETE METHODS
  // ============================================================================

  /// Uploads a file to Supabase Storage and inserts its metadata into `public.assets`.
  /// Uses a transaction-like rollback: if inserting into the database fails,
  /// the uploaded storage file is immediately deleted to avoid orphaned files.
  static Future<void> uploadAsset({
    required String topicName,
    required String originalFileName,
    required String fileType,
    required Uint8List fileBytes,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    // 1. Validate file size (10 MB limit)
    if (fileBytes.length > maxFileSizeBytes) {
      throw Exception(
        'File exceeds the 10 MB limit (${(fileBytes.length / (1024 * 1024)).toStringAsFixed(1)} MB).',
      );
    }

    // 2. Validate file type
    final cleanExtension = fileType.toLowerCase().replaceAll('.', '').trim();
    if (!['pdf', 'png', 'jpg', 'jpeg'].contains(cleanExtension)) {
      throw Exception(
        'Unsupported file type (.$cleanExtension). Only PDF, PNG, JPG, and JPEG files are allowed.',
      );
    }

    // 3. Determine MIME type
    String mimeType = 'application/octet-stream';
    if (cleanExtension == 'pdf') {
      mimeType = 'application/pdf';
    } else if (cleanExtension == 'png') {
      mimeType = 'image/png';
    } else if (cleanExtension == 'jpg' || cleanExtension == 'jpeg') {
      mimeType = 'image/jpeg';
    }

    // 4. Construct unique storage path: {user_id}/{timestamp}_{cleaned_filename}
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedFileName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final storagePath = '$userId/${timestamp}_$sanitizedFileName';

    // 5. Upload binary bytes to the private storage bucket
    try {
      await client.storage.from(storageBucket).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );
    } catch (uploadError) {
      throw Exception('Storage upload failed: $uploadError');
    }

    // 6. Insert metadata into public.assets table
    try {
      await client.from('assets').insert({
        'user_id': userId,
        'topic_name': topicName.trim(),
        'file_name': originalFileName,
        'file_path': storagePath,
        'file_type': cleanExtension,
      });
    } catch (dbError) {
      // Rollback: delete the uploaded file from storage so no orphaned file remains
      try {
        await client.storage.from(storageBucket).remove([storagePath]);
      } catch (cleanupError) {
        throw Exception(
          'Database record creation failed: $dbError. Automatic storage cleanup also failed: $cleanupError',
        );
      }
      throw Exception('Database record creation failed: $dbError');
    }
  }

  /// Generates a short-lived signed URL (valid for 60 seconds) to securely view
  /// or download a file from the private Storage bucket.
  static Future<String> getSignedUrl(String storagePath) async {
    return await client.storage
        .from(storageBucket)
        .createSignedUrl(storagePath, 60);
  }

  /// Deletes an asset: removes the file from Supabase Storage and deletes the
  /// corresponding database record from `public.assets`.
  static Future<void> deleteAsset({
    required String assetId,
    required String storagePath,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    // 1. Delete file from Storage first
    try {
      await client.storage.from(storageBucket).remove([storagePath]);
    } catch (storageError) {
      debugPrint('Notice: Storage file could not be removed: $storageError');
    }

    // 2. Delete database record strictly ensuring user_id = current user
    await client
        .from('assets')
        .delete()
        .eq('id', assetId)
        .eq('user_id', userId);
  }
}
