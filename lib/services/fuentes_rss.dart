class FuenteRss {
  final String id;
  final String nombre;
  final String url;
  final String categoriaPorDefecto;
  final bool soloNovelda;

  const FuenteRss({
    required this.id,
    required this.nombre,
    required this.url,
    required this.categoriaPorDefecto,
    this.soloNovelda = true,
  });
}

class FuentesRss {
  static const List<FuenteRss> noticiasNovelda = [
    FuenteRss(
      id: 'el_periodic_novelda',
      nombre: 'El Periódico de Novelda',
      url: 'https://www.elperiodic.com/feed/rss_novelda.xml',
      categoriaPorDefecto: 'actualidad',
      soloNovelda: true,
    ),
    FuenteRss(
      id: 'novelda_digital',
      nombre: 'Novelda Digital',
      url: 'https://noveldadigital.es/feed/',
      categoriaPorDefecto: 'actualidad',
      soloNovelda: true,
    ),
    FuenteRss(
      id: 'vinalopo',
      nombre: 'Vinalopó.com',
      url: 'https://www.vinalopo.com/feed/',
      categoriaPorDefecto: 'actualidad',
      soloNovelda: true,
    ),
  ];
}