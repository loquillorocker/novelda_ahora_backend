import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';

class NoticiaRss {
  final String titulo;
  final String? resumen;
  final String url;
  final DateTime? fechaPublicacion;
  final String? autor;
  final String? imagenUrl;

  const NoticiaRss({
    required this.titulo,
    this.resumen,
    required this.url,
    this.fechaPublicacion,
    this.autor,
    this.imagenUrl,
  });
}

class RssService {
  Future<List<NoticiaRss>> obtenerItems(String rssUrl) async {
    final uri = Uri.parse(rssUrl);

    final respuesta = await http.get(
      uri,
      headers: const {
        'User-Agent': 'NoveldaAhora/1.0',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*',
      },
    );

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo obtener el RSS. '
            'Código HTTP: ${respuesta.statusCode}',
      );
    }

    final xml = respuesta.body.trim();

    if (!xml.startsWith('<')) {
      throw Exception(
        'La fuente no está devolviendo XML/RSS. '
            'Contenido recibido: '
            '${xml.substring(0, xml.length > 200 ? 200 : xml.length)}',
      );
    }

    final feed = RssFeed.parse(xml);

    final resultado = <NoticiaRss>[];

    for (final item in feed.items ?? []) {
      if (item.title == null || item.link == null) {
        continue;
      }

      final titulo = item.title!.trim();
      final url = item.link!.trim();
      final descripcion = item.description;

      final imagen = _extraerImagen(
        xml,
        url,
        descripcion,
      );

      resultado.add(
        NoticiaRss(
          titulo: titulo,
          resumen: _limpiarTexto(descripcion),
          url: url,
          fechaPublicacion: item.pubDate,
          autor: item.author?.trim(),
          imagenUrl: imagen,
        ),
      );
    }

    return resultado;
  }

  String? _extraerImagen(
      String xml,
      String urlNoticia,
      String? descripcion,
      ) {
    final imagenDescripcion = _extraerImagenDeHtml(descripcion);

    if (imagenDescripcion != null) {
      return imagenDescripcion;
    }

    final bloqueItem = _buscarBloqueItem(
      xml,
      urlNoticia,
    );

    if (bloqueItem == null) {
      return null;
    }

    final imagenMediaContent = _extraerAtributoUrl(
      bloqueItem,
      'media:content',
    );

    if (imagenMediaContent != null) {
      return imagenMediaContent;
    }

    final imagenThumbnail = _extraerAtributoUrl(
      bloqueItem,
      'media:thumbnail',
    );

    if (imagenThumbnail != null) {
      return imagenThumbnail;
    }

    final imagenEnclosure = _extraerAtributoUrl(
      bloqueItem,
      'enclosure',
    );

    if (imagenEnclosure != null) {
      return imagenEnclosure;
    }

    final imagenHtmlItem = _extraerImagenDeHtml(
      bloqueItem,
    );

    if (imagenHtmlItem != null) {
      return imagenHtmlItem;
    }

    return null;
  }

  String? _buscarBloqueItem(
      String xml,
      String urlNoticia,
      ) {
    final items = RegExp(
      r'<item\b[^>]*>.*?</item>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(xml);

    for (final match in items) {
      final bloque = match.group(0);

      if (bloque == null) {
        continue;
      }

      if (bloque.contains(urlNoticia)) {
        return bloque;
      }
    }

    return null;
  }

  String? _extraerAtributoUrl(
      String xml,
      String etiqueta,
      ) {
    final patron = RegExp(
      '<$etiqueta\\b[^>]*\\burl\\s*=\\s*[\'"]([^\'"]+)[\'"]',
      caseSensitive: false,
      dotAll: true,
    );

    final match = patron.firstMatch(xml);

    if (match == null) {
      return null;
    }

    final url = match.group(1);

    if (!_esUrlValida(url)) {
      return null;
    }

    return _normalizarUrl(url!);
  }

  String? _extraerImagenDeHtml(String? html) {
    if (html == null || html.trim().isEmpty) {
      return null;
    }

    final patrones = [
      RegExp(
        r'''<img\b[^>]*\bsrc\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
        dotAll: true,
      ),
      RegExp(
        r'''<img\b[^>]*\bdata-src\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
        dotAll: true,
      ),
      RegExp(
        r'''<img\b[^>]*\bdata-lazy-src\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
        dotAll: true,
      ),
      RegExp(
        r'''<img\b[^>]*\bdata-original\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
        dotAll: true,
      ),
    ];

    for (final patron in patrones) {
      final match = patron.firstMatch(html);

      if (match == null) {
        continue;
      }

      final url = match.group(1);

      if (_esUrlValida(url)) {
        return _normalizarUrl(url!);
      }
    }

    return null;
  }

  String? _normalizarUrl(String url) {
    final limpia = url.trim();

    if (limpia.startsWith('//')) {
      return 'https:$limpia';
    }

    return limpia;
  }

  bool _esUrlValida(String? url) {
    if (url == null) {
      return false;
    }

    final limpia = url.trim();

    return limpia.startsWith('http://') ||
        limpia.startsWith('https://') ||
        limpia.startsWith('//');
  }

  String? _limpiarTexto(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return null;
    }

    return texto
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}