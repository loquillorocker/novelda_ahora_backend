import 'package:flutter/material.dart';

import '../models/noticia.dart';
import '../services/firestore_noticias_service.dart';
import 'video_player_screen.dart';

class VideosScreen extends StatelessWidget {
  VideosScreen({super.key});

  final FirestoreNoticiasService _service =
  FirestoreNoticiasService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vídeos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Noticia>>(
        stream: _service.escucharVideos(
          limite: 20,
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
                  'Error al cargar los vídeos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
            return const Center(
              child: Text(
                'No hay vídeos disponibles.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              24,
            ),
            itemCount: videos.length,
            separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _VideoCard(
                video: videos[index],
              );
            },
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.video,
  });

  final Noticia video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _abrirVideo(context);
        },
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                16,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    video.titulo,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 17,
                        color:
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'noveldadigital',
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);

    if (video.imagenUrl == null ||
        video.imagenUrl!.trim().isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color:
          theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 56,
              color:
              theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            video.imagenUrl!,
            fit: BoxFit.cover,
            errorBuilder: (
                context,
                error,
                stackTrace,
                ) {
              return Container(
                color: theme
                    .colorScheme
                    .surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 56,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
          Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.65,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: video,
        ),
      ),
    );
  }
}