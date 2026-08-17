import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/importador_noticias_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NoveldaAhoraApp());

  _iniciarImportacionNoticias();
}

Future<void> _iniciarImportacionNoticias() async {
  try {
    final importador = ImportadorNoticiasService();

    await importador.importarTodas();
  } catch (e) {
    // La importación se ejecuta en segundo plano para no bloquear
    // el arranque de la aplicación.
  }
}

class NoveldaAhoraApp extends StatelessWidget {
  const NoveldaAhoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Novelda Ahora',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F6D5A),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}