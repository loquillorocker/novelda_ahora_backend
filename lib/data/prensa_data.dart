enum TipoPrensa {
  local,
  provincial,
  nacional,
}

class MedioPrensa {
  final String id;
  final String nombre;
  final String descripcion;
  final TipoPrensa tipo;
  final String url;
  final String? logoUrl;

  const MedioPrensa({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.url,
    this.logoUrl,
  });
}

class PrensaData {
  static const List<MedioPrensa> medios = [
    // =========================
    // PRENSA LOCAL
    // =========================

    MedioPrensa(
      id: 'novelda_digital',
      nombre: 'Novelda Digital',
      descripcion: 'Información local de Novelda',
      tipo: TipoPrensa.local,
      url: 'https://noveldadigital.es/',
    ),

    MedioPrensa(
      id: 'el_periodic_novelda',
      nombre: 'El Periódico de Novelda',
      descripcion: 'Actualidad local de Novelda',
      tipo: TipoPrensa.local,
      url: 'https://www.elperiodic.com/novelda',
    ),

    // =========================
    // PRENSA PROVINCIAL
    // =========================

    MedioPrensa(
      id: 'informacion',
      nombre: 'Información',
      descripcion: 'Diario de información de Alicante',
      tipo: TipoPrensa.provincial,
      url: 'https://www.informacion.es/',
    ),

    MedioPrensa(
      id: 'alicanteplaza',
      nombre: 'Alicante Plaza',
      descripcion: 'Actualidad de Alicante y su provincia',
      tipo: TipoPrensa.provincial,
      url: 'https://alicanteplaza.es/',
    ),

    // =========================
    // PRENSA NACIONAL
    // =========================

    MedioPrensa(
      id: '20minutos',
      nombre: '20minutos',
      descripcion: 'Información nacional e internacional',
      tipo: TipoPrensa.nacional,
      url: 'https://www.20minutos.es/',
    ),

    MedioPrensa(
      id: 'eldiario',
      nombre: 'elDiario.es',
      descripcion: 'Información nacional e internacional',
      tipo: TipoPrensa.nacional,
      url: 'https://www.eldiario.es/',
    ),

    MedioPrensa(
      id: 'publico',
      nombre: 'Público',
      descripcion: 'Información y actualidad nacional',
      tipo: TipoPrensa.nacional,
      url: 'https://www.publico.es/',
    ),

    MedioPrensa(
      id: 'vozpopuli',
      nombre: 'Vozpópuli',
      descripcion: 'Información nacional y económica',
      tipo: TipoPrensa.nacional,
      url: 'https://www.vozpopuli.com/',
    ),
  ];

  static List<MedioPrensa> porTipo(
      TipoPrensa tipo,
      ) {
    return medios
        .where(
          (medio) => medio.tipo == tipo,
    )
        .toList();
  }
}