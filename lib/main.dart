import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NoveldaAhoraApp());

  _crearRecuerdosIniciales();
}

Future<void> _crearRecuerdosIniciales() async {
  try {
    debugPrint('>>> Creando recuerdos iniciales...');



    debugPrint(
      '<<< Recuerdos iniciales creados correctamente',
    );
  } catch (e, stackTrace) {
    debugPrint('!!! ERROR CREANDO RECUERDOS');
    debugPrint('!!! Error: $e');
    debugPrint('!!! StackTrace: $stackTrace');
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