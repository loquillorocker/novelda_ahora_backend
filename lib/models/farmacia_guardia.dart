class FarmaciaGuardia {
  final DateTime fecha;
  final int zona;
  final String turno;
  final String numeroFarmacia;
  final String nombreFarmacia;
  final String direccion;
  final String municipio;
  final String horario;

  const FarmaciaGuardia({
    required this.fecha,
    required this.zona,
    required this.turno,
    required this.numeroFarmacia,
    required this.nombreFarmacia,
    required this.direccion,
    required this.municipio,
    required this.horario,
  });

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha,
      'zona': zona,
      'turno': turno,
      'numeroFarmacia': numeroFarmacia,
      'nombreFarmacia': nombreFarmacia,
      'direccion': direccion,
      'municipio': municipio,
      'horario': horario,
    };
  }

  factory FarmaciaGuardia.fromMap(Map<String, dynamic> map) {
    return FarmaciaGuardia(
      fecha: (map['fecha'] as dynamic).toDate(),
      zona: (map['zona'] as num).toInt(),
      turno: map['turno'] as String,
      numeroFarmacia: map['numeroFarmacia'] as String,
      nombreFarmacia: map['nombreFarmacia'] as String,
      direccion: map['direccion'] as String,
      municipio: map['municipio'] as String,
      horario: map['horario'] as String,
    );
  }
}