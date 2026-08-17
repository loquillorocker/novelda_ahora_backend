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

  ImportadorNoticiasService({
    RssService? rssService,
    FirestoreNoticiasService? firestoreService,
    YouTubeService? youtubeService,
  })  : _rssService = rssService ?? RssService(),
        _firestoreService =
            firestoreService ?? FirestoreNoticiasService(),
        _youtubeService = youtubeService ?? YouTubeService();

  Future<int> importarFuente(FuenteRss fuente) async {
    final items = await _rssService.obtenerItems(fuente.url);

    int importadas = 0;

    for (final item in items) {
      final noticia = _convertirItem(
        item,
        fuente,
      );

      await _firestoreService.guardarNoticia(noticia);
      importadas++;
    }

    return importadas;
  }

  Future<int> importarVideos() async {
    final videos = await _youtubeService.obtenerUltimosVideos(
      limite: 10,
    );

    int importados = 0;

    for (final video in videos) {
      final snippet =
      video['snippet'] as Map<String, dynamic>?;

      final contentDetails =
      video['contentDetails'] as Map<String, dynamic>?;

      if (snippet == null || contentDetails == null) {
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

      final imagenUrl = _obtenerMiniatura(
        snippet,
        videoId,
      );

      final fechaPublicacion =
          DateTime.tryParse(fechaTexto ?? '') ??
              DateTime.now();

      final noticia = Noticia(
        id: 'youtube_$videoId',
        titulo: titulo.trim(),
        resumen: descripcion?.trim().isNotEmpty == true
            ? descripcion!.trim()
            : 'Vídeo de noveldadigital.',
        contenido: null,
        tipo: TipoContenido.video,
        categoria: CategoriaNoticia.actualidad,
        fuenteId: 'noveldadigital_youtube',
        fuenteNombre: 'noveldadigital',
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
      );

      await _firestoreService.guardarNoticia(noticia);
      importados++;
    }

    return importados;
  }

  Future<int> importarTodas() async {
    int total = 0;

    for (final fuente in FuentesRss.todas) {
      total += await importarFuente(fuente);
    }

    total += await importarVideos();

    return total;
  }

  Noticia _convertirItem(
      NoticiaRss item,
      FuenteRss fuente,
      ) {
    return Noticia(
      id: _generarId(item.url),
      titulo: item.titulo,
      resumen: item.resumen ??
          'Consulta la noticia completa en ${fuente.nombre}.',
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
      item.fechaPublicacion ?? DateTime.now(),
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
    snippet['thumbnails'] as Map<String, dynamic>?;

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
        thumbnails[nombre] as Map<String, dynamic>?;

        final url = thumbnail?['url'] as String?;

        if (url != null && url.trim().isNotEmpty) {
          return url;
        }
      }
    }

    return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
  }

  CategoriaNoticia _convertirCategoria(
      String categoria,
      ) {
    return CategoriaNoticia.values.firstWhere(
          (item) => item.name == categoria,
      orElse: () => CategoriaNoticia.actualidad,
    );
  }

  String _generarId(String url) {
    return base64Url.encode(
      utf8.encode(url),
    );
  }
}