enum CategoriaAviso {
  meteorologia,
  trafico,
  suministro,
  emergencia,
  transporte,
  ayuntamiento,
  otros,
}

enum NivelAviso {
  informativo,
  importante,
  urgente,
}

class Aviso {
  final String id;
  final String titulo;
  final String mensaje;

  final CategoriaAviso categoria;
  final NivelAviso nivel;

  final String fuente;
  final String? url;

  final DateTime fechaInicio;
  final DateTime fechaFin;

  final bool activo;

  final String creadoPor;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  const Aviso({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.categoria,
    required this.nivel,
    required this.fuente,
    this.url,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activo,
    required this.creadoPor,
    required this.creadoEn,
    this.actualizadoEn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'mensaje': mensaje,
      'categoria': categoria.name,
      'nivel': nivel.name,
      'fuente': fuente,
      'url': url,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'activo': activo,
      'creadoPor': creadoPor,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn?.toIso8601String(),
    };
  }

  factory Aviso.fromMap(Map<String, dynamic> map) {
    return Aviso(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      mensaje: map['mensaje'] as String,
      categoria: CategoriaAviso.values.firstWhere(
            (categoria) => categoria.name == map['categoria'],
        orElse: () => CategoriaAviso.otros,
      ),
      nivel: NivelAviso.values.firstWhere(
            (nivel) => nivel.name == map['nivel'],
        orElse: () => NivelAviso.informativo,
      ),
      fuente: map['fuente'] as String,
      url: map['url'] as String?,
      fechaInicio: DateTime.parse(map['fechaInicio'] as String),
      fechaFin: DateTime.parse(map['fechaFin'] as String),
      activo: map['activo'] as bool? ?? true,
      creadoPor: map['creadoPor'] as String,
      creadoEn: DateTime.parse(map['creadoEn'] as String),
      actualizadoEn: map['actualizadoEn'] != null
          ? DateTime.parse(map['actualizadoEn'] as String)
          : null,
    );
  }
}