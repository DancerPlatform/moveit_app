import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/academy.dart';
import '../../../data/models/instructor.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/favorite_provider.dart';
import '../../widgets/academy/academy_card.dart';
import '../../widgets/instructor/instructor_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '찜 목록',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.background,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_outlined, size: 18),
                        SizedBox(width: 6),
                        Text('학원'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 6),
                        Text('강사'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _FavoriteAcademiesTab(),
                _FavoriteInstructorsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteAcademiesTab extends StatefulWidget {
  const _FavoriteAcademiesTab();

  @override
  State<_FavoriteAcademiesTab> createState() => _FavoriteAcademiesTabState();
}

class _FavoriteAcademiesTabState extends State<_FavoriteAcademiesTab> {
  List<Academy> _academies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteAcademies();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when favorites change
    context.watch<FavoriteProvider>().favoriteAcademyIds;
    if (!_isLoading) {
      _loadFavoriteAcademies();
    }
  }

  Future<void> _loadFavoriteAcademies() async {
    final favoriteProvider = context.read<FavoriteProvider>();
    final favoriteIds = favoriteProvider.favoriteAcademyIds;

    if (favoriteIds.isEmpty) {
      setState(() {
        _academies = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('academies')
          .select()
          .inFilter('id', favoriteIds.toList());

      if (mounted) {
        setState(() {
          _academies = (response as List<dynamic>)
              .map((json) => Academy.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return _buildEmptyState('로그인 후 이용해주세요');
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_academies.isEmpty) {
      return _buildEmptyState('찜한 학원이 없습니다');
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteAcademies,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _academies.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return AcademyCard(
            academy: _academies[index],
            variant: AcademyCardVariant.listTile,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteInstructorsTab extends StatefulWidget {
  const _FavoriteInstructorsTab();

  @override
  State<_FavoriteInstructorsTab> createState() =>
      _FavoriteInstructorsTabState();
}

class _FavoriteInstructorsTabState extends State<_FavoriteInstructorsTab> {
  List<Instructor> _instructors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteInstructors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when favorites change
    context.watch<FavoriteProvider>().favoriteInstructorIds;
    if (!_isLoading) {
      _loadFavoriteInstructors();
    }
  }

  Future<void> _loadFavoriteInstructors() async {
    final favoriteProvider = context.read<FavoriteProvider>();
    final favoriteIds = favoriteProvider.favoriteInstructorIds;

    if (favoriteIds.isEmpty) {
      setState(() {
        _instructors = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('instructors')
          .select()
          .inFilter('id', favoriteIds.toList());

      if (mounted) {
        setState(() {
          _instructors = (response as List<dynamic>)
              .map((json) => Instructor.fromJson(json as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    if (!isLoggedIn) {
      return _buildEmptyState('로그인 후 이용해주세요');
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_instructors.isEmpty) {
      return _buildEmptyState('찜한 강사가 없습니다');
    }

    return RefreshIndicator(
      onRefresh: _loadFavoriteInstructors,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _instructors.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return InstructorCard(
            instructor: _instructors[index],
            variant: InstructorCardVariant.standard,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
