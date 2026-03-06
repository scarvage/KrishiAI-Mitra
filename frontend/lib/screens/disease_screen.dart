import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/disease_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/language_toggle.dart';

class DiseaseScreen extends StatelessWidget {
  const DiseaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DiseaseProvider>(
          builder: (context, provider, _) {
            final isHi = provider.language == 'hi';
            return Text(isHi ? 'फसल की बीमारी' : 'Crop Disease');
          },
        ),
        backgroundColor: AppColors.diseaseOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Consumer<DiseaseProvider>(
                builder: (context, provider, _) {
                  return LanguageToggle(
                    currentLanguage: provider.language,
                    onToggle: () => provider.toggleLanguage(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Consumer<DiseaseProvider>(
        builder: (context, provider, _) {
          // Empty state
          if (provider.imagePath == null && provider.result == null && provider.error == null) {
            return _EmptyState(provider: provider);
          }

          // Analyzing state
          if (provider.isAnalyzing) {
            return _AnalyzingState(imagePath: provider.imagePath!, isHi: provider.language == 'hi');
          }

          // Error state
          if (provider.error != null) {
            return _ErrorState(provider: provider);
          }

          // Result state
          if (provider.result != null) {
            return _ResultState(provider: provider);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final DiseaseProvider provider;

  const _EmptyState({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isHi = provider.language == 'hi';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.diseaseOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.image_rounded,
                color: AppColors.diseaseOrange,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isHi ? 'पत्ती की फोटो लें' : 'Take a Photo of the Leaf',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isHi ? 'AI बीमारी पहचानेगा' : 'AI will identify the disease',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () =>
                    provider.pickAndAnalyze(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: Text(isHi ? 'कैमरा से फोटो लें' : 'Take Photo'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () =>
                    provider.pickAndAnalyze(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(isHi ? 'गैलरी से चुनें' : 'Choose from Gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingState extends StatelessWidget {
  final String imagePath;
  final bool isHi;

  const _AnalyzingState({required this.imagePath, required this.isHi});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.25,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: AppColors.diseaseOrange),
          const SizedBox(height: 16),
          Text(
            isHi ? 'AI विश्लेषण कर रहा है...' : 'AI is analyzing...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isHi ? 'कृपया 2-3 सेकंड प्रतीक्षा करें' : 'Please wait 2-3 seconds',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultState extends StatelessWidget {
  final DiseaseProvider provider;

  const _ResultState({required this.provider});

  @override
  Widget build(BuildContext context) {
    final result = provider.result!;
    final isHi = provider.language == 'hi';
    final treatmentSteps = isHi
        ? result.treatmentStepsHindi
        : result.treatmentSteps;
    // Primary = localized name, secondary = the other language
    final primaryName = isHi ? result.nameHindi : result.name;
    final secondaryName = isHi ? result.name : result.nameHindi;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.27,
              child: Image.file(
                File(result.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Disease name banner
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: result.severityColor.withOpacity(0.1),
              border: Border.all(color: result.severityColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  result.icon,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  primaryName.isNotEmpty ? primaryName : result.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (secondaryName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondaryName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Confidence bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${isHi ? 'आत्मविश्वास' : 'Confidence'}:',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          '${result.confidencePercent}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: result.confidencePercent / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          result.severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Treatment steps
          Text(
            isHi ? 'उपचार के कदम' : 'Treatment Steps',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            treatmentSteps.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      treatmentSteps[index],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Low-confidence warning banner
          if (result.lowConfidence && result.lowConfidenceMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.lowConfidenceMessage!,
                      style: const TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => provider.reset(),
                  child: Text(isHi ? 'फिर से स्कैन करें' : 'Scan Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isHi ? 'परिणाम साझा किए गए!' : 'Results shared!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(isHi ? 'शेयर करें' : 'Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final DiseaseProvider provider;

  const _ErrorState({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              provider.language == 'hi' ? 'विश्लेषण विफल' : 'Analysis Failed',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => provider.reset(),
                icon: const Icon(Icons.refresh),
                label: Text(provider.language == 'hi' ? 'पुनः प्रयास करें' : 'Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
