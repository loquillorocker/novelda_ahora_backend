import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TiempoScreen extends StatefulWidget {
  const TiempoScreen({super.key});

  @override
  State<TiempoScreen> createState() => _TiempoScreenState();
}

class _TiempoScreenState extends State<TiempoScreen> {
  Future<DocumentSnapshot<Map<String, dynamic>>>? _futureTiempo;

  @override
  void initState() {
    super.initState();
    _cargarTiempo();
  }

  void _cargarTiempo() {
    setState(() {
      _futureTiempo = FirebaseFirestore.instance
          .collection('tiempo')
          .doc('novelda')
          .get();
    });
  }

  Future<void> _refrescarTiempo() async {
    try {
      final resultado = await FirebaseFirestore.instance
          .collection('tiempo')
          .doc('novelda')
          .get(
        const GetOptions(
          source: Source.server,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _futureTiempo = Future.value(resultado);
      });
    } catch (e) {
      debugPrint('===== ERROR TIEMPO =====');
      debugPrint(e.toString());

      if (!mounted) {
        return;
      }

      setState(() {
        _futureTiempo = Future.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiempo en Novelda',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _futureTiempo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            debugPrint('===== ERROR LECTURA TIEMPO =====');
            debugPrint(snapshot.error.toString());

            return _buildError(
              context,
              'No se ha podido cargar la información meteorológica.',
            );
          }

          if (!snapshot.hasData) {
            return _buildError(
              context,
              'No se ha podido obtener la información meteorológica.',
            );
          }

          final documento = snapshot.data!;

          debugPrint('===== FIRESTORE TIEMPO =====');
          debugPrint('Existe documento: ${documento.exists}');
          debugPrint('ID documento: ${documento.id}');

          if (!documento.exists) {
            debugPrint('El documento tiempo/novelda NO existe.');

            return _buildError(
              context,
              'Todavía no hay información meteorológica disponible.',
            );
          }

          final data = documento.data();

          debugPrint('Campos recibidos: ${data?.keys.toList()}');

          if (data == null) {
            debugPrint('El documento existe pero data() es null.');

            return _buildError(
              context,
              'No hay datos meteorológicos disponibles.',
            );
          }

          final diaria = _convertirLista(data['diaria']);
          final horaria = _convertirLista(data['horaria']);

          debugPrint(
            'Días de previsión recibidos: ${diaria.length}',
          );

          debugPrint(
            'Bloques horarios recibidos: ${horaria.length}',
          );

          if (diaria.isEmpty) {
            debugPrint(
              'El campo diaria existe pero está vacío o no tiene el formato esperado.',
            );

            return _buildError(
              context,
              'AEMET todavía no ha proporcionado la previsión.',
            );
          }

          return _buildContenido(
            context,
            diaria,
            horaria,
          );
        },
      ),
    );
  }

  Widget _buildContenido(
      BuildContext context,
      List<Map<String, dynamic>> dias,
      List<Map<String, dynamic>> horaria,
      ) {
    final hoy = dias.first;

    final temperaturaActual = _obtenerTemperaturaActual(
      horaria,
    );

    final maxima = _obtenerMaxima(hoy);
    final minima = _obtenerMinima(hoy);

    final estado = _obtenerEstadoCielo(
      hoy,
    );

    return RefreshIndicator(
      onRefresh: _refrescarTiempo,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          _buildCurrentWeather(
            context,
            hoy,
            temperaturaActual,
            maxima,
            minima,
            estado,
          ),
          const SizedBox(height: 24),
          Text(
            'Previsión',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < dias.length && i < 7; i++) ...[
            _buildForecastCard(
              context,
              dias[i],
              i,
            ),
            if (i < dias.length - 1 && i < 6)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(
      BuildContext context,
      Map<String, dynamic> dia,
      int? temperaturaActual,
      int? maxima,
      int? minima,
      String estado,
      ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Novelda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Previsión de hoy',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconoTiempo(estado),
                  size: 58,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 18),
                Text(
                  temperaturaActual != null
                      ? '$temperaturaActual°'
                      : '--°',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              estado.isNotEmpty
                  ? estado
                  : 'Previsión meteorológica',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WeatherData(
                  icon: Icons.arrow_upward,
                  label: 'Máxima',
                  value: maxima != null ? '$maxima°' : '--',
                ),
                _WeatherData(
                  icon: Icons.arrow_downward,
                  label: 'Mínima',
                  value: minima != null ? '$minima°' : '--',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(
      BuildContext context,
      Map<String, dynamic> dia,
      int indice,
      ) {
    final fecha = _parsearFecha(dia['fecha']);
    final maxima = _obtenerMaxima(dia);
    final minima = _obtenerMinima(dia);
    final estado = _obtenerEstadoCielo(dia);

    return Card(
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          child: Icon(
            _iconoTiempo(estado),
          ),
        ),
        title: Text(
          _nombreDia(fecha, indice),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          estado.isNotEmpty
              ? estado
              : 'Previsión meteorológica',
        ),
        trailing: Text(
          '${maxima != null ? '$maxima°' : '--'}'
              ' / '
              '${minima != null ? '$minima°' : '--'}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _convertirLista(dynamic valor) {
    if (valor is! List) {
      return [];
    }

    return valor
        .whereType<Map>()
        .map(
          (elemento) => Map<String, dynamic>.from(elemento),
    )
        .toList();
  }

  int? _temperatura(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is double) {
      return valor.round();
    }

    if (valor is num) {
      return valor.round();
    }

    if (valor is String) {
      return int.tryParse(valor);
    }

    return null;
  }

  int? _obtenerMaxima(Map<String, dynamic> dia) {
    // Primero intentamos el campo directo.
    final directa = _temperatura(dia['maxima']);

    if (directa != null) {
      return directa;
    }

    // En los datos actuales de AEMET,
    // maxima/minima están dentro de humedadRelativa.
    final humedad = dia['humedadRelativa'];

    if (humedad is Map) {
      return _temperatura(humedad['maxima']);
    }

    return null;
  }

  int? _obtenerMinima(Map<String, dynamic> dia) {
    // Primero intentamos el campo directo.
    final directa = _temperatura(dia['minima']);

    if (directa != null) {
      return directa;
    }

    // En los datos actuales de AEMET,
    // maxima/minima están dentro de humedadRelativa.
    final humedad = dia['humedadRelativa'];

    if (humedad is Map) {
      return _temperatura(humedad['minima']);
    }

    return null;
  }

  int? _obtenerTemperaturaActual(
      List<Map<String, dynamic>> horaria,
      ) {
    if (horaria.isEmpty) {
      return null;
    }

    final ahora = DateTime.now();

    // Buscamos el bloque horario correspondiente a hoy.
    Map<String, dynamic>? bloqueHoy;

    for (final bloque in horaria) {
      final fecha = _parsearFecha(bloque['fecha']);

      if (fecha == null) {
        continue;
      }

      if (fecha.year == ahora.year &&
          fecha.month == ahora.month &&
          fecha.day == ahora.day) {
        bloqueHoy = bloque;
        break;
      }
    }

    // Si no encontramos el bloque de hoy,
    // usamos el primero disponible.
    bloqueHoy ??= horaria.first;

    final temperaturas = bloqueHoy['temperatura'];

    if (temperaturas is! List || temperaturas.isEmpty) {
      return null;
    }

    int? mejorTemperatura;
    int? mejorDiferencia;

    for (final elemento in temperaturas) {
      if (elemento is! Map) {
        continue;
      }

      final periodo = elemento['periodo'];

      if (periodo == null) {
        continue;
      }

      final hora = int.tryParse(
        periodo.toString(),
      );

      if (hora == null) {
        continue;
      }

      final temperatura = _temperatura(
        elemento['value'],
      );

      if (temperatura == null) {
        continue;
      }

      final diferencia = (hora - ahora.hour).abs();

      if (mejorDiferencia == null ||
          diferencia < mejorDiferencia) {
        mejorDiferencia = diferencia;
        mejorTemperatura = temperatura;
      }
    }

    return mejorTemperatura;
  }

  DateTime? _parsearFecha(dynamic valor) {
    if (valor is! String || valor.isEmpty) {
      return null;
    }

    return DateTime.tryParse(valor);
  }

  String _nombreDia(
      DateTime? fecha,
      int indice,
      ) {
    if (fecha == null) {
      if (indice == 0) {
        return 'Hoy';
      }

      if (indice == 1) {
        return 'Mañana';
      }

      return 'Próximos días';
    }

    final ahora = DateTime.now();

    final fechaHoy = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    final fechaDia = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    );

    final diferencia =
        fechaDia.difference(fechaHoy).inDays;

    if (diferencia == 0) {
      return 'Hoy';
    }

    if (diferencia == 1) {
      return 'Mañana';
    }

    const nombres = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    return nombres[fecha.weekday - 1];
  }

  String _obtenerEstadoCielo(
      Map<String, dynamic> dia,
      ) {
    final estados = dia['estadoCielo'];

    if (estados is! List || estados.isEmpty) {
      return '';
    }

    // Preferimos el periodo 00-24 porque representa
    // el estado general del día.
    for (final estado in estados) {
      if (estado is! Map) {
        continue;
      }

      final periodo = estado['periodo']?.toString();

      if (periodo == '00-24') {
        final descripcion =
            estado['descripcion'] ??
                estado['value'] ??
                estado['#text'];

        if (descripcion != null &&
            descripcion.toString().trim().isNotEmpty) {
          return descripcion.toString().trim();
        }
      }
    }

    // Si no existe 00-24, buscamos cualquier descripción válida.
    for (final estado in estados) {
      if (estado is Map) {
        final descripcion =
            estado['descripcion'] ??
                estado['value'] ??
                estado['#text'];

        if (descripcion != null &&
            descripcion.toString().trim().isNotEmpty) {
          return descripcion.toString().trim();
        }
      }

      if (estado is String &&
          estado.trim().isNotEmpty) {
        return estado.trim();
      }
    }

    return '';
  }

  IconData _iconoTiempo(String estado) {
    final texto = estado.toLowerCase();

    if (texto.contains('torment')) {
      return Icons.thunderstorm_outlined;
    }

    if (texto.contains('lluvia')) {
      return Icons.umbrella_outlined;
    }

    if (texto.contains('niebla')) {
      return Icons.foggy;
    }

    // Tiene que ir antes de "nuboso".
    if (texto.contains('poco nuboso')) {
      return Icons.wb_cloudy_outlined;
    }

    if (texto.contains('muy nuboso')) {
      return Icons.cloud_outlined;
    }

    if (texto.contains('nublado')) {
      return Icons.cloud_outlined;
    }

    if (texto.contains('nuboso')) {
      return Icons.cloud_outlined;
    }

    if (texto.contains('despejado')) {
      return Icons.wb_sunny_outlined;
    }

    return Icons.wb_sunny_outlined;
  }

  Widget _buildError(
      BuildContext context,
      String mensaje,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _cargarTiempo,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherData extends StatelessWidget {
  const _WeatherData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}