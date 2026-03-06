import 'package:flutter/material.dart';

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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: currentLanguage != 'hi' ? onToggle : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: currentLanguage == 'hi'
                    ? Colors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'हिंदी',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: currentLanguage == 'hi'
                      ? Colors.black87
                      : Colors.white,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: currentLanguage != 'en' ? onToggle : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: currentLanguage == 'en'
                    ? Colors.white
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: currentLanguage == 'en'
                      ? Colors.black87
                      : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
