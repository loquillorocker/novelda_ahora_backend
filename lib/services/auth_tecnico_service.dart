import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthTecnicoService {
  static const String _email = 'sirventmartinez@gmail.com';
  static const String _password = 'Joseluis1978';

  static Future<User?> iniciarSesion() async {
    try {
      final credencial =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      debugPrint(
        'USUARIO FIREBASE: ${credencial.user?.uid}',
      );

      return credencial.user;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'ERROR LOGIN FIREBASE: ${e.code}',
      );
      return null;
    }
  }
}