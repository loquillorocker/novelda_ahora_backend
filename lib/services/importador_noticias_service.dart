import 'dart:convert';

import '../models/noticia.dart';
import 'firestore_noticias_service.dart';
import 'fuentes_rss.dart';
import 'rss_service.dart';
import 'youtube_service.dart';

class ImportadorNoticiasService {
  final RssService _rssService;
  final FirestoreNoticiasService _firestoreService;
  final YouTubeService _youtubeService;

  static const int _maxNoticiasPorFuente = 15;

  ImportadorNoticiasService({
    RssService? rssService,
    FirestoreNoticiasService? firestoreService,
    YouTubeService? youtubeService,
  })  : _rssService = rssService ?? RssService(),
        _firestoreService =
            firestoreService ?? FirestoreNoticiasService(),
        _youtubeService = youtubeService ?? YouTubeService();

  Future<int> importarFuente(FuenteRss fuente) async {
    try {
      print('===== IMPORTANDO FUENTE =====');
      print('Fuente: ${fuente.nombre}');
      print('URL: ${fuente.url}');

      final items = await _rssService.obtenerItems(
        fuente.url,
      );

      print('Items RSS recibidos: ${items.length}');

      /*
       * FILTRO DEFINITIVO:
       *
       * Solo entran noticias cuyo TÍTULO contiene
       * la palabra "Novelda".
       *
       * No se utiliza el resumen, contenido ni URL
       * para decidir si una noticia es de Novelda.
       */
      final itemsNovelda = items
          .where(
            (item) => _tituloContieneNovelda(
          item.titulo,
        ),
      )
          .take(_maxNoticiasPorFuente)
          .toList();

      print(
        'Items con "Novelda" en el título: '
            '${itemsNovelda.length}',
      );

      for (final item in itemsNovelda) {
        print(
          'ACEPTADA: ${item.titulo}',
        );
      }

      /*
       * Convertimos solamente las noticias que han pasado
       * el filtro.
       */
      final noticias = itemsNovelda
          .map(
            (item) => _convertirItem(
          item,
          fuente,
        ),
      )
          .toList();

      /*
       * IMPORTANTE:
       *
       * Sincronizamos la fuente antes de guardar.
       *
       * Esto elimina de Firestore las noticias antiguas
       * de esta misma fuente que ya no aparecen entre las
       * noticias válidas actuales.
       */
      await _firestoreService.sincronizarNoticiasFuente(
        fuenteId: fuente.id,
        noticiasValidas: noticias,
      );

      print(
        'Noticias sincronizadas de ${fuente.nombre}: '
            '${noticias.length}',
      );

      return noticias.length;
    } catch (e) {
      print('===== ERROR IMPORTANDO FUENTE =====');
      print('Fuente: ${fuente.nombre}');
      print('Error: $e');

      return 0;
    }
  }

  /*
   * Devuelve true únicamente cuando el título contiene
   * "Novelda".
   *
   * La comparación no distingue mayúsculas/minúsculas.
   *
   * Ejemplos:
   *
   * "Novelda celebra sus fiestas"       -> TRUE
   * "La Policía de Novelda detiene..."  -> TRUE
   * "NOVELDA prepara..."                -> TRUE
   * "Noticias de noveldenses..."        -> FALSE
   * "El Vinalopó..."                    -> FALSE
   */
  bool _tituloContieneNovelda(
      String titulo,
      ) {
    final normalizado = _normalizarTexto(
      titulo,
    );

    return normalizado.contains('novelda');
  }

  String _normalizarTexto(
      String texto,
      ) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll(
      RegExp(
        r'<[^>]*>',
        caseSensitive: false,
      ),
      ' ',
    )
        .replaceAll(
      RegExp(
        r'&[a-z0-9#]+;',
        caseSensitive: false,
      ),
      ' ',
    )
        .replaceAll(
      RegExp(
        r'[^a-záéíóúüñ0-9]+',
      ),
      ' ',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }

