import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class PriceTrendBar extends StatelessWidget {
  final List<int> weeklyPrices;

  const PriceTrendBar({Key? key, required this.weeklyPrices}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weeklyPrices.isEmpty) return const SizedBox.shrink();

    final maxPrice = weeklyPrices.reduce((a, b) => a > b ? a : b).toDouble();
    final minPrice = weeklyPrices.reduce((a, b) => a < b ? a : b).toDouble();
    final range = maxPrice - minPrice;
    final maxBarHeight = 60.0;

    return SizedBox(
      height: maxBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          weeklyPrices.length,
          (index) {
            final price = weeklyPrices[index].toDouble();
            final normalizedHeight = range == 0
                ? maxBarHeight / 2
                : ((price - minPrice) / range) * maxBarHeight;
            final isLastBar = index == weeklyPrices.length - 1;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    height: normalizedHeight,
                    decoration: BoxDecoration(
                      color: isLastBar
                          ? AppColors.primary
                          : AppColors.primaryLight,
                      borderRadius:
                          const BorderRadius.only(topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
