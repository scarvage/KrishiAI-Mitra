import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mandi_price.dart';
import '../providers/mandi_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/language_toggle.dart';
import '../widgets/price_trend_bar.dart';

class MandiScreen extends StatefulWidget {
  const MandiScreen({Key? key}) : super(key: key);

  @override
  State<MandiScreen> createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MandiProvider>().loadPrices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('मंडी भाव'),
        backgroundColor: AppColors.mandiBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Consumer<MandiProvider>(
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
      body: Consumer<MandiProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'सभी',
                      isSelected: provider.selectedCommodity == 'All',
                      onTap: () => provider.selectCommodity('All'),
                    ),
                    _FilterChip(
                      label: 'गेहूं',
                      isSelected: provider.selectedCommodity == 'Wheat',
                      onTap: () => provider.selectCommodity('Wheat'),
                    ),
                    _FilterChip(
                      label: 'सोयाबीन',
                      isSelected: provider.selectedCommodity == 'Soybean',
                      onTap: () => provider.selectCommodity('Soybean'),
                    ),
                    _FilterChip(
                      label: 'प्याज',
                      isSelected: provider.selectedCommodity == 'Onion',
                      onTap: () => provider.selectCommodity('Onion'),
                    ),
                    _FilterChip(
                      label: 'कपास',
                      isSelected: provider.selectedCommodity == 'Cotton',
                      onTap: () => provider.selectCommodity('Cotton'),
                    ),
                  ],
                ),
              ),
              // Last updated
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    provider.language == 'hi'
                        ? 'अंतिम अपडेट: आज 2:30 PM'
                        : 'Last update: Today 2:30 PM',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Price cards list
              if (provider.isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.mandiBlue),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: provider.filteredPrices.length,
                    itemBuilder: (context, index) {
                      final price = provider.filteredPrices[index];
                      return _PriceCard(
                        price: price,
                        language: provider.language,
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: AppColors.mandiBlue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.mandiBlue : Colors.grey.shade300,
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final MandiPrice price;
  final String language;

  const _PriceCard({
    required this.price,
    required this.language,
  });

  Color _getRecommendationColor() {
    switch (price.recommendation) {
      case 'SELL':
        return AppColors.recommendSell;
      case 'WAIT':
        return AppColors.recommendWait;
      case 'HOLD':
      default:
        return AppColors.recommendHold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendColor = _getRecommendationColor();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with recommendation badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        price.commodity,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price.market,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: recommendColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    price.recommendation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Price row
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹${price.currentPrice.toString()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'per quintal',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                      if (price.hasMSP()) ...[
                        const SizedBox(height: 2),
                        Text(
                          'MSP: ₹${price.mspPrice}',
                          style: TextStyle(
                            fontSize: 12,
                            color: price.getPriceDifference() >= 0
                                ? AppColors.recommendSell
                                : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Trend bar
            PriceTrendBar(weeklyPrices: price.weeklyPrices),
            const SizedBox(height: 12),
            // Recommendation text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: recommendColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: recommendColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                language == 'hi' ? price.reasonHi : price.reasonEn,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
