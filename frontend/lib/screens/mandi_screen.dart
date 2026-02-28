import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mandi_price.dart';
import '../providers/mandi_provider.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class MandiScreen extends StatelessWidget {
  const MandiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('मंडी भाव'),
        backgroundColor: AppColors.mandiBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<MandiProvider>(
            builder: (context, provider, _) {
              if (!provider.hasData) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: () => provider.fetchPrices(),
              );
            },
          ),
        ],
      ),
      body: Consumer<MandiProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const _LoadingView();
          }
          if (provider.hasData || provider.hasError) {
            return _ResultsView(provider: provider);
          }
          return const _SelectionView();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: State + Crop selection
// ─────────────────────────────────────────────────────────────────────────────

class _SelectionView extends StatefulWidget {
  const _SelectionView();

  @override
  State<_SelectionView> createState() => _SelectionViewState();
}

class _SelectionViewState extends State<_SelectionView> {
  String? _selectedState;
  String? _selectedCrop;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MandiProvider>();
    final canFetch = _selectedState != null && _selectedCrop != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.mandiBlue, AppColors.mandiBlue.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_up_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text(
                  'मंडी भाव जाँचें',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI द्वारा विश्लेषण और सलाह पाएं',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // State dropdown
          const Text(
            'राज्य चुनें',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          _Dropdown(
            hint: 'अपना राज्य चुनें',
            value: _selectedState,
            items: kIndianStates,
            onChanged: (v) => setState(() => _selectedState = v),
          ),

          const SizedBox(height: 24),

          // Crop grid
          const Text(
            'फसल चुनें',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: kMajorCrops.length,
            itemBuilder: (context, index) {
              final crop = kMajorCrops[index];
              final isSelected = _selectedCrop == crop['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedCrop = crop['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mandiBlue : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.mandiBlue
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.mandiBlue.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(crop['emoji']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        crop['hi']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Fetch button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: canFetch
                  ? () {
                      provider.fetchPrices(
                        crop: _selectedCrop,
                        state: _selectedState,
                      );
                    }
                  : null,
              icon: const Icon(Icons.search_rounded),
              label: const Text(
                'भाव देखें',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mandiBlue,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading view
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.mandiBlue),
          const SizedBox(height: 20),
          Text(
            'AI सलाह तैयार हो रही है...',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Results view
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final MandiProvider provider;

  const _ResultsView({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-header with crop/state info + back button
        Container(
          color: AppColors.mandiBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${provider.selectedCrop} · ${provider.selectedState}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => provider.reset(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 16),
                label: const Text(
                  'बदलें',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
        ),

        Expanded(
          child: provider.hasError
              ? _ErrorView(
                  message: provider.errorMessage ?? 'Something went wrong',
                  onRetry: () => provider.fetchPrices(),
                )
              : RefreshIndicator(
                  color: AppColors.mandiBlue,
                  onRefresh: () => provider.fetchPrices(),
                  child: _PriceResultsList(provider: provider),
                ),
        ),
      ],
    );
  }
}

class _PriceResultsList extends StatelessWidget {
  final MandiProvider provider;

  const _PriceResultsList({required this.provider});

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // AI Recommendation card
        _AiRecommendationCard(recommendation: provider.recommendation),
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            _StatBadge(
              label: 'मंडियां',
              value: '${provider.totalMandis}',
              icon: Icons.store_rounded,
            ),
            const SizedBox(width: 12),
            if (provider.lastUpdated != null)
              _StatBadge(
                label: 'अपडेट',
                value: _formatDate(provider.lastUpdated!),
                icon: Icons.access_time_rounded,
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (provider.prices.isEmpty)
          const _EmptyPricesCard()
        else
          ...provider.prices.map((price) => _PriceCard(price: price)),
      ],
    );
  }
}

class _AiRecommendationCard extends StatelessWidget {
  final String recommendation;

  const _AiRecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), AppColors.mandiBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.mandiBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI सलाह',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.isEmpty ? 'कोई सलाह उपलब्ध नहीं है।' : recommendation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final ApiMandiPrice price;

  const _PriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mandi name
            Row(
              children: [
                const Icon(Icons.store_rounded, size: 16, color: AppColors.mandiBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    price.mandi,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ],
            ),
            if (price.district.isNotEmpty) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  price.district,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Modal price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${price.modalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'प्रति क्विंटल',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Min / Max / Date tags
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Tag(
                  label: 'न्यूनतम ₹${price.minPrice.toStringAsFixed(0)}',
                  color: Colors.orange.shade700,
                ),
                _Tag(
                  label: 'अधिकतम ₹${price.maxPrice.toStringAsFixed(0)}',
                  color: AppColors.recommendSell,
                ),
                if (price.variety.isNotEmpty)
                  _Tag(label: price.variety, color: Colors.grey.shade600),
                if (price.arrivalDate != null)
                  _Tag(label: price.arrivalDate!, color: Colors.blueGrey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatBadge({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mandiBlue),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPricesCard extends StatelessWidget {
  const _EmptyPricesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'इस फसल का डेटा उपलब्ध नहीं है',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('पुनः प्रयास करें'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<MandiProvider>().reset(),
              child: const Text('वापस जाएं'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable dropdown widget
// ─────────────────────────────────────────────────────────────────────────────

class _Dropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
