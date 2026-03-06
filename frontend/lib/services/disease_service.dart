import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/disease_result.dart';
import '../utils/constants.dart';

class DiseaseService {
  static const Duration _timeout = Duration(seconds: 30);

  /// Upload an image file to the backend disease-detection API and return a [DiseaseResult].
  Future<DiseaseResult> analyzeImage(String imagePath, {String language = 'hi'}) async {
    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      throw Exception('Image file not found: $imagePath');
    }

    // Read bytes and base64-encode to send as JSON (avoids multipart complexity on iOS)
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Determine MIME type from extension
    final ext = imagePath.split('.').last.toLowerCase();
    final mimeType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    final uri = Uri.parse('$kBackendBaseUrl/api/disease/detect');

    final body = jsonEncode({
      'imageBase64': base64Image,
      'mimeType': mimeType,
      'language': language,
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept-Language': language,
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final data = json['data'] as Map<String, dynamic>;
          return DiseaseResult.fromApiResponse(data, imagePath);
        }
        throw Exception(json['error'] ?? 'Unknown error from disease API');
      }

      if (response.statusCode == 503) {
        throw Exception(language == 'hi'
            ? 'रोग पहचान सेवा अस्थायी रूप से उपलब्ध नहीं है। कृपया बाद में प्रयास करें।'
            : 'Disease detection service temporarily unavailable. Please try later.');
      }

      throw Exception('Disease API returned status ${response.statusCode}');
    } on SocketException {
      throw Exception(language == 'hi'
          ? 'नेटवर्क कनेक्शन नहीं है। इंटरनेट जांचें।'
          : 'No network connection. Check your internet.');
    } on Exception {
      rethrow;
    }
  }
}
