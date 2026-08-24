import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/farmacia_guardia.dart';

class FirestoreFarmaciasGuardiaService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _farmacias =>
      _firestore.collection('farmacias_guardia');

  Future<FarmaciaGuardia?> obtenerFarmaciaDeGuardia(
      DateTime fecha,
      ) async {
    final inicio = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    );

    final fin = inicio.add(const Duration(days: 1));

    final snapshot = await _farmacias
        .where(
      'fecha',
      isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
    )
        .where(
      'fecha',
      isLessThan: Timestamp.fromDate(fin),
    )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return FarmaciaGuardia.fromMap(
      snapshot.docs.first.data(),
    );
  }

  Future<void> cargarGuardiasIniciales() async {
    final batch = _firestore.batch();

    final farmacias = {
      '01': {
        'numeroFarmacia': '120250',
        'nombreFarmacia': 'SEGURA BELTRA, MARIA',
        'direccion': 'C/ COLON, 17 BAJO',
      },
      '02': {
        'numeroFarmacia': '110067',
        'nombreFarmacia': 'VALLEJO RAMOS, JAIME',
        'direccion': 'C/ MAYOR, Nº2',
      },
      '03': {
        'numeroFarmacia': '100400',
        'nombreFarmacia':
        'ESTEBANEZ CONSUEGRA, JUAN FRANCISCO',
        'direccion': 'C/ CERVANTES, Nº45',
      },
      '04': {
        'numeroFarmacia': '100068',
        'nombreFarmacia': 'CASTAÑO DIEZ, JUAN ANTONIO',
        'direccion': 'C/ MARIA CRISTINA, Nº113',
      },
      '05': {
        'numeroFarmacia': '100636',
        'nombreFarmacia':
        'OJEDA JOVER, JOSE IGNACIO',
        'direccion': 'AV. DE LA CONSTITUCION, Nº41',
      },
      '06': {
        'numeroFarmacia': '110704',
        'nombreFarmacia': 'CLIMENT GINER, MANUEL',
        'direccion': 'C/ MARIA CRISTINA, Nº54',
      },
      '07': {
        'numeroFarmacia': '100301',
        'nombreFarmacia': 'GARCIA MONGARS, ANDRES',
        'direccion': 'AV. REYES CATOLICOS, Nº85',
      },
      '08': {
        'numeroFarmacia': '110006',
        'nombreFarmacia':
        'HEREDEROS DE JUAN JAVIER DEL RIO SALANOVA',
        'direccion': 'C/ EMILIO CASTELAR, Nº37',
      },
      '09': {
        'numeroFarmacia': '100721',
        'nombreFarmacia': 'RODA FONOLLOSA, GLORIA',
        'direccion':
        'C/ TIRSO DE MOLINA, Nº52 BJ-ACCESO EN C/VIRIATO',
      },
    };

    final fechasTurno = <String, String>{
      '2026-08-18': '02',
      '2026-08-19': '05',
      '2026-08-20': '07',
      '2026-08-21': '08',
      '2026-08-22': '01',
      '2026-08-23': '02',
      '2026-08-24': '03',
      '2026-08-25': '04',
      '2026-08-26': '05',
      '2026-08-27': '07',
      '2026-08-28': '08',
      '2026-08-29': '09',
      '2026-08-30': '01',
      '2026-08-31': '02',
    };

    DateTime fecha = DateTime(2026, 9, 1);
    final fechaFinal = DateTime(2026, 12, 31);

    const secuencia = [
      '06',
      '07',
      '08',
      '09',
      '01',
      '02',
      '03',
      '04',
      '05',
    ];

    int indice = 0;

    while (!fecha.isAfter(fechaFinal)) {
      final clave =
          '${fecha.year.toString().padLeft(4, '0')}-'
          '${fecha.month.toString().padLeft(2, '0')}-'
          '${fecha.day.toString().padLeft(2, '0')}';

      fechasTurno[clave] = secuencia[indice];

      indice++;

      if (indice >= secuencia.length) {
        indice = 0;
      }

      fecha = fecha.add(
        const Duration(days: 1),
      );
    }

    DateTime fechaActual = DateTime(2026, 8, 18);

    while (!fechaActual.isAfter(fechaFinal)) {
      final clave =
          '${fechaActual.year.toString().padLeft(4, '0')}-'
          '${fechaActual.month.toString().padLeft(2, '0')}-'
          '${fechaActual.day.toString().padLeft(2, '0')}';

      final turno = fechasTurno[clave]!;

      final datosFarmacia = farmacias[turno]!;

      final farmacia = FarmaciaGuardia(
        fecha: fechaActual,
        zona: 62,
        turno: turno,
        numeroFarmacia:
        datosFarmacia['numeroFarmacia'] as String,
        nombreFarmacia:
        datosFarmacia['nombreFarmacia'] as String,
        direccion:
        datosFarmacia['direccion'] as String,
        municipio: 'Novelda',
        horario: 'De 9:30 a 9:30',
      );

      final referencia = _farmacias.doc(clave);

      batch.set(
        referencia,
        farmacia.toMap(),
        SetOptions(merge: true),
      );

      fechaActual = fechaActual.add(
        const Duration(days: 1),
      );
    }

    await batch.commit();
  }
}