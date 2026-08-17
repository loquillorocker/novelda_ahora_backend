import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/noticia.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  final Noticia video;

  @override
  State<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState
    extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicializarReproductor();
  }

  void _inicializarReproductor() {
    final videoUrl = widget.video.videoUrl?.trim();

    if (videoUrl == null || videoUrl.isEmpty) {
      _error = 'Este vídeo no tiene un identificador válido.';
      return;
    }

    final videoId = _obtenerVideoId(videoUrl);

    if (videoId == null || videoId.isEmpty) {
      _error = 'No se ha podido identificar el vídeo de YouTube.';
      return;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
      ),
    );
  }

  String? _obtenerVideoId(String valor) {
    final texto = valor.trim();

    // Si ya es directamente un ID de YouTube.
    if (!texto.contains('/') &&
        !texto.contains('?') &&
        !texto.contains('=') &&
        !texto.contains('.')) {
      return texto;
    }

    final uri = Uri.tryParse(texto);

    if (uri == null) {
      return null;
    }

    // https://www.youtube.com/watch?v=XXXXXXXXXXX
    final parametro = uri.queryParameters['v'];

    if (parametro != null &&
        parametro.isNotEmpty) {
      return parametro;
    }

    // https://youtu.be/XXXXXXXXXXX
    if (uri.host.contains('youtu.be')) {
      final segmentos = uri.pathSegments;

      if (segmentos.isNotEmpty) {
        return segmentos.first;
      }
    }

    // https://www.youtube.com/embed/XXXXXXXXXXX
    if (uri.pathSegments.contains('embed')) {
      final indice = uri.pathSegments.indexOf('embed');

      if (indice + 1 < uri.pathSegments.length) {
        return uri.pathSegments[indice + 1];
      }
    }

    return null;
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vídeo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final controller = _controller;

    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        YoutubePlayer(
          controller: controller,
          aspectRatio: 16 / 9,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            20,
            16,
            24,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                widget.video.titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'noveldadigital',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}