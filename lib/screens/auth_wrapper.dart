import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null || session.user == null) {
      return const LoginScreen();
    }
    final user = session.user!;
    final role = user.email == 'projectren13@gmail.com'
        ? 'administrator'
        : 'participant';

    return HomeScreen(
      user: UserModel(
        id: user.id,
        email: user.email!,
        role: role,
      ),
    );
  }
}
