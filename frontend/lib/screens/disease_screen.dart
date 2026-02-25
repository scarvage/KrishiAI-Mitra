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
        title: const Text('फसल की बीमारी'),
        backgroundColor: AppColors.diseaseOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Consumer<DiseaseProvider>(
              builder: (context, provider, _) {
                return LanguageToggle(
                  currentLanguage: provider.language,
                  onToggle: () => provider.toggleLanguage(),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<DiseaseProvider>(
        builder: (context, provider, _) {
          // Empty state
          if (provider.imagePath == null && provider.result == null) {
            return _EmptyState(provider: provider);
          }

          // Analyzing state
          if (provider.isAnalyzing) {
            return _AnalyzingState(imagePath: provider.imagePath!);
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
            const Text(
              'पत्ती की फोटो लें',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo of the leaf',
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
                label: const Text('Camera से Photo लें'),
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
                label: const Text('Gallery से चुनें'),
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

  const _AnalyzingState({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 180,
              height: 200,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: AppColors.diseaseOrange),
          const SizedBox(height: 16),
          const Text(
            'AI विश्लेषण कर रहा है...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait 2-3 seconds',
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
    final treatmentSteps = provider.language == 'hi'
        ? result.treatmentStepsHindi
        : result.treatmentSteps;

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
              height: 220,
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
                  result.nameHindi,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                // Confidence bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${provider.language == 'hi' ? 'आत्मविश्वास' : 'Confidence'}:',
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
          const SizedBox(height: 16),
          // Crop type
          Text(
            provider.language == 'hi' ? 'फसल का प्रकार' : 'Crop Type',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.cropType,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          // Treatment steps
          Text(
            provider.language == 'hi' ? 'उपचार के कदम' : 'Treatment Steps',
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
          const SizedBox(height: 20),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => provider.reset(),
                  child: const Text('फिर से स्कैन करें'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Results shared!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('शेयर करें'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
