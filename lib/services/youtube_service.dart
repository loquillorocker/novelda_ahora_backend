import 'dart:convert';

import 'package:http/http.dart' as http;

class YouTubeService {
  static const String _apiKey = 'AIzaSyDWOECeUctQ55ls9RMuOKoVJ17gT8rDwd8';
  static const String _playlistId = 'UURPUWeXX3yBMsXt66Reb8hw';

  Future<List<Map<String, dynamic>>> obtenerUltimosVideos({
    int limite = 10,
  }) async {
    final uri = Uri.https(
      'www.googleapis.com',
      '/youtube/v3/playlistItems',
      {
        'part': 'snippet,contentDetails',
        'playlistId': _playlistId,
        'maxResults': limite.toString(),
        'key': _apiKey,
      },
    );

    final respuesta = await http.get(uri);

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error al obtener los vídeos de YouTube: '
            '${respuesta.statusCode} ${respuesta.body}',
      );
    }

    final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

    final items = datos['items'] as List<dynamic>? ?? [];

    return items
        .map((item) => item as Map<String, dynamic>)
        .toList();
  }
}