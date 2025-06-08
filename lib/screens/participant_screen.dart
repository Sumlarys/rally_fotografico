import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class ParticipantScreen extends StatefulWidget {
  const ParticipantScreen({super.key});

  @override
  _ParticipantScreenState createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen> {
  final _picker = ImagePicker();

  Future<void> _uploadPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileName = '${const Uuid().v4()}.jpg';

      try {
        print('Intentando subir foto al bucket rallyphotos con nombre: $fileName');
        await Supabase.instance.client.storage
            .from('rallyphotos')
            .upload(fileName, file)
            .timeout(const Duration(seconds: 10));
        print('Foto subida exitosamente al bucket rallyphotos');

        print('Obteniendo URL pública de la foto');
        final photoUrl = Supabase.instance.client.storage.from('rallyphotos').getPublicUrl(fileName);
        print('URL pública obtenida: $photoUrl');

        print('Insertando registro en la tabla photos con user_id: $userId, status: pending');
        await Supabase.instance.client.from('photos').insert({
          'user_id': userId,
          'url': photoUrl,
          'status': 'pending',
        }).timeout(const Duration(seconds: 10));
        print('Registro insertado exitosamente en la tabla photos');

        // Refrescar la UI después de subir la foto
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto subida con éxito. Espera a que un administrador la apruebe.')),
        );
      } on StorageException catch (e) {
        print('Error al subir la foto al bucket: ${e.message}, status code: ${e.statusCode}');
        String errorMessage = 'Error al subir la foto: ${e.message}';
        if (e.statusCode == 404) {
          errorMessage = 'El bucket "rallyphotos" no existe. Verifica la configuración en Supabase.';
        } else if (e.statusCode == 403) {
          errorMessage = 'No tienes permisos para subir fotos al bucket "rallyphotos". Verifica las políticas de acceso en Supabase.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } on PostgrestException catch (e) {
        print('Error al insertar en la tabla photos: ${e.message}, details: ${e.details}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la foto en la base de datos: ${e.message}')),
        );
      } catch (e) {
        print('Error inesperado al subir la foto: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado al subir la foto: $e')),
        );
      }
    }
  }

  Future<bool> _hasVoted(String photoId) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final vote = await Supabase.instance.client
        .from('votes')
        .select()
        .eq('photo_id', photoId)
        .eq('user_id', userId)
        .maybeSingle();
    return vote != null;
  }

  Future<void> _voteForPhoto(String photoId) async {
    if (await _hasVoted(photoId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya has votado por esta foto.')),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser!.id;
    try {
      await Supabase.instance.client.from('votes').insert({
        'photo_id': photoId,
        'user_id': userId,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voto registrado con éxito.')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al votar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Participante')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _uploadPhoto,
              child: const Text('Subir Foto'),
            ),
            const SizedBox(height: 20),
            const Text('Galería de Fotos Aprobadas'),
            SizedBox(
              height: 300,
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
                        trailing: IconButton(
                          icon: const Icon(Icons.thumb_up),
                          onPressed: () => _voteForPhoto(photo['id']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('Ranking de Fotos'),
            SizedBox(
              height: 300,
              child: FutureBuilder(
                future: Supabase.instance.client
                    .from('photos')
                    .select('*, votes(count)')
                    .eq('status', 'approved')
                    .order('votes.count', ascending: false),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final photos = snapshot.data as List<dynamic>;
                  if (photos.isEmpty) {
                    return const Center(child: Text('No hay fotos aprobadas para el ranking.'));
                  }
                  return ListView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final votes = photo['votes'] != null ? photo['votes'][0]['count'] : 0;
                      return ListTile(
                        title: Text('Puesto ${index + 1}: Foto - Votos: $votes'),
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