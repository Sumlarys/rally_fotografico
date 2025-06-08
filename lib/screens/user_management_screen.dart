// lib/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../background_widget.dart';

// Configuración del token de servicio (reemplaza con tu Service Role Key)
const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhudW5ldmxubGdlb2NodW5idWJhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0OTE0NjY2NywiZXhwIjoyMDY0NzIyNjY3fQ.-rJG-7GBdvLr0ek04N-4UFuZWyIpWCqMuIl4trfJls8'; // ¡No comentes esto en producción!
const String supabaseUrl = 'https://hnunevlnlgeochunbuba.supabase.co'; // URL de tu proyecto Supabase

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  Future<void> _updateUserRole(String userId, bool isAdmin) async {
    try {
      print('Actualizando rol del usuario $userId a ${isAdmin ? 'admin' : 'participant'}');
      await Supabase.instance.client
          .from('users')
          .update({'role': isAdmin ? 'admin' : 'participant'})
          .eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol actualizado con éxito: ${isAdmin ? 'Administrador' : 'Participante'}')),
      );
      setState(() {});
    } catch (e) {
      print('Error al actualizar el rol del usuario $userId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el rol: $e')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      print('Iniciando eliminación del usuario con ID: $userId');

      // Verificar el rol del usuario autenticado
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No hay un usuario autenticado para realizar esta operación.');
      }
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', currentUserId)
          .maybeSingle();
      if (userData == null || userData['role'] != 'admin') {
        throw Exception('El usuario autenticado no tiene permisos de administrador.');
      }
      print('Usuario autenticado verificado como administrador: $currentUserId');

      // Paso 1: Obtener las fotos del usuario
      print('Obteniendo fotos del usuario $userId para eliminar votos asociados');
      final photos = await Supabase.instance.client
          .from('photos')
          .select('id')
          .eq('user_id', userId);
      final photoIds = photos.map((photo) => photo['id']).toList();
      print('Fotos encontradas para el usuario $userId: ${photoIds.length} (${photoIds.join(', ')})');

      // Paso 2: Eliminar votos asociados a las fotos del usuario
      if (photoIds.isNotEmpty) {
        print('Eliminando votos asociados a las fotos del usuario $userId');
        try {
          final votesForPhotos = await Supabase.instance.client
              .from('votes')
              .select('id')
              .inFilter('photo_id', photoIds);
          print('Votos encontrados asociados a las fotos del usuario $userId: ${votesForPhotos.length} (${votesForPhotos.map((vote) => vote['id']).join(', ')})');

          int maxAttempts = 3;
          int attempts = 0;
          while (attempts < maxAttempts) {
            await Supabase.instance.client
                .from('votes')
                .delete()
                .inFilter('photo_id', photoIds);
            attempts++;
            final remainingVotesForPhotos = await Supabase.instance.client
                .from('votes')
                .select('id')
                .inFilter('photo_id', photoIds);
            if (remainingVotesForPhotos.isEmpty) {
              break;
            }
            print('Votos residuales asociados a las fotos después del intento $attempts: ${remainingVotesForPhotos.length} (${remainingVotesForPhotos.map((vote) => vote['id']).join(', ')})');
          }

          final remainingVotesForPhotos = await Supabase.instance.client
              .from('votes')
              .select('id')
              .inFilter('photo_id', photoIds);
          if (remainingVotesForPhotos.isNotEmpty) {
            print('Votos residuales asociados a las fotos después de la eliminación: ${remainingVotesForPhotos.length} (${remainingVotesForPhotos.map((vote) => vote['id']).join(', ')})');
            throw Exception('No se pudieron eliminar todos los votos asociados a las fotos. Votos residuales: ${remainingVotesForPhotos.length}');
          }
          print('No quedan votos asociados a las fotos del usuario $userId');
        } catch (e) {
          print('Error al eliminar votos asociados a las fotos del usuario $userId: $e');
          throw Exception('Error al eliminar los votos asociados a las fotos: $e');
        }
      } else {
        print('No se encontraron fotos para eliminar votos asociados');
      }

      // Paso 3: Eliminar votos dados por el usuario
      print('Obteniendo votos dados por el usuario $userId');
      final votes = await Supabase.instance.client
          .from('votes')
          .select('id, user_id, photo_id')
          .eq('user_id', userId);
      print('Votos encontrados para el usuario $userId: ${votes.length} (${votes.map((vote) => 'id: ${vote['id']}, user_id: ${vote['user_id']}, photo_id: ${vote['photo_id']}').join(', ')})');

      if (votes.isNotEmpty) {
        print('Eliminando votos dados por el usuario $userId');
        try {
          int maxAttempts = 3;
          int attempts = 0;
          while (attempts < maxAttempts) {
            await Supabase.instance.client
                .from('votes')
                .delete()
                .eq('user_id', userId);
            attempts++;
            final remainingVotes = await Supabase.instance.client
                .from('votes')
                .select('id')
                .eq('user_id', userId);
            if (remainingVotes.isEmpty) {
              break;
            }
            print('Votos residuales después del intento $attempts: ${remainingVotes.length} (${remainingVotes.map((vote) => vote['id']).join(', ')})');
          }

          final remainingVotes = await Supabase.instance.client
              .from('votes')
              .select('id, user_id, photo_id')
              .eq('user_id', userId);
          if (remainingVotes.isNotEmpty) {
            print('Votos residuales encontrados después de la eliminación: ${remainingVotes.length} (${remainingVotes.map((vote) => 'id: ${vote['id']}, user_id: ${vote['user_id']}, photo_id: ${vote['photo_id']}').join(', ')})');
            throw Exception('No se pudieron eliminar todos los votos asociados al usuario. Votos residuales: ${remainingVotes.length}');
          }
          print('No quedan votos asociados al usuario $userId');
        } catch (e) {
          print('Error al eliminar votos dados por el usuario $userId: $e');
          throw Exception('Error al eliminar los votos dados por el usuario: $e');
        }
      } else {
        print('No se encontraron votos dados por el usuario $userId');
      }

      // Paso 4: Eliminar fotos asociadas al usuario
      print('Eliminando fotos del usuario $userId');
      try {
        await Supabase.instance.client
            .from('photos')
            .delete()
            .eq('user_id', userId);
        print('Fotos eliminadas exitosamente');
      } catch (e) {
        print('Error al eliminar fotos del usuario $userId: $e');
        throw Exception('Error al eliminar las fotos asociadas: $e');
      }

      // Paso 5: Eliminar el registro del usuario en la tabla users
      print('Eliminando registro del usuario $userId de la tabla users');
      try {
        await Supabase.instance.client
            .from('users')
            .delete()
            .eq('id', userId);
        print('Usuario eliminado exitosamente de la tabla users');
      } catch (e) {
        print('Error al eliminar el registro del usuario $userId de la tabla users: $e');
        throw Exception('Error al eliminar el usuario de la tabla users: $e');
      }

      // Paso 6: Eliminar el usuario de auth.users usando la API de administración
      print('Eliminando usuario $userId de auth.users');
      try {
        final supabaseAdmin = SupabaseClient(
          supabaseUrl,
          serviceRoleKey,
        );
        await supabaseAdmin.auth.admin.deleteUser(userId);
        print('Usuario $userId eliminado exitosamente de auth.users');
      } catch (e) {
        print('Error al eliminar el usuario $userId de auth.users: $e');
        throw Exception('Error al eliminar el usuario de auth.users: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado completamente de la base de datos y autenticación.'),
        ),
      );

      setState(() {});
    } catch (e) {
      print('Error al eliminar el usuario $userId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el usuario: $e')),
      );
    } finally {
      Navigator.pop(context); // Cerrar el indicador de carga
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Construyendo UserManagementScreen');
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Aseguramos que el Scaffold sea transparente
        appBar: AppBar(
          title: Text(
            'Gestión de Usuarios',
            style: GoogleFonts.pacifico(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Center( // Centra el contenido verticalmente
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Lista de Usuarios',
                  style: GoogleFonts.pacifico(
                    fontSize: 28,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder(
                  future: Supabase.instance.client.from('users').select(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final users = snapshot.data as List<dynamic>;
                    if (users.isEmpty) {
                      return const Center(child: Text('No hay usuarios registrados.'));
                    }
                    return ListView.builder(
                      shrinkWrap: true, // Permite que el ListView se ajuste dentro del Column
                      physics: const NeverScrollableScrollPhysics(), // Desactiva el scroll propio
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isAdmin = user['role'] == 'admin';
                        return Card(
                          elevation: 4.0,
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user['email'],
                                        style: GoogleFonts.lato(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF6A1B9A), // Morado oscuro
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rol: ${user['role']}',
                                        style: GoogleFonts.lato(
                                          fontSize: 16,
                                          color: const Color(0xFFAB47BC), // Lila
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Switch(
                                      value: isAdmin,
                                      onChanged: (value) => _updateUserRole(user['id'], value),
                                      activeColor: const Color(0xFFAB47BC), // Lila
                                      inactiveThumbColor: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteUser(user['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}