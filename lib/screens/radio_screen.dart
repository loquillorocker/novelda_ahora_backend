import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/emisoras_data.dart';
import '../models/emisora.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _emisoraActualId;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Emisora> emisoras = EmisorasData.emisoras
        .where((emisora) => emisora.activa)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Radio',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
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
          _buildCategoria(
            context,
            'Información',
            'Actualidad y noticias de Alicante y provincia.',
            TipoEmisora.informativa,
            emisoras,
          ),
          _buildCategoria(
            context,
            'Radio pública',
            'Información, actualidad y contenidos de RNE.',
            TipoEmisora.publica,
            emisoras,
          ),
          _buildCategoria(
            context,
            'Cultura',
            'Música y contenidos culturales.',
            TipoEmisora.cultural,
            emisoras,
          ),
          _buildCategoria(
            context,
            'Radios locales',
            'Emisoras del entorno de Novelda y el Medio Vinalopó.',
            TipoEmisora.local,
            emisoras,
          ),
          _buildCategoria(
            context,
            'Música',
            'Emisoras para escuchar música y entretenimiento.',
            TipoEmisora.musical,
            emisoras,
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
          'Radio',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Escucha emisoras de Novelda, el Medio Vinalopó y la provincia de Alicante.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoria(
      BuildContext context,
      String titulo,
      String descripcion,
      TipoEmisora tipo,
      List<Emisora> emisoras,
      ) {
    final emisorasCategoria =
    emisoras.where((emisora) => emisora.tipo == tipo).toList();

    if (emisorasCategoria.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...emisorasCategoria.map(
                (emisora) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildEmisoraCard(
                context,
                emisora,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmisoraCard(
      BuildContext context,
      Emisora emisora,
      ) {
    final theme = Theme.of(context);

    final bool esActual = _emisoraActualId == emisora.id;

    final bool tieneStreaming =
        emisora.urlStreaming != null &&
            emisora.urlStreaming!.trim().isNotEmpty;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirWeb(emisora),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconoTipo(emisora.tipo),
                  size: 30,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emisora.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emisora.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (emisora.localidad != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        emisora.localidad!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (tieneStreaming)
                _buildPlayerButton(
                  context,
                  emisora,
                  esActual,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerButton(
      BuildContext context,
      Emisora emisora,
      bool esActual,
      ) {
    final theme = Theme.of(context);

    return StreamBuilder<PlayerState>(
      stream: _audioPlayer.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;

        final processingState =
            playerState?.processingState ?? ProcessingState.idle;

        final bool playing =
            esActual && (playerState?.playing ?? false);

        final bool cargando =
            esActual &&
                (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering);

        if (cargando) {
          return SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }

        return IconButton(
          tooltip: playing
              ? 'Pausar'
              : 'Escuchar en directo',
          onPressed: () => _controlarReproduccion(emisora),
          icon: Icon(
            playing
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill,
            size: 38,
            color: theme.colorScheme.primary,
          ),
        );
      },
    );
  }

  IconData _iconoTipo(TipoEmisora tipo) {
    switch (tipo) {
      case TipoEmisora.publica:
        return Icons.account_balance_outlined;

      case TipoEmisora.informativa:
        return Icons.newspaper_outlined;

      case TipoEmisora.local:
        return Icons.location_on_outlined;

      case TipoEmisora.musical:
        return Icons.music_note_outlined;

      case TipoEmisora.cultural:
        return Icons.library_music_outlined;
    }
  }

  Future<void> _controlarReproduccion(Emisora emisora) async {
    final streamUrl = emisora.urlStreaming;

    if (streamUrl == null || streamUrl.trim().isEmpty) {
      await _abrirWeb(emisora);
      return;
    }

    final bool esActual = _emisoraActualId == emisora.id;

    try {
      if (esActual) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }

        return;
      }

      await _audioPlayer.stop();

      if (mounted) {
        setState(() {
          _emisoraActualId = emisora.id;
        });
      }

      await _audioPlayer.setUrl(streamUrl);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _emisoraActualId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo reproducir ${emisora.nombre}.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _abrirWeb(Emisora emisora) async {
    final uri = Uri.tryParse(emisora.urlWeb);

    if (uri == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se puede abrir ${emisora.nombre}.',
          ),
        ),
      );

      return;
    }

    final abierta = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abierta && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir ${emisora.nombre}.',
          ),
        ),
      );
    }
  }
}