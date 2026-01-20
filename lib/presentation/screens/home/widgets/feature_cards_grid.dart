import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class FeatureCardsGrid extends StatelessWidget {
  const FeatureCardsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _FeatureCard(
                title: AppStrings.nearbyStudios,
                badge: AppStrings.lowestPriceDiscount,
                height: 200,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
                ),
                icon: Icons.location_on,
                onTap: () {
                  // TODO: Navigate to nearby studios
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _FeatureCard(
                    title: AppStrings.findOnMap,
                    height: 94,
                    icon: Icons.map_outlined,
                    onTap: () {
                      // TODO: Navigate to map
                    },
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    title: AppStrings.priceComparison,
                    height: 94,
                    icon: Icons.compare_arrows,
                    onTap: () {
                      // TODO: Navigate to price comparison
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String? badge;
  final double height;
  final IconData icon;
  final Gradient? gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    this.badge,
    required this.height,
    required this.icon,
    this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? AppColors.surface : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                icon,
                color: AppColors.primary.withValues(alpha: 0.7),
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
