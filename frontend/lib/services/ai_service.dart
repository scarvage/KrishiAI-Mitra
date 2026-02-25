import '../utils/mock_data.dart';

class AIService {
  // Simulates Amazon Bedrock/Claude AI response with keyword matching
  Future<String> getResponse(String userText, String language) async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 1500));

    final textLower = userText.toLowerCase();

    // Keyword matching against mockAIResponses map
    for (final key in mockAIResponses.keys) {
      if (key == 'default') continue;
      if (textLower.contains(key)) {
        return mockAIResponses[key]![language] ??
            mockAIResponses[key]!['en']!;
      }
    }

    // Hindi keyword matching
    if (textLower.contains('गेहूं') || textLower.contains('gehu')) {
      return mockAIResponses['wheat']![language]!;
    }
    if (textLower.contains('धान') ||
        textLower.contains('चावल') ||
        textLower.contains('rice')) {
      return mockAIResponses['rice']![language]!;
    }
    if (textLower.contains('बीमारी') ||
        textLower.contains('रोग') ||
        textLower.contains('खतरा')) {
      return mockAIResponses['disease']![language]!;
    }
    if (textLower.contains('खाद') ||
        textLower.contains('fertilizer') ||
        textLower.contains('npk') ||
        textLower.contains('urea')) {
      return mockAIResponses['fertilizer']![language]!;
    }

    return mockAIResponses['default']![language]!;
  }
}
