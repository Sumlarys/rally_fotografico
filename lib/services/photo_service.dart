// lib/services/photo_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_model.dart';

class PhotoService {
  final SupabaseClient _db = Supabase.instance.client;

  /// Uploads [file] under '{userId}/{timestamp.ext}', stores it in Supabase Storage,
  /// inserts a metadata row in 'photos', and returns the public URL (or null on error).
  Future<String?> uploadPhoto(File file, String userId) async {
    const bucket = 'photos';
    final ext = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$userId/$fileName';

    try {
      // 1️⃣ Upload binary to Storage
      await _db.storage
          .from(bucket)
          .uploadBinary(
            path,
            await file.readAsBytes(),
            fileOptions: const FileOptions(upsert: true),
          );

      // 2️⃣ Get public URL
      // 2️⃣ Get public URL
      final publicUrl = _db.storage.from(bucket).getPublicUrl(path);

      // 3️⃣ Insert metadata row
      await _db.from('photos').insert({'user_id': userId, 'url': publicUrl});

      return publicUrl;
    } catch (e) {
      print('🚨 uploadPhoto error: $e');
      return null;
    }
  }

  /// Fetches all photos belonging to [userId], ordered newest first.
  Future<List<Photo>> fetchUserPhotos(String userId) async {
    try {
      final data = await _db
          .from('photos')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => Photo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('⚠️ fetchUserPhotos failed: $e');
      return [];
    }
  }

  /// Fetches all approved photos for the public gallery, newest first.
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
    } catch (e) {
      print('⚠️ fetchApprovedPhotos failed: $e');
      return [];
    }
  }

  /// Fetches pending photos (for admin review), newest first.
  Future<List<Photo>> fetchPendingPhotos() async {
    try {
      final data = await _db
          .from('photos')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => Photo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('⚠️ fetchPendingPhotos failed: $e');
      return [];
    }
  }

  /// Updates the 'status' of a photo (e.g., 'approved' or 'rejected').
  Future<bool> updatePhotoStatus(String photoId, String newStatus) async {
    try {
      await _db.from('photos').update({'status': newStatus}).eq('id', photoId);
      return true;
    } catch (e) {
      print('⚠️ updatePhotoStatus failed: $e');
      return false;
    }
  }

  /// Deletes both the Storage file and the metadata row for [photo].
  Future<bool> deletePhoto(Photo photo) async {
    try {
      final fileName = photo.url.split('/').last;
      final storagePath = '${photo.userId}/$fileName';

      // 1️⃣ Remove from Storage
      await _db.storage.from('photos').remove([storagePath]);

      // 2️⃣ Remove metadata row
      await _db.from('photos').delete().eq('id', photo.id);
      return true;
    } catch (e) {
      print('🚨 deletePhoto failed: $e');
      return false;
    }
  }

  /// Toggles a vote for the current user on [photoId].
  /// Returns the updated vote count, or null on error.
  Future<int?> toggleVote(String photoId) async {
    try {
      final result = await _db.rpc(
        'toggle_vote',
        params: {'photo_uuid': photoId},
      );
      // The RPC returns an integer
      return result is int ? result : (result as num).toInt();
    } catch (e) {
      print('🚨 toggleVote failed: $e');
      return null;
    }
  }
}
