import 'package:flutter/material.dart';

import 'menu_screen.dart';
import 'radio_screen.dart';
import 'noticias_screen.dart';
import '../widgets/home_noticias_section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoticiasScreen(),
              ),
            );
          }

          if (seccion == 'radio') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RadioScreen(),
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

          const SizedBox(height: 20),

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
          Icons.wb_sunny_outlined,
          'El tiempo',
          'Consulta la previsión meteorológica.',
          onTap: () {},
        ),

        const SizedBox(height: 10),

        _buildContentPlaceholder(
          context,
          Icons.video_library_outlined,
          'Vídeos',
          'Reportajes y vídeos de actualidad.',
          onTap: () {},
        ),

        const SizedBox(height: 10),

        _buildContentPlaceholder(
          context,
          Icons.radio_outlined,
          'Radio',
          'Escucha emisoras de Novelda, la comarca y Alicante.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RadioScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildSmallSection(
                context,
                Icons.event_outlined,
                'Ocio',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallSection(
                context,
                Icons.restaurant_outlined,
                'Gastronomía local',
                onTap: () {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildSmallSection(
                context,
                Icons.photo_library_outlined,
                'El recuerdo',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSmallSection(
                context,
                Icons.event_available_outlined,
                'Agenda',
                onTap: () {},
              ),
            ),
          ],
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

  Widget _buildSmallSection(
      BuildContext context,
      IconData icon,
      String titulo, {
        VoidCallback? onTap,
      }) {
    return Card(
      elevation: 1,
      child: SizedBox(
        height: 106,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}