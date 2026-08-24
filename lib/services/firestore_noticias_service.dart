import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/noticia.dart';

class FirestoreNoticiasService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _noticias =>
      _firestore.collection('noticias');

  Future<void> guardarNoticia(
      Noticia noticia,
      ) async {
    debugPrint('===== FIRESTORE =====');
    debugPrint(
      'Guardando noticia: ${noticia.titulo}',
    );
    debugPrint(
      'ID: ${noticia.id}',
    );
    debugPrint(
      'Fecha: ${noticia.fechaPublicacion}',
    );
    debugPrint(
      'Ubicación: ${noticia.ubicacion}',
    );
    debugPrint(
      'Tipo: ${noticia.tipo.name}',
    );

    await _noticias.doc(noticia.id).set(
      noticia.toMap(),
    );

    debugPrint(
      'Noticia guardada correctamente.',
    );
  }

  Future<void> guardarNoticias(
      List<Noticia> noticias,
      ) async {
    if (noticias.isEmpty) {
      debugPrint('===== FIRESTORE =====');
      debugPrint(
        'No hay noticias para guardar.',
      );
      return;
    }

    debugPrint('===== FIRESTORE =====');
    debugPrint(
      'Guardando ${noticias.length} noticias...',
    );

    const tamanoLote = 400;

    for (
    var inicio = 0;
    inicio < noticias.length;
    inicio += tamanoLote
    ) {
      final fin =
      (inicio + tamanoLote < noticias.length)
          ? inicio + tamanoLote
          : noticias.length;

      final lote = _firestore.batch();

      for (final noticia
      in noticias.sublist(inicio, fin)) {
        lote.set(
          _noticias.doc(noticia.id),
          noticia.toMap(),
        );
      }

      await lote.commit();

      debugPrint(
        'Lote guardado: $inicio - $fin',
      );
    }

    debugPrint('===== FIRESTORE =====');
    debugPrint(
      'Guardadas correctamente: ${noticias.length}',
    );
  }

  /*
   * SINCRONIZA UNA FUENTE RSS COMPLETA.
   *
   * Esta función es la parte importante del cambio.
   *
   * Busca todas las noticias RSS pertenecientes a la fuente
   * indicada y elimina las que ya no forman parte del conjunto
   * válido que acabamos de importar.
   *
   * De esta manera, si antes había:
   *
   *   15 noticias
   *
   * y después del nuevo filtro solamente quedan:
   *
   *   4 noticias
   *
   * Firestore termina teniendo únicamente esas 4.
   *
   * Los vídeos de YouTube no se tocan porque su fuenteId
   * es diferente y su tipo también es diferente.
   */
  Future<void> sincronizarNoticiasFuente({
    required String fuenteId,
    required List<Noticia> noticiasValidas,
  }) async {
    debugPrint(
      '========================================',
    );
    debugPrint(
      '===== SINCRONIZANDO FUENTE FIRESTORE =====',
    );
    debugPrint(
      'Fuente ID: $fuenteId',
    );
    debugPrint(
      'Noticias válidas actuales: '
          '${noticiasValidas.length}',
    );

    final idsValidos = noticiasValidas
        .map(
          (noticia) => noticia.id,
    )
        .toSet();

    final snapshot = await _noticias
        .where(
      'fuenteId',
      isEqualTo: fuenteId,
    )
        .where(
      'tipo',
      isEqualTo: TipoContenido.noticia.name,
    )
        .get(
      const GetOptions(
        source: Source.server,
      ),
    );

    debugPrint(
      'Noticias existentes de la fuente: '
          '${snapshot.docs.length}',
    );

    final documentosParaEliminar =
    snapshot.docs.where(
          (documento) =>
      !idsValidos.contains(
        documento.id,
      ),
    );

    final eliminaciones =
    documentosParaEliminar.toList();

    debugPrint(
      'Noticias antiguas que se eliminarán: '
          '${eliminaciones.length}',
    );

    const tamanoLote = 400;

    for (
    var inicio = 0;
    inicio < eliminaciones.length;
    inicio += tamanoLote
    ) {
      final fin =
      (inicio + tamanoLote <
          eliminaciones.length)
          ? inicio + tamanoLote
          : eliminaciones.length;

      final lote = _firestore.batch();

      for (final documento
      in eliminaciones.sublist(inicio, fin)) {
        debugPrint(
          'ELIMINANDO: '
              '${documento.data()['titulo'] ?? documento.id}',
        );

        lote.delete(
          documento.reference,
        );
      }

      await lote.commit();

      debugPrint(
        'Lote de eliminaciones completado: '
            '$inicio - $fin',
      );
    }

    /*
     * Ahora guardamos las noticias que sí cumplen
     * el filtro actual.
     */
    if (noticiasValidas.isNotEmpty) {
      await guardarNoticias(
        noticiasValidas,
      );
    }

    debugPrint(
      '===== SINCRONIZACIÓN COMPLETADA =====',
    );
    debugPrint(
      'Fuente: $fuenteId',
    );
    debugPrint(
      'Noticias actuales: ${noticiasValidas.length}',
    );
    debugPrint(
      '========================================',
    );
  }

  Future<void> actualizarNoticia(
      Noticia noticia,
      ) async {
    await _noticias.doc(noticia.id).update(
      noticia.toMap(),
    );

    debugPrint(
      'Noticia actualizada: ${noticia.titulo}',
    );
  }

  Future<void> eliminarNoticia(
      String id,
      ) async {
    await _noticias.doc(id).delete();

    debugPrint(
      'Noticia eliminada: $id',
    );
  }

  Future<Noticia?> obtenerNoticia(
      String id,
      ) async {
    final documento =
    await _noticias.doc(id).get(
      const GetOptions(
        source: Source.server,
      ),
    );

    if (!documento.exists ||
        documento.data() == null) {
      return null;
    }

    return Noticia.fromMap(
      documento.data()!,
    );
  }

  Future<List<Noticia>> obtenerNoticias({
    int limite = 20,
  }) async {
    debugPrint(
      '========================================',
    );
    debugPrint(
      '===== FIRESTORE CONSULTA HOME =====',
    );
    debugPrint(
      'Lectura forzada desde SERVIDOR',
    );
    debugPrint(
      'Límite solicitado: $limite',
    );

    try {
      final snapshot = await _noticias
          .where(
        'activa',
        isEqualTo: true,
      )
          .where(
        'tipo',
        isEqualTo: TipoContenido.noticia.name,
      )
          .where(
        'ubicacion',
        isEqualTo: 'Novelda',
      )
          .orderBy(
        'fechaPublicacion',
        descending: true,
      )
          .limit(limite)
          .get(
        const GetOptions(
          source: Source.server,
        ),
      );

      debugPrint(
        '===== FIRESTORE SNAPSHOT =====',
      );
      debugPrint(
        'Fuente de datos: SERVIDOR',
      );
      debugPrint(
        'Documentos recibidos: '
            '${snapshot.docs.length}',
      );

      final noticias = snapshot.docs
          .map(
            (documento) => Noticia.fromMap(
          documento.data(),
        ),
      )
          .toList();

      _diagnosticarNoticias(
        noticias,
        origen: 'obtenerNoticias()',
      );

      return noticias;
    } catch (e) {
      debugPrint(
        '===== ERROR FIRESTORE HOME =====',
      );
      debugPrint(
        'No se pudo consultar el servidor.',
      );
      debugPrint(
        'Error: $e',
      );
      debugPrint(
        '========================================',
      );

      rethrow;
    }
  }

  Stream<List<Noticia>> escucharNoticias({
    int limite = 20,
  }) async* {
    debugPrint(
      '========================================',
    );
    debugPrint(
      '===== FIRESTORE STREAM HOME =====',
    );
    debugPrint(
      'INICIO ESCUCHA DE NOTICIAS',
    );
    debugPrint(
      'Límite: $limite',
    );
    debugPrint(
      '========================================',
    );

    /*
     * PRIMERA LECTURA:
     *
     * El Home utiliza este método, no obtenerNoticias().
     * Hacemos primero una lectura REAL desde servidor.
     */
    try {
      debugPrint(
        '===== STREAM: LECTURA INICIAL SERVIDOR =====',
      );

      final servidor = await _noticias
          .where(
        'activa',
        isEqualTo: true,
      )
          .where(
        'tipo',
        isEqualTo: TipoContenido.noticia.name,
      )
          .where(
        'ubicacion',
        isEqualTo: 'Novelda',
      )
          .orderBy(
        'fechaPublicacion',
        descending: true,
      )
          .limit(limite)
          .get(
        const GetOptions(
          source: Source.server,
        ),
      );

      debugPrint(
        '===== RESULTADO SERVIDOR =====',
      );
      debugPrint(
        'Documentos recibidos: '
            '${servidor.docs.length}',
      );

      final noticiasServidor = servidor.docs
          .map(
            (documento) => Noticia.fromMap(
          documento.data(),
        ),
      )
          .toList();

      _diagnosticarNoticias(
        noticiasServidor,
        origen: 'STREAM / SERVIDOR',
      );

      yield noticiasServidor;
    } catch (e) {
      debugPrint(
        '===== ERROR LECTURA INICIAL SERVIDOR =====',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        'Se continúa con el listener de Firestore.',
      );
    }

    /*
     * SEGUNDA PARTE:
     *
     * Listener normal de Firestore.
     */
    debugPrint(
      '===== STREAM: ACTIVANDO LISTENER =====',
    );

    await for (final snapshot in _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'tipo',
      isEqualTo: TipoContenido.noticia.name,
    )
        .where(
      'ubicacion',
      isEqualTo: 'Novelda',
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(limite)
        .snapshots(
      includeMetadataChanges: true,
    )) {
      debugPrint(
        '========================================',
      );
      debugPrint(
        '===== FIRESTORE STREAM SNAPSHOT =====',
      );
      debugPrint(
        'Documentos recibidos: '
            '${snapshot.docs.length}',
      );
      debugPrint(
        'Desde caché: '
            '${snapshot.metadata.isFromCache}',
      );
      debugPrint(
        'Tiene escrituras pendientes: '
            '${snapshot.metadata.hasPendingWrites}',
      );

      final noticias = snapshot.docs
          .map(
            (documento) => Noticia.fromMap(
          documento.data(),
        ),
      )
          .toList();

      _diagnosticarNoticias(
        noticias,
        origen: 'STREAM / SNAPSHOT',
      );

      yield noticias;
    }
  }

  Stream<List<Noticia>> escucharVideos({
    int limite = 20,
  }) {
    debugPrint(
      '===== FIRESTORE STREAM VIDEOS =====',
    );

    return _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'tipo',
      isEqualTo: TipoContenido.video.name,
    )
        .where(
      'ubicacion',
      isEqualTo: 'Novelda',
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(limite)
        .snapshots(
      includeMetadataChanges: true,
    )
        .map(
          (snapshot) {
        debugPrint(
          '===== FIRESTORE VIDEOS SNAPSHOT =====',
        );

        debugPrint(
          'Documentos recibidos: '
              '${snapshot.docs.length}',
        );

        debugPrint(
          'Desde caché: '
              '${snapshot.metadata.isFromCache}',
        );

        final videos = snapshot.docs
            .map(
              (documento) => Noticia.fromMap(
            documento.data(),
          ),
        )
            .toList();

        debugPrint(
          'Videos Novelda entregados: '
              '${videos.length}',
        );

        return videos;
      },
    );
  }

  Future<Noticia?> obtenerNoticiaDestacada() async {
    debugPrint(
      '===== FIRESTORE NOTICIA DESTACADA =====',
    );

    final snapshot = await _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'destacada',
      isEqualTo: true,
    )
        .where(
      'ubicacion',
      isEqualTo: 'Novelda',
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(1)
        .get(
      const GetOptions(
        source: Source.server,
      ),
    );

    debugPrint(
      'Destacadas encontradas: '
          '${snapshot.docs.length}',
    );

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return Noticia.fromMap(
      snapshot.docs.first.data(),
    );
  }

  Future<List<Noticia>> obtenerNoticiasPorCategoria(
      CategoriaNoticia categoria, {
        int limite = 3,
      }) async {
    debugPrint(
      '===== FIRESTORE CATEGORIA =====',
    );

    debugPrint(
      'Categoría: ${categoria.name}',
    );

    final snapshot = await _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'categoria',
      isEqualTo: categoria.name,
    )
        .where(
      'ubicacion',
      isEqualTo: 'Novelda',
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(limite)
        .get(
      const GetOptions(
        source: Source.server,
      ),
    );

    debugPrint(
      'Noticias encontradas: '
          '${snapshot.docs.length}',
    );

    return snapshot.docs
        .map(
          (documento) => Noticia.fromMap(
        documento.data(),
      ),
    )
        .toList();
  }

  // ============================================================
  // DIAGNÓSTICO
  // ============================================================

  void _diagnosticarNoticias(
      List<Noticia> noticias, {
        required String origen,
      }) {
    debugPrint(
      '===== DIAGNÓSTICO NOTICIAS =====',
    );
    debugPrint(
      'Origen: $origen',
    );
    debugPrint(
      'Total entregadas: ${noticias.length}',
    );

    if (noticias.isEmpty) {
      debugPrint(
        '¡¡¡ FIRESTORE NO DEVOLVIÓ NINGUNA NOTICIA !!!',
      );
      debugPrint(
        '========================================',
      );
      return;
    }

    for (var i = 0; i < noticias.length; i++) {
      final noticia = noticias[i];

      debugPrint(
        '--- NOTICIA ${i + 1} ---',
      );
      debugPrint(
        'Título: ${noticia.titulo}',
      );
      debugPrint(
        'Fecha: ${noticia.fechaPublicacion}',
      );
      debugPrint(
        'Fuente: ${noticia.fuenteNombre}',
      );
      debugPrint(
        'Fuente ID: ${noticia.fuenteId}',
      );
      debugPrint(
        'Ubicación: ${noticia.ubicacion}',
      );
      debugPrint(
        'Tipo: ${noticia.tipo.name}',
      );
      debugPrint(
        'Activa: ${noticia.activa}',
      );
      debugPrint(
        'ID: ${noticia.id}',
      );
      debugPrint(
        'Imagen: ${noticia.imagenUrl}',
      );
    }

    debugPrint(
      '========================================',
    );
  }
}