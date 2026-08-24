import 'package:flutter/material.dart';

import '../models/aviso.dart';

class AvisoPopup extends StatelessWidget {
  final Aviso aviso;

  const AvisoPopup({
    super.key,
    required this.aviso,
  });

  Color _colorNivel(BuildContext context) {
    switch (aviso.nivel) {
      case NivelAviso.urgente:
        return Colors.red;
      case NivelAviso.importante:
        return Colors.orange;
      case NivelAviso.informativo:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _iconoCategoria() {
    switch (aviso.categoria) {
      case CategoriaAviso.meteorologia:
        return Icons.thermostat_outlined;
      case CategoriaAviso.trafico:
        return Icons.traffic_outlined;
      case CategoriaAviso.suministro:
        return Icons.water_drop_outlined;
      case CategoriaAviso.emergencia:
        return Icons.warning_amber_rounded;
      case CategoriaAviso.transporte:
        return Icons.directions_bus_outlined;
      case CategoriaAviso.ayuntamiento:
        return Icons.account_balance_outlined;
      case CategoriaAviso.otros:
        return Icons.info_outline;
    }
  }

  String _textoNivel() {
    switch (aviso.nivel) {
      case NivelAviso.urgente:
        return 'AVISO URGENTE';
      case NivelAviso.importante:
        return 'AVISO IMPORTANTE';
      case NivelAviso.informativo:
        return 'INFORMACIÓN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorNivel(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconoCategoria(),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _textoNivel(),
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                aviso.titulo,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                aviso.mensaje,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.source_outlined,
                      size: 18,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fuente: ${aviso.fuente}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (aviso.url != null && aviso.url!.trim().isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text(
                        'Ver información',
                      ),
                    ),

                  const SizedBox(width: 8),

                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text(
                      'Cerrar',
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