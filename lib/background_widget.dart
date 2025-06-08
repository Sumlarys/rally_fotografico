import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;

  const BackgroundWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    print('Intentando cargar la imagen de fondo desde assets/image.png');
    return Container(
      decoration: const BoxDecoration(
        color: Colors.blueGrey, // Color de respaldo para depuración
        image: DecorationImage(
          image: AssetImage('assets/image.png'),
          fit: BoxFit.cover, // Cubre toda la pantalla
          onError: _onImageLoadError, // Callback para depuración
        ),
      ),
      child: Container(
        // Overlay semi-transparente para mejorar la legibilidad
        color: Colors.black.withOpacity(0.1), 
        child: child,
      ),
    );
  }

  static void _onImageLoadError(Object error, StackTrace? stackTrace) {
    print('Error al cargar la imagen de fondo: $error, stackTrace: $stackTrace');
  }
}