import 'package:flutter/material.dart';
import '../widgets/background.dart';
import '../models/photo_model.dart';
import '../services/photo_service.dart';

class PublicGallery extends StatefulWidget {
  const PublicGallery({Key? key}) : super(key: key);

  @override
  State<PublicGallery> createState() => _PublicGalleryState();
}

class _PublicGalleryState extends State<PublicGallery> {
  final PhotoService _svc = PhotoService();
  List<Photo> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _photos = await _svc.fetchApprovedPhotos();
    } catch (_) {
      _photos = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(int i) async {
    final p = _photos[i];
    final cnt = await _svc.toggleVote(p.id);
    if (cnt != null) {
      setState(() => _photos[i] = p.copyWith(votes: cnt));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al votar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Galería Pública')),
      body: Background(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _photos.isEmpty
                ? Center(
                    child: Text(
                      'No hay fotos aprobadas.',
                      style: t.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _photos.length,
                    itemBuilder: (ctx, i) {
                      final p = _photos[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                p.url,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: Icon(Icons.broken_image)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Votos: ${p.votes}',
                                      style: t.textTheme.bodyMedium),
                                  IconButton(
                                    icon: const Icon(Icons.thumb_up),
                                    onPressed: () => _toggle(i),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
