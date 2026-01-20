import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/academy.dart';

/// A reusable card widget for displaying academy information.
///
/// Supports multiple display variants:
/// - [AcademyCardVariant.compact] - Small horizontal card (for horizontal lists)
/// - [AcademyCardVariant.standard] - Medium vertical card (for grids)
/// - [AcademyCardVariant.detailed] - Large card with more details (for featured sections)
class AcademyCard extends StatelessWidget {
  final Academy academy;
  final AcademyCardVariant variant;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  /// Optional distance string to display (e.g., "1.2km")
  final String? distance;

  const AcademyCard({
    super.key,
    required this.academy,
    this.variant = AcademyCardVariant.standard,
    this.onTap,
    this.width,
    this.height,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AcademyCardVariant.compact => _buildCompactCard(),
      AcademyCardVariant.standard => _buildStandardCard(),
      AcademyCardVariant.detailed => _buildDetailedCard(),
      AcademyCardVariant.listTile => _buildListTileCard(),
    };
  }

  /// Compact horizontal card for horizontal scroll lists
  Widget _buildCompactCard() {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width ?? 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildImageContainer(height: 120),
            const SizedBox(height: 10),
            // Name
            Text(
              academy.displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Tags
            if (academy.tagList.isNotEmpty)
              Text(
                academy.tagList.take(2).join(', '),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            // Distance or Address
            if (distance != null)
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textHint,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    distance!,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            else if (academy.address != null)
              Text(
                academy.address!,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  /// Standard vertical card for grid displays
  Widget _buildStandardCard() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildImageContainer(height: height ?? 140),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    academy.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Tags as chips
                  if (academy.tagList.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: academy.tagList.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Address
                  if (academy.address != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            academy.address!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  /// Detailed card with social links and full information
  Widget _buildDetailedCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildImageContainer(height: height ?? 180),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and logo row
                  Row(
                    children: [
                      if (academy.logoUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            academy.logoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 40,
                              height: 40,
                              color: AppColors.surfaceLight,
                              child: const Icon(
                                Icons.business,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              academy.displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (academy.nameEn != null && academy.nameKr != null)
                              Text(
                                academy.nameEn!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  if (academy.tagList.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: academy.tagList.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Address
                  if (academy.address != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            academy.address!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Contact
                  if (academy.contactNumber != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          academy.contactNumber!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Social links
                  _buildSocialLinks(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal list tile with image on left
  Widget _buildListTileCard() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image on left
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: height ?? 100,
                height: height ?? 100,
                child: academy.primaryImageUrl != null
                    ? Image.network(
                        academy.primaryImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            const SizedBox(width: 16),
            // Content on right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    academy.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Distance and/or Address
                  if (distance != null || academy.address != null) ...[
                    Row(
                      children: [
                        if (distance != null) ...[
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (academy.address != null) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '·',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                        if (academy.address != null)
                          Expanded(
                            child: Text(
                              academy.address!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Tags
                  if (academy.tagList.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: academy.tagList.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.textHint.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContainer({required double height}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: variant == AcademyCardVariant.compact
              ? BorderRadius.circular(12)
              : BorderRadius.zero,
          child: Container(
            height: height,
            width: double.infinity,
            color: AppColors.surface,
            child: academy.primaryImageUrl != null
                ? Image.network(
                    academy.primaryImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),
        ),
        // Active badge
        if (!academy.isActive)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Inactive',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.business_outlined,
        color: AppColors.textHint,
        size: 40,
      ),
    );
  }

  Widget _buildSocialLinks() {
    final hasSocialLinks = academy.instagramHandle != null ||
        academy.youtubeUrl != null ||
        academy.tiktokHandle != null ||
        academy.websiteUrl != null;

    if (!hasSocialLinks) return const SizedBox.shrink();

    return Row(
      children: [
        if (academy.instagramHandle != null)
          _buildSocialIcon(Icons.camera_alt_outlined, 'Instagram'),
        if (academy.youtubeUrl != null)
          _buildSocialIcon(Icons.play_circle_outline, 'YouTube'),
        if (academy.tiktokHandle != null)
          _buildSocialIcon(Icons.music_note_outlined, 'TikTok'),
        if (academy.websiteUrl != null)
          _buildSocialIcon(Icons.language_outlined, 'Website'),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String tooltip) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

/// Display variants for AcademyCard
enum AcademyCardVariant {
  /// Small horizontal card for horizontal scroll lists
  compact,

  /// Medium vertical card for grid displays
  standard,

  /// Large card with full details for featured sections
  detailed,

  /// Horizontal list tile with image on left
  listTile,
}
