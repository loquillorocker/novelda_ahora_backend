import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/aviso.dart';

class AvisosService {
  final FirebaseFirestore _firestore;

  AvisosService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Devuelve el aviso meteorológico activo más relevante para Novelda.
  ///
  /// Los avisos son creados automáticamente por el backend de AEMET
  /// en la colección "avisos_creados".
  Future<Aviso?> obtenerAvisoActivo() async {
    final ahora = DateTime.now();

    final snapshot = await _firestore
        .collection('avisos_creados')
        .where('activo', isEqualTo: true)
        .get();

    final avisos = <Aviso>[];

    for (final document in snapshot.docs) {
      final data = document.data();

      final aviso = _convertirAviso(document.id, data);

      if (aviso == null) {
        continue;
      }

      if (!aviso.activo) {
        continue;
      }

      if (aviso.fechaFin.isBefore(ahora)) {
        continue;
      }

      if (aviso.fechaInicio.isAfter(ahora)) {
        continue;
      }

      avisos.add(aviso);
    }

    if (avisos.isEmpty) {
      return null;
    }

    // Primero los urgentes, después importantes y finalmente informativos.
    avisos.sort((a, b) {
      final prioridadA = _prioridadNivel(a.nivel);
      final prioridadB = _prioridadNivel(b.nivel);

      if (prioridadA != prioridadB) {
        return prioridadB.compareTo(prioridadA);
      }

      return b.fechaInicio.compareTo(a.fechaInicio);
    });

    return avisos.first;
  }

  /// Devuelve todos los avisos meteorológicos activos.
  Future<List<Aviso>> obtenerAvisosActivos() async {
    final ahora = DateTime.now();

    final snapshot = await _firestore
        .collection('avisos_creados')
        .where('activo', isEqualTo: true)
        .get();

    final avisos = <Aviso>[];

    for (final document in snapshot.docs) {
      final aviso = _convertirAviso(
        document.id,
        document.data(),
      );

      if (aviso == null) {
        continue;
      }

      if (aviso.fechaFin.isBefore(ahora)) {
        continue;
      }

      if (aviso.fechaInicio.isAfter(ahora)) {
        continue;
      }

      avisos.add(aviso);
    }

    avisos.sort((a, b) {
      final prioridadA = _prioridadNivel(a.nivel);
      final prioridadB = _prioridadNivel(b.nivel);

      if (prioridadA != prioridadB) {
        return prioridadB.compareTo(prioridadA);
      }

      return b.fechaInicio.compareTo(a.fechaInicio);
    });

    return avisos;
  }

  Aviso? _convertirAviso(
      String documentId,
      Map<String, dynamic> data,
      ) {
    try {
      final inicio = _parseFecha(data['inicio']);
      final fin = _parseFecha(data['fin']);

      if (inicio == null || fin == null) {
        return null;
      }

      final titulo =
      (data['titulo'] as String?)?.trim().isNotEmpty == true
          ? data['titulo'] as String
          : 'Aviso meteorológico';

      final descripcion =
      (data['descripcion'] as String?)?.trim().isNotEmpty == true
          ? data['descripcion'] as String
          : 'Aviso meteorológico para la zona de Novelda.';

      final nivel = _convertirNivel(
        data['nivel'] as String?,
      );

      return Aviso(
        id: (data['id'] as String?)?.trim().isNotEmpty == true
            ? data['id'] as String
            : documentId,
        titulo: titulo,
        mensaje: descripcion,
        categoria: CategoriaAviso.meteorologia,
        nivel: nivel,
        fuente: 'AEMET',
        url: data['urlAemet'] as String?,
        fechaInicio: inicio,
        fechaFin: fin,
        activo: data['activo'] as bool? ?? true,
        creadoPor: 'AEMET',
        creadoEn: _parseFecha(data['actualizadoEn']) ?? DateTime.now(),
        actualizadoEn: _parseFecha(data['actualizadoEn']),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseFecha(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  NivelAviso _convertirNivel(String? nivel) {
    switch (nivel?.toLowerCase()) {
      case 'rojo':
        return NivelAviso.urgente;

      case 'naranja':
        return NivelAviso.importante;

      case 'amarillo':
        return NivelAviso.importante;

      default:
        return NivelAviso.informativo;
    }
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