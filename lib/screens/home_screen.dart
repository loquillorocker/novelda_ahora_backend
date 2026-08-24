import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'menu_screen.dart';
import 'radio_screen.dart';
import 'noticias_screen.dart';
import 'videos_screen.dart';
import 'farmacia_screen.dart';
import 'tiempo_screen.dart';
import 'prensa_screen.dart';
import '../services/avisos_service.dart';
import '../services/avisos_vistos_service.dart';
import '../services/importador_noticias_service.dart';
import '../widgets/aviso_popup.dart';
import '../widgets/home_noticias_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AvisosService _avisosService = AvisosService();

  final AvisosVistosService _avisosVistosService =
  AvisosVistosService();

  final ImportadorNoticiasService _importadorNoticias =
  ImportadorNoticiasService();

  bool _actualizandoNoticias = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarAvisos();
      _actualizarNoticiasAlAbrir();
    });
  }

  Future<void> _actualizarNoticiasAlAbrir() async {
    if (_actualizandoNoticias) {
      return;
    }

    _actualizandoNoticias = true;

    try {
      await _importadorNoticias.importarTodas();
    } catch (_) {
      // Si falla la actualización, se mantienen
      // las noticias que ya estaban disponibles.
    } finally {
      _actualizandoNoticias = false;
    }
  }

  Future<void> _mostrarAvisos() async {
    try {
      final avisos =
      await _avisosService.obtenerAvisosActivos();

      if (!mounted || avisos.isEmpty) {
        return;
      }

      final avisosVistos =
      await _avisosVistosService.obtenerAvisosVistos();

      if (!mounted) {
        return;
      }

      final avisosPendientes = avisos
          .where(
            (aviso) => !avisosVistos.contains(aviso.id),
      )
          .toList();

      for (final aviso in avisosPendientes) {
        if (!mounted) {
          return;
        }

        final resultado = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AvisoPopup(
            aviso: aviso,
          ),
        );

        if (!mounted) {
          return;
        }

        await _avisosVistosService.marcarAvisoComoVisto(
          aviso.id,
        );

        if (resultado == true) {
          await _abrirUrlAviso(aviso.url);
        }

        if (!mounted) {
          return;
        }
      }
    } catch (_) {
      // Los avisos no deben impedir que cargue el Home.
    }
  }

  Future<void> _abrirUrlAviso(String? url) async {
    if (url == null || url.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url.trim());

    if (uri == null) {
      return;
    }

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir el enlace del aviso.',
          ),
        ),
      );
    }
  }

  void _abrirNoticias() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NoticiasScreen(),
      ),
    );
  }

  void _abrirRadio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RadioScreen(),
      ),
    );
  }

  void _abrirPrensa() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrensaScreen(),
      ),
    );
  }

  void _abrirVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideosScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Novelda Ahora',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      drawer: MenuScreen(
        onSeleccion: (seccion) {
          if (seccion == 'noticias') {
            _abrirNoticias();
          }

          if (seccion == 'videos') {
            _abrirVideos();
          }

          if (seccion == 'radio') {
            _abrirRadio();
          }

          if (seccion == 'farmacia') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FarmaciaScreen(),
              ),
            );
          }

          if (seccion == 'tiempo') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TiempoScreen(),
              ),
            );
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          32,
        ),
        children: [
          _buildWelcome(context),

          const SizedBox(height: 18),

          _buildQuickAccess(context),

          const SizedBox(height: 24),

          const HomeNoticiasSection(),

          const SizedBox(height: 28),

          _buildDiscoverSection(context),
        ],
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Novelda Ahora',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Todo lo que ocurre en Novelda, en un solo lugar.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildQuickAccessChip(
            context,
            icon: Icons.article_outlined,
            label: 'Noticias',
            onTap: _abrirNoticias,
          ),
          _buildQuickAccessChip(
            context,
            icon: Icons.event_outlined,
            label: 'Agenda',
          ),
          _buildQuickAccessChip(
            context,
            icon: Icons.restaurant_outlined,
            label: 'Restauración',
          ),
          _buildQuickAccessChip(
            context,
            icon: Icons.local_activity_outlined,
            label: 'Ocio',
          ),
          _buildQuickAccessChip(
            context,
            icon: Icons.museum_outlined,
            label: 'Cultura',
          ),
          _buildQuickAccessChip(
            context,
            icon: Icons.radio_outlined,
            label: 'Radio',
            onTap: _abrirRadio,
          ),
          _buildQuickAccessChip(
            context,
            icon: Icons.newspaper_outlined,
            label: 'Prensa',
            onTap: _abrirPrensa,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessChip(
      BuildContext context, {
        required IconData icon,
        required String label,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(label),
        onPressed: onTap,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: onTap != null
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
      ),
    );
  }

  Widget _buildDiscoverSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descubre Novelda',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        _buildContentPlaceholder(
          context,
          Icons.video_library_outlined,
          'Vídeos',
          'Reportajes y vídeos de actualidad.',
          onTap: _abrirVideos,
        ),
        const SizedBox(height: 10),
        _buildContentPlaceholder(
          context,
          Icons.radio_outlined,
          'Radio',
          'Escucha emisoras de Novelda, la comarca y Alicante.',
          onTap: _abrirRadio,
        ),
      ],
    );
  }

  Widget _buildContentPlaceholder(
      BuildContext context,
      IconData icon,
      String titulo,
      String descripcion, {
        VoidCallback? onTap,
      }) {
    return Card(
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(descripcion),
        onTap: onTap,
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}