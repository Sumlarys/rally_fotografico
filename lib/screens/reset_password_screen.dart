// lib/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../background_widget.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio.';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ingresa un email válido (ej: ejemplo@rallyfoto.com).';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
    });

    if (_emailError != null) {
      return;
    }

    try {
      final email = _emailController.text.trim().toLowerCase();
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se ha enviado un enlace para restablecer tu contraseña. Revisa tu correo.')),
      );
      _emailController.clear();
      setState(() {
        _emailError = null;
      });
    } catch (e) {
      setState(() {
        _emailError = 'Error: $e';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Construyendo ResetPasswordScreen');
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent, // Aseguramos que el Scaffold sea transparente
        appBar: AppBar(
          title: Text(
            'Restablecer Contraseña',
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
                  Text(
                    'Ingrese su email', // Texto actualizado
                    style: GoogleFonts.pacifico(
                      fontSize: 28, // Tamaño igual al del encabezado
                      color: const Color(0xFFAB47BC), // Morado claro
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    onChanged: (value) => setState(() {
                      _emailError = _validateEmail(value);
                    }),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'ejemplo@rallyfoto.com',
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text('Enviar Enlace de Restablecimiento'),
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