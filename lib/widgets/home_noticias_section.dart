import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/noticia.dart';
import '../services/firestore_noticias_service.dart';
import '../screens/noticias_screen.dart';

class HomeNoticiasSection extends StatefulWidget {
  const HomeNoticiasSection({
    super.key,
  });

  @override
  State<HomeNoticiasSection> createState() =>
      _HomeNoticiasSectionState();
}

class _HomeNoticiasSectionState
    extends State<HomeNoticiasSection> {
  static const String _cloudinaryCloudName = 'gg9ef0fm';

  final FirestoreNoticiasService _service =
  FirestoreNoticiasService();

  final PageController _pageController =
  PageController(
    viewportFraction: 0.92,
  );

  final ValueNotifier<int> _paginaActual =
  ValueNotifier<int>(0);

  @override
  void dispose() {
    _pageController.dispose();
    _paginaActual.dispose();
    super.dispose();
  }

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
    return StreamBuilder<List<Noticia>>(
      stream: _service.escucharNoticias(
        limite: 6,
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

        final noticias = (snapshot.data ?? [])
            .where(
              (noticia) =>
          noticia.tipo == TipoContenido.noticia,
        )
            .toList();

        if (noticias.isEmpty) {
          return _buildMessageCard(
            context,
            'Todavía no hay noticias disponibles.',
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 330,
              child: PageView.builder(
                controller: _pageController,
                itemCount: noticias.length,
                padEnds: false,
                physics: const PageScrollPhysics(),
                onPageChanged: (pagina) {
                  _paginaActual.value = pagina;
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right:
                      index < noticias.length - 1
                          ? 12
                          : 0,
                    ),
                    child: _buildNewsCard(
                      context,
                      noticias[index],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildPageIndicators(
              context,
              noticias.length,
            ),
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
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirNoticia(
          context,
          noticia,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildNewsImage(
              context,
              noticia,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  14,
                ),
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
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        noticia.titulo,
                        maxLines: 3,
                        overflow:
                        TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.public,
                          size: 15,
                          color: theme.colorScheme
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
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: theme.colorScheme
                              .onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsImage(
      BuildContext context,
      Noticia noticia,
      ) {
    final imagenUrl = _convertirImagenCloudinary(
      noticia.imagenUrl,
    );

    if (imagenUrl == null) {
      return _buildImagePlaceholder(context);
    }

    return SizedBox(
      width: double.infinity,
      height: 185,
      child: Image.network(
        imagenUrl,
        fit: BoxFit.cover,
        loadingBuilder: (
            context,
            child,
            loadingProgress,
            ) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return _buildImagePlaceholder(context);
        },
      ),
    );
  }

  String? _convertirImagenCloudinary(
      String? url,
      ) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    final limpia = url.trim();

    if (limpia.contains(
      'res.cloudinary.com/',
    )) {
      return limpia;
    }

    if (!limpia.startsWith('http://') &&
        !limpia.startsWith('https://')) {
      return limpia;
    }

    final encodedUrl =
    Uri.encodeComponent(limpia);

    return 'https://res.cloudinary.com/'
        '$_cloudinaryCloudName/image/fetch/'
        '$encodedUrl';
  }

  Widget _buildImagePlaceholder(
      BuildContext context,
      ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 185,
      color:
      colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.article_outlined,
        size: 48,
        color:
        colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildPageIndicators(
      BuildContext context,
      int cantidad,
      ) {
    final primary =
        Theme.of(context).colorScheme.primary;

    return ValueListenableBuilder<int>(
      valueListenable: _paginaActual,
      builder: (
          context,
          pagina,
          child,
          ) {
        return Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: List.generate(
            cantidad,
                (index) {
              final activo =
                  index == pagina;

              return AnimatedContainer(
                duration: const Duration(
                  milliseconds: 200,
                ),
                margin:
                const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                width: activo ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: activo
                      ? primary
                      : primary.withValues(
                    alpha: 0.25,
                  ),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              );
            },
          ),
        );
      },
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
          style: Theme.of(context)
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