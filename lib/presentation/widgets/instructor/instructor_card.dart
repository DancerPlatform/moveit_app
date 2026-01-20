import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/instructor.dart';

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
      InstructorCardVariant.compact => _buildCompactCard(),
      InstructorCardVariant.standard => _buildStandardCard(),
      InstructorCardVariant.grid => _buildGridCard(),
    };
  }

  /// Compact card for horizontal lists
  Widget _buildCompactCard() {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width ?? 120,
        child: Column(
          children: [
            _buildProfileImage(size: 80),
            const SizedBox(height: 8),
            Text(
              instructor.displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (instructor.specialtyList.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                instructor.specialtyList.first,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Standard list tile card
  Widget _buildStandardCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                children: [
                  Text(
                    instructor.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (instructor.specialtyList.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: instructor.specialtyList.take(3).map((specialty) {
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
                            specialty,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (instructor.bio != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      instructor.bio!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
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
  Widget _buildGridCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildProfileImage(size: 80),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    instructor.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (instructor.specialtyList.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      instructor.specialtyList.take(2).join(', '),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
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
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
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
