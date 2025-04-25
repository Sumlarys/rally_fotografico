// lib/services/photo_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_model.dart';

class PhotoService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Uploads [file] under "{userId}/{timestamp_filename}" and
  /// records it in the "photos" table.
  Future<String?> uploadPhoto(File file, String userId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = '$userId/$fileName';

      // 1️⃣ Upload returns a String path now:
      final String storagePath = await _db
          .storage
          .from('photos')
          .upload(path, file, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ));

      // 2️⃣ GetPublicUrl returns a String URL:
      final String publicUrl =
          _db.storage.from('photos').getPublicUrl(storagePath);

      // 3️⃣ Insert metadata; throws on error:
      await _db.from('photos').insert({
        'user_id': userId,
        'url': publicUrl,
      });

      return publicUrl;
    } catch (err) {
      print('⚠️ uploadPhoto failed: $err');
      return null;
    }
  }

  /// Fetches the current user's photos (newest first).
  Future<List<Photo>> fetchUserPhotos(String userId) async {
    try {
      // Returns List<dynamic> on success or throws.
      final data = await _db
          .from('photos')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => Photo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (err) {
      print('⚠️ fetchUserPhotos failed: $err');
      return [];
    }
  }

  /// Fetches approved photos for the public gallery.
  Future<List<Photo>> fetchApprovedPhotos() async {
    try {
      final data = await _db
          .from('photos')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => Photo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (err) {
      print('⚠️ fetchApprovedPhotos failed: $err');
      return [];
    }
  }
}
