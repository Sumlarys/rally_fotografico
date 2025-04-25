import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/photo_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final PhotoService _photoService = PhotoService();
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final file = File(picked.path);
    final url = await _photoService.uploadPhoto(file, user.id);
    setState(() => _uploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(url != null ? 'Upload successful' : 'Upload failed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Photo')),
      body: Center(
        child: _uploading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _pickAndUpload,
                child: const Text('Pick & Upload'),
              ),
      ),
    );
  }
}
