import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DiseaseResult {
  final String name;
  final String nameHindi;
  final String cropType;
  final int confidencePercent;
  final String severity;
  final Color severityColor;
  final List<String> treatmentSteps;
  final List<String> treatmentStepsHindi;
  final String imagePath;
  final String icon;
  final bool lowConfidence;
  final String? lowConfidenceMessage;

  DiseaseResult({
    required this.name,
    required this.nameHindi,
    required this.cropType,
    required this.confidencePercent,
    required this.severity,
    required this.severityColor,
    required this.treatmentSteps,
    required this.treatmentStepsHindi,
    required this.imagePath,
    required this.icon,
    this.lowConfidence = false,
    this.lowConfidenceMessage,
  });

  /// Build from the real backend API response.
  factory DiseaseResult.fromApiResponse(Map<String, dynamic> data, String imagePath) {
    final severity = (data['severity'] as String?) ?? 'medium';
    final confidencePct = (data['confidencePercent'] as int?) ??
        ((((data['confidence'] as num?) ?? 0.0) * 100).round());

    final Color color;
    switch (severity) {
      case 'none':
        color = AppColors.success;
        break;
      case 'low':
        color = Colors.lightGreen;
        break;
      case 'high':
        color = AppColors.error;
        break;
      default:
        color = AppColors.warning;
    }

    final String icon;
    final String cropType = (data['cropType'] as String?) ?? 'Unknown';
    if (cropType.toLowerCase().contains('tomato')) {
      icon = '🍅';
    } else if (cropType.toLowerCase().contains('potato')) {
      icon = '🥔';
    } else if (cropType.toLowerCase().contains('wheat')) {
      icon = '🌾';
    } else if (cropType.toLowerCase().contains('rice')) {
      icon = '🍚';
    } else if (cropType.toLowerCase().contains('maize') || cropType.toLowerCase().contains('corn')) {
      icon = '🌽';
    } else if (cropType.toLowerCase().contains('apple')) {
      icon = '🍎';
    } else if (severity == 'none') {
      icon = '✅';
    } else {
      icon = '🌿';
    }

    return DiseaseResult(
      name: (data['diseaseName'] as String?) ?? 'Unknown',
      nameHindi: (data['diseaseNameHindi'] as String?) ?? '',
      cropType: cropType,
      confidencePercent: confidencePct,
      severity: severity,
      severityColor: color,
      treatmentSteps: List<String>.from((data['treatments'] as List?) ?? []),
      treatmentStepsHindi: List<String>.from((data['treatmentsHindi'] as List?) ?? []),
      imagePath: imagePath,
      icon: icon,
      lowConfidence: (data['lowConfidence'] as bool?) ?? false,
      lowConfidenceMessage: data['lowConfidenceMessage'] as String?,
    );
  }

  /// Legacy factory for mock data (kept for backward compat).
  factory DiseaseResult.fromMap(Map<String, dynamic> data, String imagePath) {
    return DiseaseResult(
      name: data['name'] as String,
      nameHindi: data['nameHindi'] as String,
      cropType: data['crop'] as String,
      confidencePercent: data['confidence'] as int,
      severity: data['severity'] as String,
      severityColor: Color(data['color'] as int),
      treatmentSteps: List<String>.from(data['treatment'] as List),
      treatmentStepsHindi: List<String>.from(data['treatmentHindi'] as List),
      imagePath: imagePath,
      icon: data['icon'] as String,
    );
  }
}