  Future<int> importarVideos() async {
    try {
      print('===== IMPORTANDO VIDEOS =====');

      final videos =
      await _youtubeService.obtenerUltimosVideos(
        limite: 10,
      );

      print(
        'Videos recibidos: ${videos.length}',
      );

      final noticias = <Noticia>[];

      for (final video in videos) {
        final snippet =
        video['snippet'] as Map<String, dynamic>?;

        final contentDetails =
        video['contentDetails']
        as Map<String, dynamic>?;

        if (snippet == null ||
            contentDetails == null) {
          continue;
        }

        final videoId =
        contentDetails['videoId'] as String?;

        final titulo =
        snippet['title'] as String?;

        final descripcion =
        snippet['description'] as String?;

        final fechaTexto =
        snippet['publishedAt'] as String?;

        if (videoId == null ||
            videoId.trim().isEmpty ||
            titulo == null ||
            titulo.trim().isEmpty) {
          continue;
        }

        final textoVideo = [
          titulo,
          descripcion ?? '',
        ].join(' ');

        if (!_textoIndicaNovelda(
          textoVideo,
        )) {
          continue;
        }

        final imagenUrl = _obtenerMiniatura(
          snippet,
          videoId,
        );

        final fechaPublicacion =
            DateTime.tryParse(
              fechaTexto ?? '',
            ) ??
                DateTime.now();

        noticias.add(
          Noticia(
            id: 'youtube_$videoId',
            titulo: titulo.trim(),
            resumen:
            descripcion?.trim().isNotEmpty == true
                ? descripcion!.trim()
                : 'Vídeo de actualidad de Novelda.',
            contenido: null,
            tipo: TipoContenido.video,
            categoria: CategoriaNoticia.actualidad,
            fuenteId: 'noveldadigital_youtube',
            fuenteNombre: 'Noveldadigital',
            urlOriginal:
            'https://www.youtube.com/watch?v=$videoId',
            imagenUrl: imagenUrl,
            videoUrl:
            'https://www.youtube.com/watch?v=$videoId',
            fechaPublicacion: fechaPublicacion,
            fechaCaptura: DateTime.now(),
            autor: null,
            ubicacion: 'Novelda',
            destacada: false,
            activa: true,
            etiquetas: const [],
          ),
        );
      }

      if (noticias.isNotEmpty) {
        await _firestoreService.guardarNoticias(
          noticias,
        );
      }

      print(
        'Videos de Novelda guardados: '
            '${noticias.length}',
      );

      return noticias.length;
    } catch (e) {
      print(
        '===== ERROR IMPORTANDO VIDEOS =====',
      );
      print('Error: $e');

      return 0;
    }
  }

  /*
   * Filtro utilizado únicamente para YouTube.
   *
   * Aquí mantenemos la búsqueda en título + descripción,
   * porque la regla nueva que estamos aplicando es para
   * las noticias RSS.
   */
  bool _textoIndicaNovelda(
      String texto,
      ) {
    if (texto.trim().isEmpty) {
      return false;
    }

    final normalizado = _normalizarTexto(
      texto,
    );

    return normalizado.contains('novelda');
  }

  Future<int> importarNoticias() async {
    return importarTodas();
  }

  Future<int> importarTodas() async {
    print(
      '========================================',
    );
    print(
      '===== INICIO IMPORTACION NOTICIAS =====',
    );
    print(
      '========================================',
    );

    int total = 0;

    for (final fuente
    in FuentesRss.noticiasNovelda) {
      final cantidad =
      await importarFuente(fuente);

      total += cantidad;
    }

    total += await importarVideos();

    print(
      '========================================',
    );
    print(
      '===== FIN IMPORTACION =====',
    );
    print(
      'Total importado: $total',
    );
    print(
      '========================================',
    );

    return total;
  }

  Noticia _convertirItem(
      NoticiaRss item,
      FuenteRss fuente,
      ) {
    return Noticia(
      id: _generarId(
        item.url,
      ),
      titulo: item.titulo.trim(),
      resumen: item.resumen ??
          'Consulta la noticia completa en '
              '${fuente.nombre}.',
      contenido: null,
      tipo: TipoContenido.noticia,
      categoria: _convertirCategoria(
        fuente.categoriaPorDefecto,
      ),
      fuenteId: fuente.id,
      fuenteNombre: fuente.nombre,
      urlOriginal: item.url,
      imagenUrl: item.imagenUrl,
      videoUrl: null,
      fechaPublicacion:
      item.fechaPublicacion ??
          DateTime.now(),
      fechaCaptura: DateTime.now(),
      autor: item.autor,
      ubicacion: 'Novelda',
      destacada: false,
      activa: true,
      etiquetas: const [],
    );
  }

  String? _obtenerMiniatura(
      Map<String, dynamic> snippet,
      String videoId,
      ) {
    final thumbnails =
    snippet['thumbnails']
    as Map<String, dynamic>?;

    if (thumbnails != null) {
      const nombres = [
        'maxres',
        'standard',
        'high',
        'medium',
        'default',
      ];

      for (final nombre in nombres) {
        final thumbnail =
        thumbnails[nombre]
        as Map<String, dynamic>?;

        final url =
        thumbnail?['url'] as String?;

        if (url != null &&
            url.trim().isNotEmpty) {
          return url;
        }
      }
    }

    return 'https://i.ytimg.com/vi/'
        '$videoId/hqdefault.jpg';
  }

  CategoriaNoticia _convertirCategoria(
      String categoria,
      ) {
    return CategoriaNoticia.values.firstWhere(
          (item) => item.name == categoria,
      orElse: () =>
      CategoriaNoticia.actualidad,
    );
  }

  String _generarId(
      String url,
      ) {
    return base64Url.encode(
      utf8.encode(url),
    );
  }
}