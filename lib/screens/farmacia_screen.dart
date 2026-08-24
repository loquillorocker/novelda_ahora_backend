import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/farmacia_guardia.dart';
import '../services/firestore_farmacias_guardia_service.dart';

class FarmaciaScreen extends StatelessWidget {
  const FarmaciaScreen({super.key});

  Future<void> _abrirGoogleMaps(
      BuildContext context,
      FarmaciaGuardia farmacia,
      ) async {
    final consulta = Uri.encodeComponent(
      '${farmacia.nombreFarmacia}, '
          '${farmacia.direccion}, Novelda, Alicante',
    );

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$consulta',
    );

    try {
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abierto && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir Google Maps.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al abrir Google Maps: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Farmacia de guardia',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<FarmaciaGuardia?>(
        future: FirestoreFarmaciasGuardiaService()
            .obtenerFarmaciaDeGuardia(
          DateTime.now(),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar la farmacia de guardia:\n\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final farmacia = snapshot.data;

          if (farmacia == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay información de farmacia de guardia '
                      'para hoy.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.local_pharmacy_outlined,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Farmacia de guardia de hoy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmacia.nombreFarmacia,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                farmacia.direccion,
                                style: const TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_outlined,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                farmacia.horario,
                                style: const TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.tag_outlined,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'N.º farmacia: '
                                  '${farmacia.numeroFarmacia}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    _abrirGoogleMaps(
                      context,
                      farmacia,
                    );
                  },
                  icon: const Icon(
                    Icons.map_outlined,
                  ),
                  label: const Text(
                    'Cómo llegar',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}