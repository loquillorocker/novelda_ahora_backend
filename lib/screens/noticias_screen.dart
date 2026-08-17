import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/noticia.dart';
import '../services/firestore_noticias_service.dart';

class NoticiasScreen extends StatelessWidget {
  NoticiasScreen({super.key});

  final FirestoreNoticiasService _service =
  FirestoreNoticiasService();

  Future<void> _abrirNoticia(
      BuildContext context,
      Noticia noticia,
      ) async {
    final uri = Uri.tryParse(noticia.urlOriginal);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede abrir esta noticia.',
          ),
        ),
      );
      return;
    }

    final abierta = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abierta && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir el artículo.',
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
          'Noticias',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Noticia>>(
        stream: _service.escucharNoticias(
          limite: 30,
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
                  'Error al cargar las noticias:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final noticias = snapshot.data ?? [];

          if (noticias.isEmpty) {
            return const Center(
              child: Text(
                'No hay noticias disponibles.',
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
            itemCount: noticias.length,
            separatorBuilder: (_, _) =>
            const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final noticia = noticias[index];

              return _NoticiaCard(
                noticia: noticia,
                onTap: () => _abrirNoticia(
                  context,
                  noticia,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  const _NoticiaCard({
    required this.noticia,
    required this.onTap,
  });

  final Noticia noticia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            if (noticia.imagenUrl != null &&
                noticia.imagenUrl!.trim().isNotEmpty)
              _buildImage(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                14,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    noticia.categoria.name.toUpperCase(),
                    style:
                    theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color:
                      theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    noticia.titulo,
                    maxLines: 4,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 15,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          noticia.fuenteNombre,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: theme
                              .textTheme
                              .bodySmall
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

  Widget _buildImage(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image(
        image: _ImagenSslPersonalizada(
          noticia.imagenUrl!,
        ),
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            color:
            theme.colorScheme.primaryContainer,
            child: Center(
              child: Icon(
                Icons.article_outlined,
                size: 42,
                color:
                theme.colorScheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ImageProvider personalizada.
///
/// Algunas imágenes de Novelda Digital tienen un problema
/// con la cadena de certificados SSL del servidor.
/// Flutter las rechaza aunque el navegador pueda descargarlas.
///
/// Esta clase utiliza un HttpClient que acepta ese certificado
/// para poder descargar la imagen.
class _ImagenSslPersonalizada
    extends ImageProvider<_ImagenSslPersonalizada> {
  const _ImagenSslPersonalizada(this.url);

  final String url;

  @override
  Future<_ImagenSslPersonalizada> obtainKey(
      ImageConfiguration configuration,
      ) {
    return SynchronousFuture<_ImagenSslPersonalizada>(
      this,
    );
  }

  @override
  ImageStreamCompleter loadImage(
      _ImagenSslPersonalizada key,
      ImageDecoderCallback decode,
      ) {
    final completer =
    MultiFrameImageStreamCompleter(
      codec: _cargarImagen(
        key.url,
        decode,
      ),
      scale: 1.0,
      informationCollector: () sync* {
        yield DiagnosticsProperty<String>(
          'URL',
          key.url,
        );
      },
    );

    return completer;
  }

  Future<ui.Codec> _cargarImagen(
      String url,
      ImageDecoderCallback decode,
      ) async {
    final uri = Uri.parse(url);

    final client = HttpClient();

    client.badCertificateCallback =
        (
        X509Certificate cert,
        String host,
        int port,
        ) {
      if (host == 'img.noveldadigital.es') {
        return true;
      }

      return false;
    };

    try {
      final request =
      await client.getUrl(uri);

      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0',
      );

      final response =
      await request.close();

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP ${response.statusCode}',
        );
      }

      final bytes =
      await consolidateHttpClientResponseBytes(
        response,
      );

      final buffer =
      await ui.ImmutableBuffer.fromUint8List(
        Uint8List.fromList(bytes),
      );

      return decode(buffer);
    } finally {
      client.close();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is _ImagenSslPersonalizada &&
          other.url == url;

  @override
  int get hashCode => url.hashCode;
}