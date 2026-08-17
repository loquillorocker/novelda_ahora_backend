import 'dart:convert';

import '../models/noticia.dart';
import 'firestore_noticias_service.dart';
import 'fuentes_rss.dart';
import 'rss_service.dart';

class ImportadorNoticiasService {
  final RssService _rssService;
  final FirestoreNoticiasService _firestoreService;

  ImportadorNoticiasService({
    RssService? rssService,
    FirestoreNoticiasService? firestoreService,
  })  : _rssService = rssService ?? RssService(),
        _firestoreService =
            firestoreService ?? FirestoreNoticiasService();

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

  Future<int> importarTodas() async {
    int total = 0;

    for (final fuente in FuentesRss.todas) {
      total += await importarFuente(fuente);
    }

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