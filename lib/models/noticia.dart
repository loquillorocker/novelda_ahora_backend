enum TipoContenido {
  noticia,
  video,
  aviso,
  suceso,
  evento,
  farmacia,
  deporte,
}

enum CategoriaNoticia {
  actualidad,
  sucesos,
  politica,
  sociedad,
  cultura,
  fiestas,
  deportes,
  economia,
  educacion,
  salud,
  servicios,
  medioAmbiente,
  trafico,
  agenda,
}

class Noticia {
  final String id;
  final String titulo;
  final String resumen;
  final String? contenido;

  final TipoContenido tipo;
  final CategoriaNoticia categoria;

  final String fuenteId;
  final String fuenteNombre;
  final String urlOriginal;

  final String? imagenUrl;
  final String? videoUrl;

  final DateTime fechaPublicacion;
  final DateTime fechaCaptura;

  final String? autor;
  final String? ubicacion;

  final bool destacada;
  final bool activa;

  final List<String> etiquetas;

  const Noticia({
    required this.id,
    required this.titulo,
    required this.resumen,
    this.contenido,
    required this.tipo,
    required this.categoria,
    required this.fuenteId,
    required this.fuenteNombre,
    required this.urlOriginal,
    this.imagenUrl,
    this.videoUrl,
    required this.fechaPublicacion,
    required this.fechaCaptura,
    this.autor,
    this.ubicacion,
    this.destacada = false,
    this.activa = true,
    this.etiquetas = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'resumen': resumen,
      'contenido': contenido,
      'tipo': tipo.name,
      'categoria': categoria.name,
      'fuenteId': fuenteId,
      'fuenteNombre': fuenteNombre,
      'urlOriginal': urlOriginal,
      'imagenUrl': imagenUrl,
      'videoUrl': videoUrl,
      'fechaPublicacion': fechaPublicacion.toIso8601String(),
      'fechaCaptura': fechaCaptura.toIso8601String(),
      'autor': autor,
      'ubicacion': ubicacion,
      'destacada': destacada,
      'activa': activa,
      'etiquetas': etiquetas,
    };
  }

  factory Noticia.fromMap(Map<String, dynamic> map) {
    return Noticia(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      resumen: map['resumen'] as String,
      contenido: map['contenido'] as String?,
      tipo: TipoContenido.values.firstWhere(
            (tipo) => tipo.name == map['tipo'],
        orElse: () => TipoContenido.noticia,
      ),
      categoria: CategoriaNoticia.values.firstWhere(
            (categoria) => categoria.name == map['categoria'],
        orElse: () => CategoriaNoticia.actualidad,
      ),
      fuenteId: map['fuenteId'] as String,
      fuenteNombre: map['fuenteNombre'] as String,
      urlOriginal: map['urlOriginal'] as String,
      imagenUrl: map['imagenUrl'] as String?,
      videoUrl: map['videoUrl'] as String?,
      fechaPublicacion: DateTime.parse(map['fechaPublicacion'] as String),
      fechaCaptura: DateTime.parse(map['fechaCaptura'] as String),
      autor: map['autor'] as String?,
      ubicacion: map['ubicacion'] as String?,
      destacada: map['destacada'] as bool? ?? false,
      activa: map['activa'] as bool? ?? true,
      etiquetas: List<String>.from(map['etiquetas'] ?? const []),
    );
  }
}