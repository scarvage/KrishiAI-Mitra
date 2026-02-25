import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class LanguageToggle extends StatelessWidget {
  final String currentLanguage;
  final VoidCallback onToggle;

  const LanguageToggle({
    Key? key,
    required this.currentLanguage,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: currentLanguage != 'hi' ? onToggle : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: currentLanguage == 'hi'
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'हिंदी',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: currentLanguage == 'hi'
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: currentLanguage != 'en' ? onToggle : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: currentLanguage == 'en'
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: currentLanguage == 'en'
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
