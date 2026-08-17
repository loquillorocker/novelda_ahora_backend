import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/noticia.dart';
import '../services/firestore_noticias_service.dart';
import '../screens/noticias_screen.dart';

class HomeNoticiasSection extends StatelessWidget {
  const HomeNoticiasSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        const SizedBox(height: 10),
        _buildLatestNews(context),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Noticias',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoticiasScreen(),
              ),
            );
          },
          child: const Text('Ver todas'),
        ),
      ],
    );
  }

  Widget _buildLatestNews(BuildContext context) {
    final service = FirestoreNoticiasService();

    return StreamBuilder<List<Noticia>>(
      stream: service.escucharNoticias(
        limite: 3,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Card(
            elevation: 1,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildMessageCard(
            context,
            'No se pudieron cargar las noticias.',
          );
        }

        final noticias = snapshot.data ?? [];

        if (noticias.isEmpty) {
          return _buildMessageCard(
            context,
            'Todavía no hay noticias disponibles.',
          );
        }

        return Column(
          children: [
            for (int i = 0; i < noticias.length; i++) ...[
              _buildNewsCard(
                context,
                noticias[i],
              ),
              if (i < noticias.length - 1)
                const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNewsCard(
      BuildContext context,
      Noticia noticia,
      ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirNoticia(
          context,
          noticia,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildNewsImage(
                context,
                noticia,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombreCategoria(
                        noticia.categoria,
                      ),
                      style: theme
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                        fontWeight:
                        FontWeight.bold,
                        color: theme
                            .colorScheme
                            .primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      noticia.titulo,
                      maxLines: 3,
                      overflow:
                      TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                        FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsImage(
      BuildContext context,
      Noticia noticia,
      ) {
    if (noticia.imagenUrl == null ||
        noticia.imagenUrl!.trim().isEmpty) {
      return _buildImagePlaceholder(context);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        noticia.imagenUrl!,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return _buildImagePlaceholder(context);
        },
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.article_outlined,
        size: 30,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMessageCard(
      BuildContext context,
      String mensaje,
      ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          mensaje,
          style:
          Theme.of(context)
              .textTheme
              .bodyMedium,
        ),
      ),
    );
  }

  Future<void> _abrirNoticia(
      BuildContext context,
      Noticia noticia,
      ) async {
    final uri = Uri.tryParse(
      noticia.urlOriginal,
    );

    if (uri == null) {
      return;
    }

    final abierta = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!abierta && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir el artículo.',
          ),
        ),
      );
    }
  }

  String _nombreCategoria(
      CategoriaNoticia categoria,
      ) {
    switch (categoria) {
      case CategoriaNoticia.actualidad:
        return 'ACTUALIDAD';
      case CategoriaNoticia.sucesos:
        return 'SUCESOS';
      case CategoriaNoticia.politica:
        return 'POLÍTICA';
      case CategoriaNoticia.sociedad:
        return 'SOCIEDAD';
      case CategoriaNoticia.cultura:
        return 'CULTURA';
      case CategoriaNoticia.fiestas:
        return 'FIESTAS';
      case CategoriaNoticia.deportes:
        return 'DEPORTES';
      case CategoriaNoticia.economia:
        return 'ECONOMÍA';
      case CategoriaNoticia.educacion:
        return 'EDUCACIÓN';
      case CategoriaNoticia.salud:
        return 'SALUD';
      case CategoriaNoticia.servicios:
        return 'SERVICIOS';
      case CategoriaNoticia.medioAmbiente:
        return 'MEDIO AMBIENTE';
      case CategoriaNoticia.trafico:
        return 'TRÁFICO';
      case CategoriaNoticia.agenda:
        return 'AGENDA';
    }
  }
}