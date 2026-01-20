import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../search/search_screen.dart';

class Categories extends StatelessWidget {
  const Categories({super.key});

  static const List<_CategoryItem> _categories = [
    _CategoryItem(label: AppStrings.categoryAll, icon: Icons.apps),
    _CategoryItem(label: AppStrings.categoryKpop, icon: Icons.music_note),
    _CategoryItem(label: AppStrings.categoryHiphop, icon: Icons.headphones),
    _CategoryItem(label: AppStrings.categoryJazz, icon: Icons.piano),
    _CategoryItem(label: AppStrings.categoryBallet, icon: Icons.sports_gymnastics),
    _CategoryItem(label: AppStrings.categoryContemporary, icon: Icons.self_improvement),
    _CategoryItem(label: AppStrings.categoryLatin, icon: Icons.favorite),
    _CategoryItem(label: AppStrings.categoryStreet, icon: Icons.skateboarding),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategoryButton(
            icon: category.icon,
            label: category.label,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SearchScreen(
                    initialCategory: category.label,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;

  const _CategoryItem({required this.label, required this.icon});
}

class _CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
