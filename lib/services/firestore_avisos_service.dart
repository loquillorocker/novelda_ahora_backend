import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/aviso.dart';

class FirestoreAvisosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _avisosCollection =>
      _firestore.collection('avisos');

  /// Obtiene todos los avisos activos y vigentes en este momento.
  Future<List<Aviso>> obtenerAvisosActivos() async {
    final ahora = Timestamp.now();

    final snapshot = await _avisosCollection
        .where('activo', isEqualTo: true)
        .where('fechaInicio', isLessThanOrEqualTo: ahora)
        .where('fechaFin', isGreaterThanOrEqualTo: ahora)
        .get();

    final avisos = snapshot.docs.map((doc) {
      final data = doc.data();

      return Aviso(
        id: doc.id,
        titulo: data['titulo'] as String,
        mensaje: data['mensaje'] as String,
        categoria: CategoriaAviso.values.firstWhere(
              (categoria) => categoria.name == data['categoria'],
          orElse: () => CategoriaAviso.otros,
        ),
        nivel: NivelAviso.values.firstWhere(
              (nivel) => nivel.name == data['nivel'],
          orElse: () => NivelAviso.informativo,
        ),
        fuente: data['fuente'] as String,
        url: data['url'] as String?,
        fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
        fechaFin: (data['fechaFin'] as Timestamp).toDate(),
        activo: data['activo'] as bool? ?? true,
        creadoPor: data['creadoPor'] as String,
        creadoEn: (data['creadoEn'] as Timestamp).toDate(),
        actualizadoEn: data['actualizadoEn'] != null
            ? (data['actualizadoEn'] as Timestamp).toDate()
            : null,
      );
    }).toList();

    avisos.sort((a, b) {
      final nivelComparacion =
      _prioridadNivel(b.nivel).compareTo(_prioridadNivel(a.nivel));

      if (nivelComparacion != 0) {
        return nivelComparacion;
      }

      return b.fechaInicio.compareTo(a.fechaInicio);
    });

    return avisos;
  }

  int _prioridadNivel(NivelAviso nivel) {
    switch (nivel) {
      case NivelAviso.urgente:
        return 3;
      case NivelAviso.importante:
        return 2;
      case NivelAviso.informativo:
        return 1;
    }
  }
}