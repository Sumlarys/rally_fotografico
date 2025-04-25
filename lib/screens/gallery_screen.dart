import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/photo_model.dart';
import '../services/photo_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final PhotoService _photoService = PhotoService();
  late final String _userId;
  List<Photo> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _userId = user!.id;
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await _photoService.fetchUserPhotos(_userId);
    setState(() {
      _photos = photos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_photos.isEmpty) {
      return const Scaffold(body: Center(child: Text('No photos yet.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Photos')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return Card(child: Image.network(photo.url, fit: BoxFit.cover));
        },
      ),
    );
  }
}
