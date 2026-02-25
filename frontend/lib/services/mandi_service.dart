import 'package:shared_preferences/shared_preferences.dart';

import '../models/mandi_price.dart';
import '../utils/mock_data.dart';

class MandiService {
  // Returns the full list of mock mandi prices
  Future<List<MandiPrice>> getPrices({String? state}) async {
    // Check cache: if last fetch < 30 minutes ago, return cached
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt('mandi_last_fetch') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Cache hit - return immediately without delay
    if (now - lastFetch < 1800000) {
      final prices = mockMandiPrices.map((m) => MandiPrice.fromMap(m)).toList();
      if (state != null) {
        return prices.where((p) => p.state == state).toList();
      }
      return prices;
    }

    // Cache miss - simulate network fetch
    await Future.delayed(const Duration(seconds: 1));
    await prefs.setInt('mandi_last_fetch', now);

    // Filter by state if provided
    final prices = mockMandiPrices.map((m) => MandiPrice.fromMap(m)).toList();
    if (state != null) {
      return prices.where((p) => p.state == state).toList();
    }
    return prices;
  }
}
