class Fuente {
  final String id;
  final String nombre;
  final TipoFuente tipo;
  final String url;
  final String? rssUrl;
  final String? logoUrl;
  final bool activa;
  final int prioridad;
  final DateTime? ultimaActualizacion;

  const Fuente({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.url,
    this.rssUrl,
    this.logoUrl,
    this.activa = true,
    this.prioridad = 0,
    this.ultimaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo.name,
      'url': url,
      'rssUrl': rssUrl,
      'logoUrl': logoUrl,
      'activa': activa,
      'prioridad': prioridad,
      'ultimaActualizacion': ultimaActualizacion?.toIso8601String(),
    };
  }

  factory Fuente.fromMap(Map<String, dynamic> map) {
    return Fuente(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      tipo: TipoFuente.values.firstWhere(
            (tipo) => tipo.name == map['tipo'],
        orElse: () => TipoFuente.otra,
      ),
      url: map['url'] as String,
      rssUrl: map['rssUrl'] as String?,
      logoUrl: map['logoUrl'] as String?,
      activa: map['activa'] as bool? ?? true,
      prioridad: map['prioridad'] as int? ?? 0,
      ultimaActualizacion: map['ultimaActualizacion'] != null
          ? DateTime.parse(map['ultimaActualizacion'] as String)
          : null,
    );
  }
}

enum TipoFuente {
  prensa,
  radio,
  ayuntamiento,
  organismoPublico,
  facebook,
  web,
  otra,
}