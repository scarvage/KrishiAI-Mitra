import 'package:flutter/material.dart';

import '../models/mandi_price.dart';
import '../services/mandi_service.dart';

enum MandiScreenState { idle, loading, loaded, error }

class MandiProvider extends ChangeNotifier {
  final MandiService _service = MandiService();

  MandiScreenState _state = MandiScreenState.idle;
  List<ApiMandiPrice> _prices = [];
  String _recommendation = '';
  String? _selectedCrop;
  String? _selectedState;
  String? _lastUpdated;
  int _totalMandis = 0;
  String? _errorMessage;
  String _language = 'hi';

  // --- Getters ---
  MandiScreenState get screenState => _state;
  List<ApiMandiPrice> get prices => _prices;
  String get recommendation => _recommendation;
  String? get selectedCrop => _selectedCrop;
  String? get selectedState => _selectedState;
  String? get lastUpdated => _lastUpdated;
  int get totalMandis => _totalMandis;
  String? get errorMessage => _errorMessage;
  String get language => _language;

  bool get isLoading => _state == MandiScreenState.loading;
  bool get hasData => _state == MandiScreenState.loaded;
  bool get hasError => _state == MandiScreenState.error;

  void setLanguage(String code) {
    if (_language == code) return;
    _language = code;
    notifyListeners();
  }

  void selectCrop(String crop) {
    _selectedCrop = crop;
    notifyListeners();
  }

  void selectState(String state) {
    _selectedState = state;
    notifyListeners();
  }

  /// Reset back to the selection screen
  void reset() {
    _state = MandiScreenState.idle;
    _prices = [];
    _recommendation = '';
    _lastUpdated = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetch live prices + AI recommendation from the backend.
  Future<void> fetchPrices({String? crop, String? state}) async {
    final cropToUse = crop ?? _selectedCrop;
    final stateToUse = state ?? _selectedState;

    if (cropToUse == null || stateToUse == null) return;

    _selectedCrop = cropToUse;
    _selectedState = stateToUse;
    _state = MandiScreenState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.fetchMandiPrices(
        crop: cropToUse,
        state: stateToUse,
        languageCode: _language,
      );

      _prices = response.prices;
      _recommendation = response.recommendation;
      _lastUpdated = response.lastUpdated;
      _totalMandis = response.totalMandis;
      _state = MandiScreenState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = MandiScreenState.error;
    }

    notifyListeners();
  }
}
