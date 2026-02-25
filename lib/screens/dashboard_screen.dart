import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/feature_card.dart';
import 'disease_screen.dart';
import 'mandi_screen.dart';
import 'voice_chat_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'नमस्ते, किसान भाई!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hello, Farmer!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Indore, MP',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.cloud, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '28°C',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                    const Text(
                      'क्या करना है?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What would you like to do?',
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
              titleHi: 'आवाज़ से पूछो',
              titleEn: 'Ask by Voice',
              subtitleHi: 'AI मित्र से सवाल पूछें',
              subtitleEn: 'Ask farming questions',
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
              titleHi: 'फसल की बीमारी',
              titleEn: 'Disease Check',
              subtitleHi: 'फोटो से रोग पहचानें',
              subtitleEn: 'Detect crop disease',
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
              titleHi: 'मंडी भाव',
              titleEn: 'Market Prices',
              subtitleHi: 'रीयल-टाइम फसल भाव',
              subtitleEn: 'Real-time crop prices',
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
                        'Crops',
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
                        'Wheat Price',
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
                        '28°C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Weather',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
