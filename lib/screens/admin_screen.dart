import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../services/photo_service.dart';
import '../widgets/background.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _photoService = PhotoService();
  List<Photo> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final list = await _photoService.fetchPendingPhotos();
    setState(() {
      _pending = list;
      _loading = false;
    });
  }

  Future<void> _handle(String id, String status) async {
    final ok = await _photoService.updatePhotoStatus(id, status);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo $status')),
      );
      await _loadPending();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Pending Photos')),
      body: Background(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _pending.isEmpty
                ? Center(
                    child: Text(
                      'No pending photos',
                      style: t.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _pending.length,
                    itemBuilder: (ctx, i) {
                      final photo = _pending[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Image.network(photo.url, height: 200, fit: BoxFit.cover),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _handle(photo.id, 'rejected'),
                                    child: const Text('Reject', style: TextStyle(color: Colors.red)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _handle(photo.id, 'approved'),
                                    child: const Text('Approve'),
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
    );
  }
}
