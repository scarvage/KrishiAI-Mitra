import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class AIService {
  static const Duration _timeout = Duration(seconds: 10);

  /// Send a text query to the backend Voice Assistant API.
  /// Returns the AI-generated answer string.
  Future<String> getResponse(
    String query,
    String languageCode, {
    List<Map<String, String>> history = const [],
  }) async {
    final uri = Uri.parse('$kBackendBaseUrl/api/voice/query');

    final body = jsonEncode({
      'query': query,
      'language': languageCode,
      'history': history,
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept-Language': languageCode,
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return (data['data']?['answer'] as String?) ?? _fallback(languageCode);
        }
      }

      return _errorMessage(languageCode, response.statusCode);
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return languageCode == 'hi'
            ? 'नेटवर्क धीमा है। कृपया पुनः प्रयास करें।'
            : 'Network is slow. Please try again.';
      }
      return languageCode == 'hi'
          ? 'सेवा अभी उपलब्ध नहीं है। कृपया बाद में प्रयास करें।'
          : 'Service unavailable. Please try again later.';
    }
  }

  String _fallback(String lang) => lang == 'hi'
      ? 'मैं अभी आपकी मदद नहीं कर सकता। कृपया दोबारा पूछें।'
      : 'I could not process your question. Please try again.';

  String _errorMessage(String lang, int status) {
    if (status == 503) {
      return lang == 'hi'
          ? 'AI सेवा अस्थायी रूप से अनुपलब्ध है। कृपया बाद में प्रयास करें।'
          : 'AI service temporarily unavailable. Please try later.';
    }
    return _fallback(lang);
  }
}
