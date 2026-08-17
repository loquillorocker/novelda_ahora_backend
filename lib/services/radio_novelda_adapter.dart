import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

import 'rss_service.dart';

class RadioNoveldaAdapter {
  static const String feedUrl =
      'https://www.noveldaradio.es/feed/';

  Future<List<NoticiaRss>> obtenerNoticias() async {
    final uri = Uri.parse(feedUrl);

    final respuesta = await http.get(
      uri,
      headers: const {
        'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/149.0.0.0 Safari/537.36',
        'Accept':
        'application/rss+xml, application/xml, text/xml, */*',
        'Accept-Language':
        'es-ES,es;q=0.9,en;q=0.8',
      },
    );

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo obtener el RSS de Radio Novelda. '
            'Código HTTP: ${respuesta.statusCode}',
      );
    }

    final feed = RssFeed.parse(respuesta.body);

    return feed.items
        ?.where(
          (item) =>
      item.title != null &&
          item.link != null,
    )
        .map(
          (item) => NoticiaRss(
        titulo: item.title!.trim(),
        resumen: _limpiarTexto(
          item.description,
        ),
        url: item.link!.trim(),
        fechaPublicacion: item.pubDate,
        autor: item.author?.trim(),
      ),
    )
        .toList() ??
        [];
  }

  String? _limpiarTexto(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return null;
    }

    return texto
        .replaceAll(
      RegExp(r'<[^>]*>'),
      ' ',
    )
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }
}