// lib/screens/gallery_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:proyecto_integrado/widgets/background.dart';
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
  List<Photo> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _photos = [];
        _loading = false;
      });
      return;
    }

    final boxName = 'photos_${user.id}';
    try {
      final fresh = await _photoService.fetchUserPhotos(user.id);
      final box = await Hive.openBox<Photo>(boxName);
      await box.clear();
      await box.addAll(fresh);
      _photos = fresh;
    } catch (_) {
      final box = await Hive.openBox<Photo>(boxName);
      _photos = box.values.toList();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deletePhoto(Photo photo) async {
    final ok = await _photoService.deletePhoto(photo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Foto eliminada' : 'Error al eliminar')),
    );
    if (ok) await _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Fotos')),
      body:
          Background(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _photos.isEmpty
                ? Center(
                  child: Text(
                    'No hay fotos subidas aún.',
                    style: t.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _photos.length,
                  itemBuilder: (ctx, i) {
                    final photo = _photos[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias, // smooth clipping
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Explicitly clip only the top corners of the image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              photo.url,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, prog) {
                                if (prog == null) return child;
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder:
                                  (ctx, _, __) => const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                            ),
                          ),
            
                          // Optional: show vote count or other info
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              'Votes: ${photo.votes}',
                              style: t.textTheme.bodyMedium,
                            ),
                          ),
            
                          // Delete button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deletePhoto(photo),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPhotos,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
