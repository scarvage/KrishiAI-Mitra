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
  });

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
