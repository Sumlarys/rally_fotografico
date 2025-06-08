import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import 'user_management_screen.dart';
import 'pending_photos_screen.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../background_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  int _voteActionCounter = 0; // Contador para forzar la reconstrucción del FutureBuilder
  int _photoActionCounter = 0; // Contador para forzar la reconstrucción al eliminar o aprobar fotos
  String? _userRole; // Guardar el rol del usuario

  Future<String?> _getUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (userData == null) {
        print('Usuario ${user.id} no encontrado en la tabla users, asignando rol por defecto: participant');
        return 'participant';
      }
      _userRole = userData['role'] as String?;
      return _userRole;
    } catch (e) {
      print('Error al obtener el rol del usuario: $e');
      return 'participant';
    }
  }

  Future<bool> _ensureUserExists(String userId, String email) async {
    try {
      print('Verificando si el usuario $userId existe en la tabla users');
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (userData == null) {
        print('Usuario $userId no encontrado en la tabla users, intentando crearlo');
        await Supabase.instance.client.from('users').insert({
          'id': userId,
          'email': email,
          'role': 'participant',
        }).timeout(const Duration(seconds: 10));
        print('Usuario $userId creado exitosamente en la tabla users');
        return true;
      }
      print('Usuario $userId ya existe en la tabla users');
      return true;
    } catch (e) {
      print('Error al verificar/crear usuario $userId: $e');
      return false;
    }
  }

  Future<void> _uploadPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      final user = Supabase.instance.client.auth.currentUser!;
      final userId = user.id;
      final email = user.email ?? 'unknown@example.com';
      final fileName = '${const Uuid().v4()}.jpg';

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

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

        // Verificar o crear el usuario antes de insertar la foto
        print('Verificando existencia del usuario $userId antes de insertar foto');
        try {
          final userExists = await _ensureUserExists(userId, email);
          if (!userExists) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: No se pudo verificar o crear tu cuenta. Intenta de nuevo.')),
            );
            Navigator.pop(context); // Cerrar el indicador de carga
            return;
          }
          print('Usuario $userId verificado o creado exitosamente');
        } catch (e) {
          print('Error al verificar/crear usuario $userId: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al verificar el usuario: $e. Intenta de nuevo.')),
          );
          Navigator.pop(context); // Cerrar el indicador de carga
          return;
        }

        print('Insertando registro en la tabla photos con user_id: $userId, status: pending');
        await Supabase.instance.client.from('photos').insert({
          'user_id': userId,
          'url': photoUrl,
          'status': 'pending',
        }).timeout(const Duration(seconds: 10));
        print('Registro insertado exitosamente en la tabla photos');

        // Refrescar la UI después de subir la foto
        if (mounted) {
          setState(() {});
        }

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
      } finally {
        Navigator.pop(context); // Cerrar el indicador de carga
      }
    }
  }

  Future<void> _deletePhoto(String photoId) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('Eliminando foto con ID $photoId');
      // Primero eliminar los votos asociados a la foto
      await Supabase.instance.client
          .from('votes')
          .delete()
          .eq('photo_id', photoId);
      // Luego eliminar la foto
      await Supabase.instance.client
          .from('photos')
          .delete()
          .eq('id', photoId);
      print('Foto eliminada exitosamente');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto eliminada con éxito.')),
      );
      // Incrementar el contador para forzar la reconstrucción del FutureBuilder
      if (mounted) {
        setState(() {
          _photoActionCounter++;
        });
      }
    } catch (e) {
      print('Error al eliminar la foto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la foto: $e')),
      );
    } finally {
      Navigator.pop(context); // Cerrar el indicador de carga
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
    print('Verificando si el usuario $userId votó por la foto $photoId: ${vote != null}');
    return vote != null;
  }

  Future<void> _voteForPhoto(String photoId, bool hasVoted) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final userEmail = Supabase.instance.client.auth.currentUser!.email ?? 'unknown@example.com';

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Verificar si el usuario existe en la tabla users
    print('Verificando existencia del usuario $userId antes de votar');
    try {
      final userExists = await _ensureUserExists(userId, userEmail);
      if (!userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo verificar tu cuenta. Por favor, intenta de nuevo más tarde.')),
        );
        Navigator.pop(context); // Cerrar el indicador de carga
        return;
      }
      print('Usuario $userId verificado o creado exitosamente para votar');
    } catch (e) {
      print('Error al verificar/crear usuario $userId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al verificar el usuario: $e. Intenta de nuevo.')),
      );
      Navigator.pop(context); // Cerrar el indicador de carga
      return;
    }

    try {
      if (hasVoted) {
        // Quitar el voto
        print('Eliminando voto del usuario $userId para la foto $photoId');
        final response = await Supabase.instance.client
            .from('votes')
            .delete()
            .eq('photo_id', photoId)
            .eq('user_id', userId);
        print('Respuesta de eliminación: $response');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voto eliminado con éxito.')),
        );
      } else {
        // Añadir el voto
        print('Añadiendo voto del usuario $userId para la foto $photoId');
        final response = await Supabase.instance.client.from('votes').insert({
          'photo_id': photoId,
          'user_id': userId,
        });
        print('Respuesta de inserción: $response');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voto registrado con éxito.')),
        );
      }
      // Incrementar el contador para forzar la reconstrucción del FutureBuilder
      if (mounted) {
        setState(() {
          _voteActionCounter++;
        });
      }
    } catch (e) {
      print('Error al votar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al votar: $e')),
      );
    } finally {
      Navigator.pop(context); // Cerrar el indicador de carga
    }
  }

  void _onPhotoApproved() {
    print('Callback _onPhotoApproved ejecutado');
    // Incrementar el contador para forzar la reconstrucción del FutureBuilder
    if (mounted) {
      setState(() {
        _photoActionCounter++;
      });
    }
  }

  Widget _buildPhotoCard(dynamic photo, {required bool showVoteButton}) {
    final votes = photo['votes_count'] != null ? photo['votes_count'] : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Stack(
          children: [
            Column(
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
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$votes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (showVoteButton)
                        FutureBuilder<bool>(
                          future: _hasVoted(photo['id']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox.shrink();
                            final hasVoted = snapshot.data!;
                            return IconButton(
                              icon: Icon(
                                hasVoted ? Icons.favorite : Icons.favorite_border,
                                color: hasVoted ? Colors.red : Colors.grey,
                                size: 24,
                              ),
                              onPressed: () => _voteForPhoto(photo['id'], hasVoted),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Icono de papelera para administradores
            if (_userRole == 'admin')
              Positioned(
                bottom: 8.0,
                left: 8.0,
                child: IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () => _deletePhoto(photo['id']),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantPanel() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _uploadPhoto,
              child: const Text('Subir Foto'),
            ),
          ),
        ),
        FutureBuilder(
          key: ValueKey(_photoActionCounter),
          future: Supabase.instance.client
              .from('photos')
              .select('id, url, status')
              .eq('status', 'approved'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              print('Error al cargar las fotos aprobadas: ${snapshot.error}');
              return SliverToBoxAdapter(
                child: Center(child: Text('Error al cargar las fotos: ${snapshot.error}')),
              );
            }
            if (!snapshot.hasData) {
              print('No hay datos disponibles para las fotos aprobadas.');
              return const SliverToBoxAdapter(
                child: Center(child: Text('No hay datos disponibles.')),
              );
            }
            final photos = snapshot.data as List<dynamic>;
            if (photos.isEmpty) {
              print('No hay fotos aprobadas en la base de datos.');
              return const SliverToBoxAdapter(
                child: Center(child: Text('No hay fotos aprobadas.')),
              );
            }

            // Obtener el conteo de votos para cada foto
            return FutureBuilder(
              key: ValueKey('$_voteActionCounter-$_photoActionCounter'),
              future: Future.wait(
                photos.map((photo) async {
                  final votes = await Supabase.instance.client
                      .from('votes')
                      .select('id')
                      .eq('photo_id', photo['id'])
                      .count();
                  print('Conteo de votos para la foto ${photo['id']}: ${votes.count}');
                  return {
                    ...photo,
                    'votes_count': votes.count,
                  };
                }),
              ),
              builder: (context, voteSnapshot) {
                if (voteSnapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (voteSnapshot.hasError) {
                  print('Error al contar los votos: ${voteSnapshot.error}');
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Error al contar los votos: ${voteSnapshot.error}')),
                  );
                }
                final photosWithVotes = voteSnapshot.data as List<dynamic>;
                // Ordenar manualmente por conteo de votos (descendente)
                photosWithVotes.sort((a, b) => (b['votes_count'] as int).compareTo(a['votes_count'] as int));
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final photo = photosWithVotes[index];
                      return _buildPhotoCard(photo, showVoteButton: true);
                    },
                    childCount: photosWithVotes.length,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminPanel() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    print('Navegando a PendingPhotosScreen desde HomeScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PendingPhotosScreen(
                          onPhotoApproved: _onPhotoApproved,
                        ),
                      ),
                    ).then((_) {
                      print('Regresando a HomeScreen desde PendingPhotosScreen');
                    });
                  },
                  child: const Text('Revisar Fotos Pendientes'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                    );
                  },
                  child: const Text('Gestionar Usuarios'),
                ),
              ],
            ),
          ),
        ),
        FutureBuilder(
          key: ValueKey(_photoActionCounter),
          future: Supabase.instance.client
              .from('photos')
              .select('id, url, status')
              .eq('status', 'approved'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              print('Error al cargar las fotos aprobadas: ${snapshot.error}');
              return SliverToBoxAdapter(
                child: Center(child: Text('Error al cargar las fotos: ${snapshot.error}')),
              );
            }
            if (!snapshot.hasData) {
              print('No hay datos disponibles para las fotos aprobadas.');
              return const SliverToBoxAdapter(
                child: Center(child: Text('No hay datos disponibles.')),
              );
            }
            final photos = snapshot.data as List<dynamic>;
            if (photos.isEmpty) {
              print('No hay fotos aprobadas en la base de datos.');
              return const SliverToBoxAdapter(
                child: Center(child: Text('No hay fotos aprobadas.')),
              );
            }

            // Obtener el conteo de votos para cada foto
            return FutureBuilder(
              key: ValueKey('$_voteActionCounter-$_photoActionCounter'),
              future: Future.wait(
                photos.map((photo) async {
                  final votes = await Supabase.instance.client
                      .from('votes')
                      .select('id')
                      .eq('photo_id', photo['id'])
                      .count();
                  print('Conteo de votos para la foto ${photo['id']}: ${votes.count}');
                  return {
                    ...photo,
                    'votes_count': votes.count,
                  };
                }),
              ),
              builder: (context, voteSnapshot) {
                if (voteSnapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (voteSnapshot.hasError) {
                  print('Error al contar los votos: ${voteSnapshot.error}');
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Error al contar los votos: ${voteSnapshot.error}')),
                  );
                }
                final photosWithVotes = voteSnapshot.data as List<dynamic>;
                // Ordenar manualmente por conteo de votos (descendente)
                photosWithVotes.sort((a, b) => (b['votes_count'] as int).compareTo(a['votes_count'] as int));
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final photo = photosWithVotes[index];
                      return _buildPhotoCard(photo, showVoteButton: true);
                    },
                    childCount: photosWithVotes.length,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return BackgroundWidget(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Rally Fotográfico',
            style: GoogleFonts.pacifico(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: user != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      setState(() {});
                    },
                    color: Colors.white,
                  ),
                ]
              : null,
        ),
        body: user == null
            ? Stack(
                children: [
                  // Título cerca de la parte superior
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Bienvenido al Rally Fotográfico',
                      style: GoogleFonts.pacifico(
                        fontSize: 36,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Botón centrado verticalmente
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Iniciar Sesión / Registrarse'),
                    ),
                  ),
                ],
              )
            : FutureBuilder<String?>(
                future: _getUserRole(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final userRole = snapshot.data ?? 'participant';
                  return userRole == 'admin'
                      ? _buildAdminPanel()
                      : _buildParticipantPanel();
                },
              ),
      ),
    );
  }
}