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
  static const String _cloudinaryCloudName = 'gg9ef0fm';

  static const Duration _timeout = Duration(seconds: 10);

  Future<List<NoticiaRss>> obtenerItems(
      String rssUrl,
      ) async {
    final uri = Uri.parse(rssUrl);

    final usaImagenOriginal =
    rssUrl.contains('vinalopo.com');

    late http.Response respuesta;

    try {
      respuesta = await http
          .get(
        uri,
        headers: const {
          'User-Agent': 'NoveldaAhora/1.0',
          'Accept':
          'application/rss+xml, application/xml, text/xml, */*',
        },
      )
          .timeout(_timeout);
    } catch (e) {
      throw Exception(
        'No se pudo descargar el RSS: $rssUrl',
      );
    }

    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudo obtener el RSS. '
            'Código HTTP: ${respuesta.statusCode}',
      );
    }

    final xml = respuesta.body.trim();

    if (xml.isEmpty) {
      throw Exception(
        'La fuente RSS devolvió una respuesta vacía.',
      );
    }

    if (!xml.startsWith('<')) {
      throw Exception(
        'La fuente no está devolviendo XML/RSS. '
            'Contenido recibido: '
            '${xml.substring(
          0,
          xml.length > 200 ? 200 : xml.length,
        )}',
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

      final bloqueItem = _buscarBloqueItem(
        xml,
        url,
        titulo,
      );

      final contenidoHtml =
      _extraerContenidoEncoded(bloqueItem);

      final imagen = _extraerImagen(
        bloqueItem: bloqueItem,
        descripcion: descripcion,
        contenidoHtml: contenidoHtml,
      );

      final imagenFinal = usaImagenOriginal
          ? imagen
          : _convertirImagenCloudinary(imagen);

      resultado.add(
        NoticiaRss(
          titulo: titulo,
          resumen: _limpiarTexto(
            descripcion ?? contenidoHtml,
          ),
          url: url,
          fechaPublicacion: item.pubDate,
          autor: item.author?.trim(),
          imagenUrl: imagenFinal,
        ),
      );
    }

    return resultado;
  }

  String? _convertirImagenCloudinary(
      String? url,
      ) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    final limpia = url.trim();

    if (limpia.contains('res.cloudinary.com/')) {
      return limpia;
    }

    if (!limpia.startsWith('http://') &&
        !limpia.startsWith('https://')) {
      return limpia;
    }

    final encodedUrl = Uri.encodeComponent(limpia);

    return 'https://res.cloudinary.com/'
        '$_cloudinaryCloudName/image/fetch/'
        '$encodedUrl';
  }

  String? _extraerImagen({
    required String? bloqueItem,
    required String? descripcion,
    required String? contenidoHtml,
  }) {
    final imagenDescripcion =
    _extraerImagenDeHtml(descripcion);

    if (imagenDescripcion != null) {
      return imagenDescripcion;
    }

    final imagenContenido =
    _extraerImagenDeHtml(contenidoHtml);

    if (imagenContenido != null) {
      return imagenContenido;
    }

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

    final imagenHtmlItem =
    _extraerImagenDeHtml(bloqueItem);

    if (imagenHtmlItem != null) {
      return imagenHtmlItem;
    }

    final imagenHref = _extraerAtributoHref(
      bloqueItem,
      'media:content',
    );

    if (imagenHref != null) {
      return imagenHref;
    }

    final thumbnailHref = _extraerAtributoHref(
      bloqueItem,
      'media:thumbnail',
    );

    if (thumbnailHref != null) {
      return thumbnailHref;
    }

    return null;
  }

  String? _buscarBloqueItem(
      String xml,
      String urlNoticia,
      String titulo,
      ) {
    final items = RegExp(
      r'<item\b[^>]*>.*?</item>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(xml);

    final urlNormalizada =
    _decodificarXml(urlNoticia.trim());

    final tituloNormalizado =
    _decodificarXml(titulo.trim());

    for (final match in items) {
      final bloque = match.group(0);

      if (bloque == null) {
        continue;
      }

      final bloqueNormalizado =
      _decodificarXml(bloque);

      if (bloqueNormalizado.contains(
        urlNormalizada,
      )) {
        return bloque;
      }

      if (bloqueNormalizado.contains(
        tituloNormalizado,
      )) {
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

    return _normalizarUrl(
      _decodificarXml(url!),
    );
  }

  String? _extraerAtributoHref(
      String xml,
      String etiqueta,
      ) {
    final patron = RegExp(
      '<$etiqueta\\b[^>]*\\bhref\\s*=\\s*[\'"]([^\'"]+)[\'"]',
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

    return _normalizarUrl(
      _decodificarXml(url!),
    );
  }

  String? _extraerContenidoEncoded(
      String? bloqueItem,
      ) {
    if (bloqueItem == null ||
        bloqueItem.trim().isEmpty) {
      return null;
    }

    final patron = RegExp(
      r'<content:encoded\b[^>]*>(.*?)</content:encoded>',
      caseSensitive: false,
      dotAll: true,
    );

    final match = patron.firstMatch(
      bloqueItem,
    );

    if (match == null) {
      return null;
    }

    return _decodificarXml(
      match.group(1) ?? '',
    );
  }

  String? _extraerImagenDeHtml(
      String? html,
      ) {
    if (html == null ||
        html.trim().isEmpty) {
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
      RegExp(
        r'''<img\b[^>]*\bsrcset\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
        dotAll: true,
      ),
    ];

    for (final patron in patrones) {
      final match = patron.firstMatch(html);

      if (match == null) {
        continue;
      }

      var url = match.group(1);

      if (url == null) {
        continue;
      }

      url = _decodificarXml(
        url.trim(),
      );

      if (url.contains(',')) {
        url = url.split(',').first.trim();
      }

      final partes = url.split(' ');

      if (partes.isNotEmpty) {
        url = partes.first.trim();
      }

      if (_esUrlValida(url)) {
        return _normalizarUrl(url);
      }
    }

    return null;
  }

  String? _normalizarUrl(
      String url,
      ) {
    final limpia = url.trim();

    if (limpia.startsWith('//')) {
      return 'https:$limpia';
    }

    return limpia;
  }

  bool _esUrlValida(
      String? url,
      ) {
    if (url == null) {
      return false;
    }

    final limpia = url.trim();

    return limpia.startsWith('http://') ||
        limpia.startsWith('https://') ||
        limpia.startsWith('//');
  }

  String _decodificarXml(
      String texto,
      ) {
    return texto
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  String? _limpiarTexto(
      String? texto,
      ) {
    if (texto == null ||
        texto.trim().isEmpty) {
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