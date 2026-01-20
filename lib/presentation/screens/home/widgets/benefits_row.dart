import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class BenefitsRow extends StatelessWidget {
  const BenefitsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _BenefitItem(
            icon: Icons.verified,
            label: AppStrings.lowestPriceGuarantee,
            color: AppColors.success,
          ),
          const SizedBox(width: 24),
          _BenefitItem(
            icon: Icons.calendar_month,
            label: AppStrings.paymentBenefits,
            color: AppColors.primary,
          ),
          const SizedBox(width: 24),
          _BenefitItem(
            icon: Icons.credit_card,
            label: AppStrings.interestFreeInstallment,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BenefitItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
