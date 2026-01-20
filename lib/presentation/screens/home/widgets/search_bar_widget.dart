import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to search screen
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.searchHint,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.search,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
