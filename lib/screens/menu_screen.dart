import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({
    super.key,
    required this.onSeleccion,
  });

  final void Function(String seccion) onSeleccion;

  void _seleccionar(BuildContext context, String seccion) {
    Navigator.pop(context);
    onSeleccion(seccion);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Novelda Ahora',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              onTap: () => _seleccionar(context, 'inicio'),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Noticias'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _seleccionar(context, 'noticias'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Vídeos'),
              onTap: () => _seleccionar(context, 'videos'),
            ),
            ListTile(
              leading: const Icon(Icons.radio_outlined),
              title: const Text('Radio'),
              onTap: () => _seleccionar(context, 'radio'),
            ),
            ListTile(
              leading: const Icon(Icons.local_pharmacy_outlined),
              title: const Text('Farmacia de guardia'),
              onTap: () => _seleccionar(context, 'farmacia'),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Ocio'),
              onTap: () => _seleccionar(context, 'ocio'),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_outlined),
              title: const Text('Gastronomía'),
              onTap: () => _seleccionar(context, 'gastronomia'),
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Tiempo'),
              onTap: () => _seleccionar(context, 'tiempo'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Novelda en el recuerdo'),
              onTap: () => _seleccionar(context, 'recuerdo'),
            ),
            ListTile(
              leading: const Icon(Icons.miscellaneous_services_outlined),
              title: const Text('Servicios'),
              onTap: () => _seleccionar(context, 'servicios'),
            ),
          ],
        ),
      ),
    );
  }
}