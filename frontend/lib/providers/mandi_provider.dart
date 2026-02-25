import 'package:flutter/material.dart';

import '../models/mandi_price.dart';
import '../services/mandi_service.dart';

class MandiProvider extends ChangeNotifier {
  final MandiService _service = MandiService();

  List<MandiPrice> _prices = [];
  bool _isLoading = false;
  String _selectedCommodity = 'All';
  String _language = 'hi';

  List<MandiPrice> get prices => _prices;
  bool get isLoading => _isLoading;
  String get selectedCommodity => _selectedCommodity;
  String get language => _language;

  // Filtered list for display
  List<MandiPrice> get filteredPrices {
    if (_selectedCommodity == 'All') return _prices;
    return _prices
        .where((p) => p.commodity.toLowerCase().contains(
            _selectedCommodity.toLowerCase()))
        .toList();
  }

  void toggleLanguage() {
    _language = _language == 'hi' ? 'en' : 'hi';
    notifyListeners();
  }

  void setLanguage(String code) {
    if (_language == code) return;
    _language = code;
    notifyListeners();
  }

  Future<void> loadPrices() async {
    _isLoading = true;
    notifyListeners();

    _prices = await _service.getPrices();
    _isLoading = false;
    notifyListeners();
  }

  void selectCommodity(String commodity) {
    _selectedCommodity = commodity;
    notifyListeners();
  }
}
