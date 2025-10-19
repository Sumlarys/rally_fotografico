import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://hnunevlnlgeochunbuba.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhudW5ldmxubGdlb2NodW5idWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxNDY2NjcsImV4cCI6MjA2NDcyMjY2N30.KiuPY7JR2PUNy75OsTQSitRS07j0sXo-yc2YODJO3-4',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Construyendo MyApp');
    return MaterialApp(
      title: 'Rally Fotográfico',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6A1B9A), 
          secondary: Color(0xFFAB47BC), 
          surface: Color(0xFFF3E5F5), 
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF4A148C), 
        ),
        scaffoldBackgroundColor: Colors.transparent, // Fondo transparente para mostrar la imagen
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAB47BC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C),
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: Color(0xFF4A148C),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          color: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}