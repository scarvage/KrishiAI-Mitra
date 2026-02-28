import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/mandi_price.dart';
import '../utils/constants.dart';

class MandiService {
  /// Fetch mandi prices for the given [crop] and [state] from the backend.
  /// [languageCode] is sent as the Accept-Language header so the AI
  /// recommendation is generated in the user's selected language.
  Future<MandiApiResponse> fetchMandiPrices({
    required String crop,
    required String state,
    required String languageCode,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$kBackendBaseUrl/api/price/mandi').replace(
      queryParameters: {
        'crop': crop,
        'state': state,
        'limit': limit.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept-Language': languageCode,
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to fetch mandi prices');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return MandiApiResponse.fromJson(json);
  }
}
