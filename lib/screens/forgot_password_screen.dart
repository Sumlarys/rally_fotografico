// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:proyecto_integrado/widgets/background.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _message;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _message = null; });
    final ok = await AuthService().resetPassword(_emailCtrl.text.trim());
    setState(() {
      _loading = false;
      _message = ok
        ? 'Revisa tu correo para restablecer contraseña.'
        : 'Error al enviar el email.';
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Olvidé mi contraseña')),
      body: Background(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Introduce tu email para recibir el enlace de restablecimiento.',
                style: t.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) =>
                    v != null && v.contains('@') ? null : 'Email inválido',
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Enviar enlace',
                loading: _loading,
                onPressed: _submit,
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.startsWith('Revisa')
                      ? Colors.green
                      : t.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
