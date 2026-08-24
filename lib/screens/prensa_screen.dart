import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/prensa_data.dart';

class PrensaScreen extends StatelessWidget {
  const PrensaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prensa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          _buildIntro(context),
          const SizedBox(height: 24),

          _buildSeccion(
            context,
            titulo: 'Prensa local',
            subtitulo: 'Medios de información de Novelda',
            icono: Icons.location_city_outlined,
            tipo: TipoPrensa.local,
          ),

          const SizedBox(height: 28),

          _buildSeccion(
            context,
            titulo: 'Prensa provincial',
            subtitulo: 'Medios de información de Alicante',
            icono: Icons.map_outlined,
            tipo: TipoPrensa.provincial,
          ),

          const SizedBox(height: 28),

          _buildSeccion(
            context,
            titulo: 'Prensa nacional',
            subtitulo: 'Medios de información de ámbito nacional',
            icono: Icons.public_outlined,
            tipo: TipoPrensa.nacional,
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prensa',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Accede directamente a medios de información local, '
              'provincial y nacional.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSeccion(
      BuildContext context, {
        required String titulo,
        required String subtitulo,
        required IconData icono,
        required TipoPrensa tipo,
      }) {
    final theme = Theme.of(context);
    final medios = PrensaData.porTipo(tipo);

    if (medios.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...medios.map(
              (medio) => Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: _MedioPrensaCard(
              medio: medio,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedioPrensaCard extends StatelessWidget {
  const _MedioPrensaCard({
    required this.medio,
  });

  final MedioPrensa medio;

  Future<void> _abrir(BuildContext context) async {
    final uri = Uri.tryParse(
      medio.url,
    );

    if (uri == null) {
      _mostrarError(context);
      return;
    }

    try {
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abierto && context.mounted) {
        _mostrarError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _mostrarError(context);
      }
    }
  }

  void _mostrarError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se pudo abrir el medio de comunicación.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrir(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: medio.logoUrl != null &&
                    medio.logoUrl!.trim().isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    medio.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (
                        context,
                        error,
                        stackTrace,
                        ) {
                      return Icon(
                        Icons.article_outlined,
                        size: 28,
                        color: theme.colorScheme.primary,
                      );
                    },
                  ),
                )
                    : Icon(
                  Icons.article_outlined,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      medio.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medio.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new,
                size: 19,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}