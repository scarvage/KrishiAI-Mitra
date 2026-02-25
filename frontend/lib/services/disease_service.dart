import '../models/disease_result.dart';
import '../utils/mock_data.dart';

class DiseaseService {
  static int _demoIndex = 0;

  // Simulates Google Cloud Vision + ML model analysis
  Future<DiseaseResult> analyzeImage(String imagePath) async {
    // Simulate upload + ML processing time
    await Future.delayed(const Duration(seconds: 2));

    final data = mockDiseases[_demoIndex % mockDiseases.length];
    _demoIndex++;

    return DiseaseResult.fromMap(data, imagePath);
  }
}
