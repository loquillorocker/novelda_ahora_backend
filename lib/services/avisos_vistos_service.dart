import 'package:shared_preferences/shared_preferences.dart';

class AvisosVistosService {
  static const String _claveAvisosVistos = 'avisos_vistos';

  Future<Set<String>> obtenerAvisosVistos() async {
    final prefs = await SharedPreferences.getInstance();

    final avisos = prefs.getStringList(_claveAvisosVistos) ?? const [];

    return avisos.toSet();
  }

  Future<bool> haVistoAviso(String avisoId) async {
    final avisosVistos = await obtenerAvisosVistos();

    return avisosVistos.contains(avisoId);
  }

  Future<void> marcarAvisoComoVisto(String avisoId) async {
    final prefs = await SharedPreferences.getInstance();

    final avisosVistos =
        prefs.getStringList(_claveAvisosVistos) ?? <String>[];

    if (!avisosVistos.contains(avisoId)) {
      avisosVistos.add(avisoId);

      await prefs.setStringList(
        _claveAvisosVistos,
        avisosVistos,
      );
    }
  }

  Future<void> limpiarAvisosVistos() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_claveAvisosVistos);
  }
}