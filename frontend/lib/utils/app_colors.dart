import 'package:flutter/material.dart';

class AppColors {
  // Primary theme
  static const Color primary = Color(0xFF4CAF50);        // Agriculture green (seed color)
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primaryLight = Color(0xFFC8E6C9);

  // Accent colors
  static const Color accent = Color(0xFFFF9800);         // Orange for disease alerts
  static const Color warning = Color(0xFFF44336);        // Red for high severity
  static const Color background = Color(0xFFF1F8E9);     // Very light green
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF1B5E20);    // Dark green
  static const Color textSecondary = Color(0xFF4E4E4E);  // Gray

  // Recommendation colors
  static const Color recommendSell = Color(0xFF2E7D32);  // Dark green
  static const Color recommendHold = Color(0xFF1976D2);  // Blue
  static const Color recommendWait = Color(0xFFFF8F00);  // Amber/Orange

  // Feature screen colors
  static const Color voiceGreen = Color(0xFF4CAF50);
  static const Color diseaseOrange = Color(0xFFFF9800);
  static const Color mandiBlue = Color(0xFF1976D2);

  // Severity colors
  static const Color severityHigh = Color(0xFFF44336);   // Red
  static const Color severityMedium = Color(0xFFFF9800); // Orange
  static const Color severityLow = Color(0xFFFFC107);    // Amber
  static const Color severityNone = Color(0xFF4CAF50);   // Green
}
