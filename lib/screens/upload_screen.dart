import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _picker = ImagePicker();
  final _photoService = PhotoService();
  bool _loading = false;
  String _message = '';

  Future<void> _pickAndUpload() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _loading = true;
      _message = '';
    });

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _message = 'Not logged in';
        _loading = false;
      });
      return;
    }

    final file = File(picked.path);
    final url = await _photoService.uploadPhoto(file, user.id);

    setState(() {
      _loading = false;
      _message = url != null ? 'Upload successful!' : 'Upload failed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Photo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_loading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _pickAndUpload,
                child: const Text('Pick & Upload Photo'),
              ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('failed') ? Colors.red : Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
