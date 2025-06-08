import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../background_widget.dart';

class PendingPhotosScreen extends StatefulWidget {
  final VoidCallback? onPhotoApproved; // Hacer el callback opcional

  const PendingPhotosScreen({super.key, this.onPhotoApproved});

  @override
  _PendingPhotosScreenState createState() => _PendingPhotosScreenState();
}

class _PendingPhotosScreenState extends State<PendingPhotosScreen> {
  Future<void> _updatePhotoStatus(String photoId, String status) async {
    try {
      print('Actualizando estado de la foto con ID $photoId a $status');
      await Supabase.instance.client
          .from('photos')
          .update({'status': status})
          .eq('id', photoId)
          .timeout(const Duration(seconds: 10));
      print('Estado actualizado exitosamente');
      // Notificar a HomeScreen si se aprobó una foto
      if (status == 'approved' && widget.onPhotoApproved != null) {
        print('Ejecutando onPhotoApproved desde PendingPhotosScreen');
        widget.onPhotoApproved!();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error al actualizar el estado de la foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el estado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Construyendo PendingPhotosScreen');
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Aseguramos que el Scaffold sea transparente
        appBar: AppBar(
          title: Text(
            'Fotos Pendientes',
            style: GoogleFonts.pacifico(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: CustomScrollView(
          slivers: [
            FutureBuilder(
              future: Supabase.instance.client
                  .from('photos')
                  .select()
                  .eq('status', 'pending'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  print('Error al cargar las fotos pendientes: ${snapshot.error}');
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Error al cargar las fotos: ${snapshot.error}')),
                  );
                }
                if (!snapshot.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text('No hay datos disponibles.')),
                  );
                }
                final photos = snapshot.data as List<dynamic>;
                if (photos.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Text('No hay fotos pendientes de aprobación.')),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final photo = photos[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                                child: Image.network(
                                  photo['url'],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error al cargar la imagen: $error');
                                    return Container(
                                      height: 180,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error, color: Colors.red, size: 50),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _updatePhotoStatus(photo['id'], 'approved'),
                                      icon: const Icon(Icons.check, color: Colors.white),
                                      label: const Text('Aprobar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _updatePhotoStatus(photo['id'], 'rejected'),
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      label: const Text('Rechazar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: photos.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}