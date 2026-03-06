import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/weather_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/feature_card.dart';
import '../widgets/language_selection_dialog.dart';
import 'disease_screen.dart';
import 'mandi_screen.dart';
import 'voice_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) => SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            langProvider.t('greeting'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Language change button
                        GestureDetector(
                          onTap: () => LanguageSelectionDialog.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white38, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  langProvider.currentLanguage.flag,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  langProvider.currentLanguage.nativeName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.expand_more,
                                    color: Colors.white, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<WeatherProvider>(
                      builder: (context, weather, _) {
                        final locationText =
                            weather.status == WeatherStatus.loaded
                                ? weather.weatherData!.locationName
                                : 'Loading...';
                        final tempText =
                            weather.status == WeatherStatus.loaded
                                ? '${weather.weatherData!.temperature.round()}°C'
                                : weather.status == WeatherStatus.error
                                    ? '--°C'
                                    : '...';
                        return Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              locationText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.cloud,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              tempText,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Feature Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        langProvider.t('what_to_do'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        langProvider.t('what_to_do_sub'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Feature Cards
              FeatureCard(
                icon: Icons.mic_rounded,
                titleHi: langProvider.t('voice_title'),
                titleEn: langProvider.t('voice_sub'),
                subtitleHi: langProvider.t('voice_sub'),
                subtitleEn: langProvider.t('voice_sub'),
                badge: 'AI Powered',
                color: AppColors.voiceGreen,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VoiceChatScreen(),
                    ),
                  );
                },
              ),
              FeatureCard(
                icon: Icons.camera_alt_rounded,
                titleHi: langProvider.t('disease_title'),
                titleEn: langProvider.t('disease_sub'),
                subtitleHi: langProvider.t('disease_sub'),
                subtitleEn: langProvider.t('disease_sub'),
                badge: 'Photo Analysis',
                color: AppColors.diseaseOrange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiseaseScreen(),
                    ),
                  );
                },
              ),
              FeatureCard(
                icon: Icons.trending_up_rounded,
                titleHi: langProvider.t('mandi_title'),
                titleEn: langProvider.t('mandi_sub'),
                subtitleHi: langProvider.t('mandi_sub'),
                subtitleEn: langProvider.t('mandi_sub'),
                badge: 'Live Prices',
                color: AppColors.mandiBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MandiScreen(),
                    ),
                  );
                },
              ),
              // Quick Stats
              Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          '4',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          langProvider.t('crops_label'),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Column(
                      children: [
                        const Text(
                          '₹2,180',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          langProvider.t('wheat_label'),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.shade300,
                    ),
                    Consumer<WeatherProvider>(
                      builder: (context, weather, _) {
                        final tempText =
                            weather.status == WeatherStatus.loaded
                                ? '${weather.weatherData!.temperature.round()}°C'
                                : weather.status == WeatherStatus.loading
                                    ? '...'
                                    : '--°C';
                        final conditionText =
                            weather.status == WeatherStatus.loaded
                                ? weather.weatherData!.condition
                                : 'Weather';
                        return Column(
                          children: [
                            Text(
                              tempText,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              conditionText,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary.withOpacity(0.6),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
