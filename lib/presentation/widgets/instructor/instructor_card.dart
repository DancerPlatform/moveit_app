import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/instructor.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/favorite_provider.dart';

/// Display variants for instructor cards
enum InstructorCardVariant {
  compact,
  standard,
  grid,
}

/// A reusable card widget for displaying instructor information.
class InstructorCard extends StatelessWidget {
  final Instructor instructor;
  final InstructorCardVariant variant;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const InstructorCard({
    super.key,
    required this.instructor,
    this.variant = InstructorCardVariant.standard,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      InstructorCardVariant.compact => _buildCompactCard(context),
      InstructorCardVariant.standard => _buildStandardCard(context),
      InstructorCardVariant.grid => _buildGridCard(context),
    };
  }

  /// Compact card for horizontal lists
  Widget _buildCompactCard(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final isFavorite = favoriteProvider.isInstructorFavorite(instructor.id);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width ?? 120,
        height: height ?? 150,
        child: Column(
          children: [
            Stack(
              children: [
                _buildProfileImage(size: 80),
                if (isLoggedIn)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => favoriteProvider
                          .toggleInstructorFavorite(instructor.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.primary : Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildNameRow(fontSize: 13, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              instructor.specialtyList.isNotEmpty
                  ? instructor.specialtyList.first
                  : '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Standard list tile card
  Widget _buildStandardCard(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final isFavorite = favoriteProvider.isInstructorFavorite(instructor.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 88,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildProfileImage(size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNameRow(fontSize: 15),
                  const SizedBox(height: 4),
                  if (instructor.specialtyList.isNotEmpty)
                    SizedBox(
                      height: 20,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: instructor.specialtyList.take(3).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              instructor.specialtyList[index],
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLoggedIn)
              GestureDetector(
                onTap: () =>
                    favoriteProvider.toggleInstructorFavorite(instructor.id),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${instructor.likeCount}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${instructor.likeCount}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Grid card for grid layouts
  Widget _buildGridCard(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final favoriteProvider = context.watch<FavoriteProvider>();
    final isFavorite = favoriteProvider.isInstructorFavorite(instructor.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height ?? 190,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Stack(
              children: [
                _buildProfileImage(size: 80),
                if (isLoggedIn)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => favoriteProvider
                          .toggleInstructorFavorite(instructor.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.primary : Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _buildNameRow(fontSize: 14, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(
                      instructor.specialtyList.isNotEmpty
                          ? instructor.specialtyList.take(2).join(', ')
                          : '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${instructor.likeCount}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the name row with Korean name and optional English name
  Widget _buildNameRow({
    required double fontSize,
    TextAlign textAlign = TextAlign.start,
  }) {
    final hasEnglishName = instructor.nameEn != null && instructor.nameEn!.isNotEmpty;

    return Row(
      mainAxisSize: textAlign == TextAlign.center ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: textAlign == TextAlign.center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            instructor.displayName,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          ),
        ),
        if (hasEnglishName && instructor.nameKr != null) ...[
          const SizedBox(width: 6),
          Text(
            instructor.nameEn!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: fontSize - 2,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Builds the circular profile image
  Widget _buildProfileImage({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceLight,
        image: instructor.profileImageUrl != null
            ? DecorationImage(
                image: NetworkImage(instructor.profileImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: instructor.profileImageUrl == null
          ? Icon(
              Icons.person,
              size: size * 0.5,
              color: AppColors.textHint,
            )
          : null,
    );
  }
}
