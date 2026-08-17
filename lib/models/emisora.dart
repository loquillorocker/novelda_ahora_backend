enum TipoEmisora {
  publica,
  informativa,
  local,
  musical,
  cultural,
}

enum CoberturaEmisora {
  nacional,
  provincial,
  comarcal,
  local,
}

class Emisora {
  final String id;
  final String nombre;
  final String descripcion;
  final TipoEmisora tipo;
  final CoberturaEmisora cobertura;
  final String? localidad;
  final String urlWeb;
  final String? urlStreaming;
  final String? urlFeed;
  final String? logoUrl;
  final bool activa;

  const Emisora({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.cobertura,
    this.localidad,
    required this.urlWeb,
    this.urlStreaming,
    this.urlFeed,
    this.logoUrl,
    this.activa = true,
  });
}