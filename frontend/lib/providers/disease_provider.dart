import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/disease_result.dart';
import '../services/disease_service.dart';

class DiseaseProvider extends ChangeNotifier {
  final DiseaseService _service = DiseaseService();
  final ImagePicker _imagePicker = ImagePicker();

  DiseaseResult? _result;
  bool _isAnalyzing = false;
  String? _imagePath;
  String _language = 'hi';

  DiseaseResult? get result => _result;
  bool get isAnalyzing => _isAnalyzing;
  String? get imagePath => _imagePath;
  String get language => _language;

  void toggleLanguage() {
    _language = _language == 'hi' ? 'en' : 'hi';
    notifyListeners();
  }

  void setLanguage(String code) {
    if (_language == code) return;
    _language = code;
    notifyListeners();
  }

  Future<void> pickAndAnalyze(ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (file == null) return;

    _imagePath = file.path;
    _isAnalyzing = true;
    _result = null;
    notifyListeners();

    _result = await _service.analyzeImage(file.path);
    _isAnalyzing = false;
    notifyListeners();
  }

  void reset() {
    _result = null;
    _imagePath = null;
    _isAnalyzing = false;
    notifyListeners();
  }
}
