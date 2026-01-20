import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/academy.dart';
import '../../../data/models/dance_class.dart';
import '../../../data/models/hall.dart';
import '../../../data/models/instructor.dart';
import '../../../data/repositories/academy_repository.dart';

class AcademyDetailScreen extends StatefulWidget {
  final String academyId;

  const AcademyDetailScreen({
    super.key,
    required this.academyId,
  });

  @override
  State<AcademyDetailScreen> createState() => _AcademyDetailScreenState();
}

class _AcademyDetailScreenState extends State<AcademyDetailScreen> {
  final AcademyRepository _repository = AcademyRepository();
  final PageController _imagePageController = PageController();

  bool _isLoading = true;
  String? _errorMessage;
  AcademyDetails? _details;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAcademyDetails();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadAcademyDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _repository.getAcademyDetails(widget.academyId);
      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
          if (details == null) {
            _errorMessage = '학원 정보를 찾을 수 없습니다.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '정보를 불러오는 중 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _details != null
                  ? _buildContent()
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAcademyDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final academy = _details!.academy;

    return CustomScrollView(
      slivers: [
        _buildAppBar(academy),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(academy),
              if (academy.tagList.isNotEmpty) _buildTags(academy),
              _buildContactInfo(academy),
              _buildSocialLinks(academy),
              if (_details!.instructors.isNotEmpty)
                _buildInstructorsSection(_details!.instructors),
              if (_details!.classes.isNotEmpty)
                _buildClassesSection(_details!.classes),
              if (_details!.halls.isNotEmpty)
                _buildHallsSection(_details!.halls),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(Academy academy) {
    final images = academy.images;
    final hasImages = images.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: hasImages
            ? Stack(
                children: [
                  PageView.builder(
                    controller: _imagePageController,
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index].url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      );
                    },
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : academy.logoUrl != null
                ? Image.network(
                    academy.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.business_outlined,
          color: AppColors.textHint,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildBasicInfo(Academy academy) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (academy.logoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    academy.logoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      academy.displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (academy.nameEn != null && academy.nameKr != null)
                      Text(
                        academy.nameEn!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTags(Academy academy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: academy.tagList.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactInfo(Academy academy) {
    final hasAddress = academy.address != null;
    final hasPhone = academy.contactNumber != null;

    if (!hasAddress && !hasPhone) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (hasAddress)
              _buildInfoRow(
                icon: Icons.location_on_outlined,
                text: academy.address!,
                onTap: () {
                  final query = Uri.encodeComponent(academy.address!);
                  _launchUrl('https://maps.google.com/?q=$query');
                },
              ),
            if (hasAddress && hasPhone) const Divider(color: AppColors.divider),
            if (hasPhone)
              _buildInfoRow(
                icon: Icons.phone_outlined,
                text: academy.contactNumber!,
                onTap: () => _makePhoneCall(academy.contactNumber!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks(Academy academy) {
    final links = <_SocialLink>[];

    if (academy.instagramHandle != null) {
      links.add(_SocialLink(
        icon: Icons.camera_alt_outlined,
        label: 'Instagram',
        url: 'https://instagram.com/${academy.instagramHandle}',
      ));
    }
    if (academy.youtubeUrl != null) {
      links.add(_SocialLink(
        icon: Icons.play_circle_outline,
        label: 'YouTube',
        url: academy.youtubeUrl!,
      ));
    }
    if (academy.tiktokHandle != null) {
      links.add(_SocialLink(
        icon: Icons.music_note_outlined,
        label: 'TikTok',
        url: 'https://tiktok.com/@${academy.tiktokHandle}',
      ));
    }
    if (academy.websiteUrl != null) {
      links.add(_SocialLink(
        icon: Icons.language_outlined,
        label: '웹사이트',
        url: academy.websiteUrl!,
      ));
    }

    if (links.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: links.map((link) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => _launchUrl(link.url),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(link.icon, color: AppColors.textPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      link.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                '전체보기',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructorsSection(List<Instructor> instructors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('강사진'),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: instructors.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildInstructorCard(instructors[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstructorCard(Instructor instructor) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: instructor.profileImageUrl != null
                ? Image.network(
                    instructor.profileImageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInstructorPlaceholder(),
                  )
                : _buildInstructorPlaceholder(),
          ),
          const SizedBox(height: 8),
          Text(
            instructor.displayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (instructor.specialtyList.isNotEmpty)
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
      ),
    );
  }

  Widget _buildInstructorPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.textHint,
        size: 36,
      ),
    );
  }

  Widget _buildClassesSection(List<DanceClass> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('수업'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: classes.length > 5 ? 5 : classes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildClassCard(classes[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClassCard(DanceClass danceClass) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: danceClass.thumbnailUrl != null
                ? Image.network(
                    danceClass.thumbnailUrl!,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildClassPlaceholder(),
                  )
                : _buildClassPlaceholder(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  danceClass.displayTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (danceClass.genre != null)
                  Text(
                    danceClass.genre!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (danceClass.difficultyLevel != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          danceClass.difficultyLevel!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (danceClass.classType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          danceClass.classType!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.surfaceLight,
      child: const Icon(
        Icons.music_note,
        color: AppColors.textHint,
        size: 28,
      ),
    );
  }

  Widget _buildHallsSection(List<Hall> halls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('시설'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: halls.map((hall) => _buildHallChip(hall)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHallChip(Hall hall) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.meeting_room_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            hall.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          if (hall.capacity > 0) ...[
            const SizedBox(width: 8),
            Text(
              '(${hall.capacity}명)',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String label;
  final String url;

  const _SocialLink({
    required this.icon,
    required this.label,
    required this.url,
  });
}