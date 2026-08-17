class FuenteRss {
  final String id;
  final String nombre;
  final String url;
  final String categoriaPorDefecto;

  const FuenteRss({
    required this.id,
    required this.nombre,
    required this.url,
    required this.categoriaPorDefecto,
  });
}

class FuentesRss {
  static const List<FuenteRss> todas = [
    FuenteRss(
      id: 'el_periodic_novelda',
      nombre: 'El Periódico de Novelda',
      url: 'https://www.elperiodic.com/feed/rss_novelda.xml',
      categoriaPorDefecto: 'actualidad',
    ),
    FuenteRss(
      id: 'novelda_digital',
      nombre: 'Novelda Digital',
      url: 'https://noveldadigital.es/feed/',
      categoriaPorDefecto: 'actualidad',
    ),
  ];
}