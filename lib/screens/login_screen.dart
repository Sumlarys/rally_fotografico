// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:rally_app/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reset_password_screen.dart';
import '../background_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isRegistering = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio.';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un email válido (ej: ejemplo@rallyfoto.com).';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (!RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#$%^&*]).*$').hasMatch(value)) {
      return 'Debe contener una mayúscula, una minúscula, un número y un carácter especial.';
    }
    if (value.contains(' ')) {
      return 'La contraseña no debe contener espacios.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Debes repetir la contraseña.';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  Future<bool> _checkIfEmailExists(String email) async {
    try {
      // Usamos una consulta a la tabla 'users' para verificar si el email existe
      final response = await Supabase.instance.client
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      return response != null;
    } catch (e) {
      print('Error al verificar si el email existe: $e');
      return false;
    }
  }

  Future<void> _handleAuth() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      if (_isRegistering) {
        _confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);
      }
    });

    if (_emailError != null || _passwordError != null || (_isRegistering && _confirmPasswordError != null)) {
      return;
    }

    try {
      // Normalizar el email a minúsculas
      final email = _emailController.text.trim().toLowerCase();

      if (_isRegistering) {
        // Registro
        try {
          print('Intentando registrar con email: $email');
          final response = await Supabase.instance.client.auth.signUp(
            email: email,
            password: _passwordController.text,
            data: {'email': email},
          ).timeout(const Duration(seconds: 10));

          if (response.user != null) {
            print('Usuario registrado exitosamente en Supabase Auth: ${response.user!.id}');
            // Insertar usuario en la tabla 'users'
            try {
              await Supabase.instance.client.from('users').insert({
                'id': response.user!.id,
                'email': email,
                'role': 'participant',
              }).timeout(const Duration(seconds: 10));
              print('Usuario insertado en la tabla users con ID: ${response.user!.id}');
            } catch (e) {
              print('Error al insertar usuario en la tabla users: $e');
              // Si falla la inserción en la tabla users, eliminar el usuario de auth para evitar inconsistencias
              await Supabase.instance.client.auth.admin.deleteUser(response.user!.id);
              print('Usuario eliminado de auth debido a error en la tabla users');
              setState(() {
                _emailError = 'Error al registrar el usuario en la base de datos: $e';
                _passwordError = null;
                _confirmPasswordError = null;
              });
              return;
            }

            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            setState(() {
              _isRegistering = false;
              _emailError = null;
              _passwordError = null;
              _confirmPasswordError = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registro exitoso. Por favor, confirma tu email antes de iniciar sesión. Revisa tu correo o los logs de Supabase.')),
            );
          } else {
            throw Exception('No se pudo registrar el usuario. Verifica tu conexión o intenta de nuevo.');
          }
        } on AuthException catch (e) {
          print('Error de registro: ${e.message}');
          if (e.message.contains('already registered')) {
            setState(() {
              _emailError = 'Este email ya está registrado. Intenta iniciar sesión o usa otro email.';
              _passwordError = null;
              _confirmPasswordError = null;
            });
          } else {
            setState(() {
              _emailError = 'Error de registro: ${e.message}';
              _passwordError = null;
              _confirmPasswordError = null;
            });
          }
        }
      } else {
        // Inicio de sesión
        try {
          print('Verificando si el email existe: $email');
          final emailExists = await _checkIfEmailExists(email);
          print('Email existe: $emailExists');

          if (!emailExists) {
            setState(() {
              _emailError = 'Este email no está registrado. Regístrate primero.';
              _passwordError = null;
            });
            return;
          }

          print('Intentando iniciar sesión con email: $email');
          final response = await Supabase.instance.client.auth.signInWithPassword(
            email: email,
            password: _passwordController.text,
          ).timeout(const Duration(seconds: 10));

          if (response.user == null) {
            print('Inicio de sesión fallido: usuario no encontrado o contraseña incorrecta');
            setState(() {
              _emailError = null;
              _passwordError = 'Contraseña incorrecta. ¿Olvidaste tu contraseña?';
            });
            return;
          }

          print('Usuario encontrado: ${response.user!.id}, confirmado: ${response.user!.confirmedAt}');
          if (!response.user!.confirmedAt.toString().isNotEmpty) {
            print('Email no confirmado');
            setState(() {
              _emailError = 'Por favor, confirma tu email antes de iniciar sesión. Revisa tu correo o los logs de Supabase.';
              _passwordError = null;
            });
            return;
          }

          print('Inicio de sesión exitoso');
          _emailController.clear();
          _passwordController.clear();
          setState(() {
            _emailError = null;
            _passwordError = null;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } on AuthException catch (e) {
          print('Error de inicio de sesión: ${e.message}');
          if (e.message.contains('Invalid login credentials')) {
            setState(() {
              _emailError = null;
              _passwordError = 'Contraseña incorrecta. ¿Olvidaste tu contraseña?';
            });
          } else if (e.message.contains('Email not confirmed')) {
            setState(() {
              _emailError = 'Por favor, confirma tu email antes de iniciar sesión. Revisa tu correo o los logs de Supabase.';
              _passwordError = null;
            });
          } else {
            setState(() {
              _emailError = 'Error de inicio de sesión: ${e.message}';
              _passwordError = null;
            });
          }
        }
      }
    } catch (e) {
      print('Error inesperado: $e');
      setState(() {
        _emailError = 'Error inesperado: $e';
        _passwordError = 'Error inesperado: $e';
        _confirmPasswordError = null;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Construyendo LoginScreen');
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Aseguramos que el Scaffold sea transparente
        appBar: AppBar(
          title: Text(
            'Iniciar Sesión / Registrarse',
            style: GoogleFonts.pacifico(
              fontSize: 28,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Center( // Centra todos los componentes verticalmente
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centra los elementos dentro del Column
                children: [
                  TextField(
                    controller: _emailController,
                    onChanged: (value) => setState(() {
                      _emailError = _validateEmail(value);
                    }),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'ejemplo@rallyfoto.com', // Hint actualizado
                      errorText: _emailError,
                      hintStyle: GoogleFonts.lato(
                        fontSize: 16,
                        color: const Color(0xFFAB47BC), // Morado claro
                      ),
                      labelStyle: GoogleFonts.lato(
                        fontSize: 16,
                        color: const Color(0xFFAB47BC), // Morado claro
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: _passwordController,
                    onChanged: (value) => setState(() {
                      _emailError = null; // Limpiar error de email al cambiar la contraseña
                      _passwordError = _validatePassword(value);
                    }),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: 'Rally2025!', // Hint actualizado
                      errorText: _passwordError,
                      hintStyle: GoogleFonts.lato(
                        fontSize: 16,
                        color: const Color(0xFFAB47BC), // Morado claro
                      ),
                      labelStyle: GoogleFonts.lato(
                        fontSize: 16,
                        color: const Color(0xFFAB47BC), // Morado claro
                      ),
                    ),
                    obscureText: true,
                  ),
                  if (_isRegistering)
                    TextField(
                      controller: _confirmPasswordController,
                      onChanged: (value) => setState(() {
                        _confirmPasswordError = _validateConfirmPassword(value);
                      }),
                      decoration: InputDecoration(
                        labelText: 'Repetir Contraseña',
                        hintText: 'Rally2025!', // Hint actualizado
                        errorText: _confirmPasswordError,
                        hintStyle: GoogleFonts.lato(
                          fontSize: 16,
                          color: const Color(0xFFAB47BC), // Morado claro
                        ),
                        labelStyle: GoogleFonts.lato(
                          fontSize: 16,
                          color: const Color(0xFFAB47BC), // Morado claro
                        ),
                      ),
                      obscureText: true,
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleAuth,
                    child: Text(_isRegistering ? 'Registrarse' : 'Iniciar Sesión'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isRegistering = !_isRegistering),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFAB47BC), // Morado claro
                    ),
                    child: Text(
                      _isRegistering
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Regístrate',
                      style: GoogleFonts.lato(
                        fontSize: 18, // Tamaño más grande
                        fontWeight: FontWeight.bold, // Más destacado
                      ),
                    ),
                  ),
                  if (!_isRegistering)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFAB47BC), // Morado claro
                      ),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: GoogleFonts.lato(
                          fontSize: 18, // Tamaño más grande
                          fontWeight: FontWeight.bold, // Más destacado
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}