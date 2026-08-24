import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'prensa_screen.dart';
import 'tiempo_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({
    super.key,
    required this.onSeleccion,
  });

  final void Function(String seccion) onSeleccion;

  void _seleccionar(
      BuildContext context,
      String seccion,
      ) {
    Navigator.pop(context);
    onSeleccion(seccion);
  }

  Future<Map<String, dynamic>?> _obtenerTiempo() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tiempo')
          .doc('novelda')
          .get();

      if (!snapshot.exists) {
        return null;
      }

      return snapshot.data();
    } catch (e) {
      debugPrint('===== ERROR TIEMPO MENU =====');
      debugPrint(e.toString());
      return null;
    }
  }

  int? _temperatura(dynamic valor) {
    if (valor is int) {
      return valor;
    }

    if (valor is double) {
      return valor.round();
    }

    if (valor is String) {
      return int.tryParse(valor);
    }

    return null;
  }

  String _obtenerEstadoCielo(dynamic valor) {
    if (valor is! List || valor.isEmpty) {
      return '';
    }

    for (final estado in valor) {
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

  void _abrirTiempo(BuildContext context) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TiempoScreen(),
      ),
    );
  }

  void _abrirPrensa(BuildContext context) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrensaScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Novelda Ahora',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ─────────────────────────────────────
            // TIEMPO
            // ─────────────────────────────────────

            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                0,
                12,
                10,
              ),
              child: FutureBuilder<Map<String, dynamic>?>(
                future: _obtenerTiempo(),
                builder: (context, snapshot) {
                  return _buildTarjetaTiempo(
                    context,
                    snapshot,
                  );
                },
              ),
            ),

            const Divider(
              height: 1,
            ),

            // ─────────────────────────────────────
            // PRINCIPAL
            // ─────────────────────────────────────

            ListTile(
              leading: const Icon(
                Icons.home_outlined,
              ),
              title: const Text('Inicio'),
              onTap: () => _seleccionar(
                context,
                'inicio',
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.article_outlined,
              ),
              title: const Text(
                'Noticias de Novelda',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _seleccionar(
                context,
                'noticias',
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.newspaper_outlined,
              ),
              title: const Text('Prensa'),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _abrirPrensa(
                context,
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.video_library_outlined,
              ),
              title: const Text('Vídeos'),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _seleccionar(
                context,
                'videos',
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.radio_outlined,
              ),
              title: const Text('Radio'),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _seleccionar(
                context,
                'radio',
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.local_pharmacy_outlined,
              ),
              title: const Text(
                'Farmacia de guardia',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _seleccionar(
                context,
                'farmacia',
              ),
            ),

            const Divider(
              height: 20,
            ),

            // ─────────────────────────────────────
            // DESCUBRE NOVELDA
            // ─────────────────────────────────────

            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                4,
              ),
              child: Text(
                'Descubre Novelda',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.event_outlined,
              ),
              title: const Text('Agenda'),
              onTap: () => _seleccionar(
                context,
                'agenda',
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.restaurant_outlined,
              ),
              title: const Text('Gastronomía'),
              onTap: () => _seleccionar(
                context,
                'gastronomia',
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.local_activity_outlined,
              ),
              title: const Text('Ocio'),
              onTap: () => _seleccionar(
                context,
                'ocio',
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.museum_outlined,
              ),
              title: const Text('Cultura'),
              onTap: () => _seleccionar(
                context,
                'cultura',
              ),
            ),

            ListTile(
              leading: const Icon(
                Icons.miscellaneous_services_outlined,
              ),
              title: const Text('Servicios'),
              onTap: () => _seleccionar(
                context,
                'servicios',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaTiempo(
      BuildContext context,
      AsyncSnapshot<Map<String, dynamic>?> snapshot,
      ) {
    final theme = Theme.of(context);

    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return Card(
        elevation: 1,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Cargando tiempo...',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = snapshot.data;

    if (data == null) {
      return Card(
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrirTiempo(context),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 32,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiempo en Novelda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Consulta la previsión meteorológica',
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    }

    final diaria = data['diaria'];

    if (diaria is! List || diaria.isEmpty) {
      return Card(
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrirTiempo(context),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 32,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiempo en Novelda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Previsión meteorológica',
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    }

    final hoy = diaria.first;

    if (hoy is! Map) {
      return Card(
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _abrirTiempo(context),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 32,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Tiempo en Novelda',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    }

    final dia = Map<String, dynamic>.from(hoy);

    final maxima = _temperatura(
      dia['maxima'],
    );

    final minima = _temperatura(
      dia['minima'],
    );

    final estado = _obtenerEstadoCielo(
      dia['estadoCielo'],
    );

    final icono = _iconoTiempo(estado);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirTiempo(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            14,
            12,
            14,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icono,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tiempo en Novelda',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment:
                CrossAxisAlignment.center,
                children: [
                  Text(
                    maxima != null
                        ? '$maxima°'
                        : '--°',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          estado.isNotEmpty
                              ? estado
                              : 'Previsión meteorológica',
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Máx. '
                              '${maxima != null ? '$maxima°' : '--'}'
                              '  ·  '
                              'Mín. '
                              '${minima != null ? '$minima°' : '--'}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                            color: theme.colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}