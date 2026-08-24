import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'gg9ef0fm';
  static const String _uploadPreset = 'novelda_ahora_recuerdos';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  Future<String> subirImagen({
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    final uri = Uri.parse(_uploadUrl);

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] = _uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: nombreArchivo,
      ),
    );

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Error al subir la imagen a Cloudinary: '
            '${response.statusCode} - $responseBody',
      );
    }

    final data =
    jsonDecode(responseBody) as Map<String, dynamic>;

    final secureUrl = data['secure_url'] as String?;

    if (secureUrl == null || secureUrl.trim().isEmpty) {
      throw Exception(
        'Cloudinary no devolvió una URL de imagen válida.',
      );
    }

    return secureUrl;
  }
}