import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/noticia.dart';
import '../services/firestore_noticias_service.dart';
import '../services/importador_noticias_service.dart';

class NoticiasScreen extends StatefulWidget {
  const NoticiasScreen({super.key});

  @override
  State<NoticiasScreen> createState() => _NoticiasScreenState();
}

class _NoticiasScreenState extends State<NoticiasScreen> {
  final FirestoreNoticiasService _service =
  FirestoreNoticiasService();

  final ImportadorNoticiasService _importador =
  ImportadorNoticiasService();

  CategoriaNoticia? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarNoticiasSilenciosamente();
    });
  }

  Future<void> _actualizarNoticiasSilenciosamente() async {
    try {
      await _importador.importarTodas();
    } catch (e) {
      debugPrint(
        '===== ERROR ACTUALIZACIÓN NOTICIAS NOVELDA =====',
      );
      debugPrint(e.toString());
    }
  }

  Future<void> _abrirNoticia(
      BuildContext context,
      Noticia noticia,
      ) async {
    final uri = Uri.tryParse(
      noticia.urlOriginal,
    );

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

  Future<void> _actualizarNoticias() async {
    try {
      await _importador.importarTodas();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron actualizar las noticias.',
          ),
        ),
      );
    }
  }

  List<CategoriaNoticia> _obtenerCategoriasDisponibles(
      List<Noticia> noticias,
      ) {
    final categorias = noticias
        .where(
          (noticia) =>
      noticia.tipo == TipoContenido.noticia,
    )
        .map(
          (noticia) => noticia.categoria,
    )
        .toSet()
        .toList();

    categorias.sort(
          (a, b) => _nombreCategoria(a).compareTo(
        _nombreCategoria(b),
      ),
    );

    return categorias;
  }

  List<Noticia> _filtrarNoticias(
      List<Noticia> noticias,
      ) {
    final noticiasSoloNoticias = noticias
        .where(
          (noticia) =>
      noticia.tipo == TipoContenido.noticia,
    )
        .toList();

    if (_categoriaSeleccionada == null) {
      return noticiasSoloNoticias;
    }

    return noticiasSoloNoticias
        .where(
          (noticia) =>
      noticia.categoria ==
          _categoriaSeleccionada,
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Noticias de Novelda',
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
            return RefreshIndicator(
              onRefresh: _actualizarNoticias,
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 250),
                  Center(
                    child: Text(
                      'No hay noticias de Novelda disponibles.',
                    ),
                  ),
                ],
              ),
            );
          }

          final categoriasDisponibles =
          _obtenerCategoriasDisponibles(
            noticias,
          );

          final noticiasFiltradas =
          _filtrarNoticias(noticias);

          return RefreshIndicator(
            onRefresh: _actualizarNoticias,
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                24,
              ),
              children: [
                _buildCategorias(
                  context,
                  categoriasDisponibles,
                ),
                const SizedBox(height: 14),
                if (noticiasFiltradas.isEmpty)
                  _buildSinNoticiasCategoria(
                    context,
                  )
                else
                  ...List.generate(
                    noticiasFiltradas.length,
                        (index) {
                      final noticia =
                      noticiasFiltradas[index];

                      return Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: _NoticiaCard(
                          noticia: noticia,
                          onTap: () =>
                              _abrirNoticia(
                                context,
                                noticia,
                              ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorias(
      BuildContext context,
      List<CategoriaNoticia> categoriasDisponibles,
      ) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildCategoriaChip(
            context,
            label: 'Todas',
            icon: Icons.article_outlined,
            seleccionado:
            _categoriaSeleccionada == null,
            onTap: () {
              setState(() {
                _categoriaSeleccionada = null;
              });
            },
          ),
          ...categoriasDisponibles.map(
                (categoria) {
              return _buildCategoriaChip(
                context,
                label: _nombreCategoria(
                  categoria,
                ),
                icon: _iconoCategoria(
                  categoria,
                ),
                seleccionado:
                _categoriaSeleccionada ==
                    categoria,
                onTap: () {
                  setState(() {
                    _categoriaSeleccionada =
                        categoria;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaChip(
      BuildContext context, {
        required String label,
        required IconData icon,
        required bool seleccionado,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        right: 8,
      ),
      child: FilterChip(
        selected: seleccionado,
        onSelected: (_) => onTap(),
        avatar: Icon(
          icon,
          size: 17,
          color: seleccionado
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: seleccionado
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
        selectedColor:
        theme.colorScheme.primary,
        checkmarkColor:
        theme.colorScheme.onPrimary,
        backgroundColor:
        theme.colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
      ),
    );
  }

  Widget _buildSinNoticiasCategoria(
      BuildContext context,
      ) {
    final nombre = _categoriaSeleccionada != null
        ? _nombreCategoria(
      _categoriaSeleccionada!,
    )
        : 'esta categoría';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              size: 42,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay noticias de $nombre.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  String _nombreCategoria(
      CategoriaNoticia categoria,
      ) {
    switch (categoria) {
      case CategoriaNoticia.actualidad:
        return 'Actualidad';
      case CategoriaNoticia.sucesos:
        return 'Sucesos';
      case CategoriaNoticia.politica:
        return 'Política';
      case CategoriaNoticia.sociedad:
        return 'Sociedad';
      case CategoriaNoticia.cultura:
        return 'Cultura';
      case CategoriaNoticia.fiestas:
        return 'Fiestas';
      case CategoriaNoticia.deportes:
        return 'Deportes';
      case CategoriaNoticia.economia:
        return 'Economía';
      case CategoriaNoticia.educacion:
        return 'Educación';
      case CategoriaNoticia.salud:
        return 'Salud';
      case CategoriaNoticia.servicios:
        return 'Servicios';
      case CategoriaNoticia.medioAmbiente:
        return 'Medio ambiente';
      case CategoriaNoticia.trafico:
        return 'Tráfico';
      case CategoriaNoticia.agenda:
        return 'Agenda';
    }
  }

  IconData _iconoCategoria(
      CategoriaNoticia categoria,
      ) {
    switch (categoria) {
      case CategoriaNoticia.actualidad:
        return Icons.article_outlined;
      case CategoriaNoticia.sucesos:
        return Icons.warning_amber_outlined;
      case CategoriaNoticia.politica:
        return Icons.account_balance_outlined;
      case CategoriaNoticia.sociedad:
        return Icons.groups_outlined;
      case CategoriaNoticia.cultura:
        return Icons.museum_outlined;
      case CategoriaNoticia.fiestas:
        return Icons.celebration_outlined;
      case CategoriaNoticia.deportes:
        return Icons.sports_soccer_outlined;
      case CategoriaNoticia.economia:
        return Icons.euro_outlined;
      case CategoriaNoticia.educacion:
        return Icons.school_outlined;
      case CategoriaNoticia.salud:
        return Icons.health_and_safety_outlined;
      case CategoriaNoticia.servicios:
        return Icons.miscellaneous_services_outlined;
      case CategoriaNoticia.medioAmbiente:
        return Icons.eco_outlined;
      case CategoriaNoticia.trafico:
        return Icons.traffic_outlined;
      case CategoriaNoticia.agenda:
        return Icons.event_outlined;
    }
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
                noticia.imagenUrl!
                    .trim()
                    .isNotEmpty)
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
                    _nombreCategoria(
                      noticia.categoria,
                    ).toUpperCase(),
                    style: theme
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.w700,
                      letterSpacing: 0.7,
                      color: theme
                          .colorScheme
                          .primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    noticia.titulo,
                    maxLines: 4,
                    overflow:
                    TextOverflow.ellipsis,
                    style: theme
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.w700,
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
      child: Image.network(
        noticia.imagenUrl!,
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

  String _nombreCategoria(
      CategoriaNoticia categoria,
      ) {
    switch (categoria) {
      case CategoriaNoticia.actualidad:
        return 'Actualidad';
      case CategoriaNoticia.sucesos:
        return 'Sucesos';
      case CategoriaNoticia.politica:
        return 'Política';
      case CategoriaNoticia.sociedad:
        return 'Sociedad';
      case CategoriaNoticia.cultura:
        return 'Cultura';
      case CategoriaNoticia.fiestas:
        return 'Fiestas';
      case CategoriaNoticia.deportes:
        return 'Deportes';
      case CategoriaNoticia.economia:
        return 'Economía';
      case CategoriaNoticia.educacion:
        return 'Educación';
      case CategoriaNoticia.salud:
        return 'Salud';
      case CategoriaNoticia.servicios:
        return 'Servicios';
      case CategoriaNoticia.medioAmbiente:
        return 'Medio ambiente';
      case CategoriaNoticia.trafico:
        return 'Tráfico';
      case CategoriaNoticia.agenda:
        return 'Agenda';
    }
  }
}