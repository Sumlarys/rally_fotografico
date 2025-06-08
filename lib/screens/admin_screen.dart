import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_management_screen.dart';
import 'pending_photos_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administrador')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                );
              },
              child: const Text('Gestionar Usuarios'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PendingPhotosScreen()),
                );
              },
              child: const Text('Revisar Fotos Pendientes'),
            ),
            const SizedBox(height: 20),
            const Text('Vista General de Fotos Aprobadas'),
            SizedBox(
              height: 500,
              child: FutureBuilder(
                future: Supabase.instance.client
                    .from('photos')
                    .select('*, votes(count)')
                    .eq('status', 'approved'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final photos = snapshot.data as List<dynamic>;
                  if (photos.isEmpty) {
                    return const Center(child: Text('No hay fotos aprobadas.'));
                  }
                  return ListView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final votes = photo['votes'] != null ? photo['votes'][0]['count'] : 0;
                      return ListTile(
                        title: Text('Foto ${index + 1} - Votos: $votes'),
                        subtitle: Image.network(
                          photo['url'],
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error al cargar la imagen: $error');
                            return const Icon(Icons.error);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}