import 'package:flutter/material.dart';
import '../widgets/background.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar usuarios')),
      body: const Background(
        child: Center(
          child: Text(
            'Gestión de usuarios deshabilitada\nen modo personal.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
