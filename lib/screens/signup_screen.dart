import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/background.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'auth_wrapper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false, _valid = false;
  String? _error;

  void _check() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (ok != _valid) setState(() => _valid = ok);
  }

  Future<void> _submit() async {
    if (!_valid) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AuthService()
          .signUp(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (res.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      } else {
        setState(() => _error = 'Registro fallido');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error inesperado');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_check);
    _passCtrl.addListener(_check);
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_check);
    _passCtrl.removeListener(_check);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Background(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Regístrate',
                  textAlign: TextAlign.center,
                  style: t.textTheme.titleLarge?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: t.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(children: [
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v != null && v.contains('@') ? null : 'Email inválido',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'Mín. 6 caracteres',
                    ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(color: t.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    CustomButton(
                      label: 'Crear Cuenta',
                      loading: _loading,
                      onPressed:
                          (_valid && !_loading) ? () => _submit() : null,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('¿Ya tienes cuenta? Inicia Sesión'),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
