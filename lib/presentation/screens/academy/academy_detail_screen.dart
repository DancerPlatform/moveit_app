import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _AcademyDetailScreenState extends State<AcademyDetailScreen>
    with SingleTickerProviderStateMixin {
  final AcademyRepository _repository = AcademyRepository();
  final PageController _imagePageController = PageController();
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;
  AcademyDetails? _details;
  int _currentImageIndex = 0;

  // Class sorting
  String _classSortBy = 'date'; // 'date', 'name', 'price'
  bool _classSortAscending = true;

  // Calendar
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAcademyDetails();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<DanceClass> get _sortedClasses {
    if (_details == null) return [];
    final classes = List<DanceClass>.from(_details!.classes);

    classes.sort((a, b) {
      int comparison;
      switch (_classSortBy) {
        case 'date':
          final aTime = a.startTime ?? DateTime(2100);
          final bTime = b.startTime ?? DateTime(2100);
          comparison = aTime.compareTo(bTime);
          break;
        case 'name':
          comparison = a.displayTitle.compareTo(b.displayTitle);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        default:
          comparison = 0;
      }
      return _classSortAscending ? comparison : -comparison;
    });

    return classes;
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

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          _buildAppBar(academy),
          SliverToBoxAdapter(
            child: _buildBasicInfo(academy),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: '홈'),
                  Tab(text: '수업'),
                  Tab(text: '일정'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildClassesTab(),
          _buildScheduleTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final academy = _details!.academy;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric( vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (academy.tagList.isNotEmpty) _buildTags(academy),
          _buildContactInfo(academy),
          _buildSocialLinks(academy),
          if (_details!.instructors.isNotEmpty)
            _buildInstructorsSection(_details!.instructors),
          if (_details!.halls.isNotEmpty) _buildHallsSection(_details!.halls),
        ],
      ),
    );
  }

  Widget _buildClassesTab() {
    final classes = _sortedClasses;

    if (classes.isEmpty) {
      return const Center(
        child: Text(
          '등록된 수업이 없습니다.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        _buildSortOptions(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildClassCard(classes[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text(
            '정렬:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 8),
          _buildSortChip('날짜', 'date'),
          const SizedBox(width: 8),
          _buildSortChip('이름', 'name'),
          const SizedBox(width: 8),
          _buildSortChip('가격', 'price'),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _classSortAscending = !_classSortAscending;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _classSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _classSortAscending ? '오름차순' : '내림차순',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _classSortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _classSortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTab() {
    final classes = _details!.classes
        .where((c) => c.startTime != null)
        .toList();

    List<DanceClass> filteredClasses;
    if (_selectedDate != null) {
      filteredClasses = classes
          .where((c) =>
              c.startTime!.year == _selectedDate!.year &&
              c.startTime!.month == _selectedDate!.month &&
              c.startTime!.day == _selectedDate!.day)
          .toList()
        ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
    } else {
      filteredClasses = classes
          .where((c) =>
              c.startTime!.year == _selectedMonth.year &&
              c.startTime!.month == _selectedMonth.month)
          .toList()
        ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCalendarHeader(),
              _buildCalendarGrid(classes),
              const Divider(color: AppColors.divider),
              _buildScheduleListHeader(filteredClasses.length),
            ],
          ),
        ),
        if (filteredClasses.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                _selectedDate != null ? '선택한 날짜에 일정이 없습니다.' : '이번 달 일정이 없습니다.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildScheduleItem(filteredClasses[index]),
                  );
                },
                childCount: filteredClasses.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildScheduleListHeader(int count) {
    final headerText = _selectedDate != null
        ? DateFormat('M월 d일').format(_selectedDate!)
        : DateFormat('M월').format(_selectedMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text(
            '$headerText 일정',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count개',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (_selectedDate != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = null;
                });
              },
              child: const Text(
                '전체 보기',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
                _selectedDate = null;
              });
            },
          ),
          Text(
            DateFormat('yyyy년 M월').format(_selectedMonth),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
                _selectedDate = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(List<DanceClass> classes) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

    final classDateSet = <int>{};
    for (final c in classes) {
      if (c.startTime != null &&
          c.startTime!.year == _selectedMonth.year &&
          c.startTime!.month == _selectedMonth.month) {
        classDateSet.add(c.startTime!.day);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토']
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: d == '일'
                              ? AppColors.error
                              : d == '토'
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNum = index - firstWeekday + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox();
              }

              final hasClass = classDateSet.contains(dayNum);
              final isToday = DateTime.now().year == _selectedMonth.year &&
                  DateTime.now().month == _selectedMonth.month &&
                  DateTime.now().day == dayNum;
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == _selectedMonth.year &&
                  _selectedDate!.month == _selectedMonth.month &&
                  _selectedDate!.day == dayNum;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    final tappedDate = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month,
                      dayNum,
                    );
                    if (_selectedDate == tappedDate) {
                      _selectedDate = null;
                    } else {
                      _selectedDate = tappedDate;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: isToday || isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasClass && !isSelected)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(DanceClass danceClass) {
    final timeFormat = DateFormat('MM/dd HH:mm');
    return GestureDetector(
      onTap: () => _showClassDetailModal(danceClass),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    danceClass.displayTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeFormat.format(danceClass.startTime!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (danceClass.instructor != null)
              Text(
                danceClass.instructor!.displayName,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
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

  Widget _buildClassCard(DanceClass danceClass) {
    final priceFormat = NumberFormat('#,###', 'ko_KR');

    return GestureDetector(
      onTap: () => _showClassDetailModal(danceClass),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          danceClass.displayTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (danceClass.difficultyLevel != null || danceClass.classType != null) ...[
                        const SizedBox(width: 8),
                        if (danceClass.difficultyLevel != null)
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
                        if (danceClass.difficultyLevel != null && danceClass.classType != null)
                          const SizedBox(width: 4),
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (danceClass.instructor != null) ...[
                        ClipOval(
                          child: danceClass.instructor!.profileImageUrl != null
                              ? Image.network(
                                  danceClass.instructor!.profileImageUrl!,
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 20,
                                    height: 20,
                                    color: AppColors.surfaceLight,
                                    child: const Icon(
                                      Icons.person,
                                      size: 12,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 20,
                                  height: 20,
                                  color: AppColors.surfaceLight,
                                  child: const Icon(
                                    Icons.person,
                                    size: 12,
                                    color: AppColors.textHint,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            danceClass.instructor!.displayName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (danceClass.price > 0)
                        Text(
                          '₩${priceFormat.format(danceClass.price)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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

  void _showClassDetailModal(DanceClass danceClass) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final priceFormat = NumberFormat('#,###', 'ko_KR');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      danceClass.displayTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (danceClass.instructor != null) ...[
                      _buildModalInfoRow(
                        Icons.person,
                        '강사',
                        danceClass.instructor!.displayName,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (danceClass.startTime != null) ...[
                      _buildModalInfoRow(
                        Icons.schedule,
                        '시작',
                        dateFormat.format(danceClass.startTime!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (danceClass.endTime != null) ...[
                      _buildModalInfoRow(
                        Icons.schedule_outlined,
                        '종료',
                        dateFormat.format(danceClass.endTime!),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (danceClass.genre != null) ...[
                      _buildModalInfoRow(
                        Icons.music_note,
                        '장르',
                        danceClass.genre!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (danceClass.difficultyLevel != null) ...[
                      _buildModalInfoRow(
                        Icons.signal_cellular_alt,
                        '난이도',
                        danceClass.difficultyLevel!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (danceClass.classType != null) ...[
                      _buildModalInfoRow(
                        Icons.category,
                        '수업 유형',
                        danceClass.classType!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (danceClass.price > 0) ...[
                      _buildModalInfoRow(
                        Icons.payments,
                        '가격',
                        '₩${priceFormat.format(danceClass.price)}',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (danceClass.description != null && danceClass.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '설명',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        danceClass.description!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}