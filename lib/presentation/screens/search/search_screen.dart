import 'dart:async';
import 'dart:math' show asin, cos, sin, sqrt, pi;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/academy.dart';
import '../../../data/repositories/academy_repository.dart';
import '../../widgets/academy/academy_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final AcademyRepository _repository = AcademyRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Academy> _results = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String _selectedCategory = AppStrings.categoryAll;
  Timer? _debounceTimer;

  // Distance filter
  bool _distanceFilterEnabled = false;
  double _maxDistanceKm = 10.0;
  Position? _userPosition;
  bool _isLoadingLocation = false;

  static const int _pageSize = 20;
  static const double _minDistance = 1.0;
  static const double _maxDistance = 50.0;

  final List<String> _categories = [
    AppStrings.categoryAll,
    AppStrings.categoryKpop,
    AppStrings.categoryHiphop,
    AppStrings.categoryJazz,
    AppStrings.categoryBallet,
    AppStrings.categoryContemporary,
    AppStrings.categoryLatin,
    AppStrings.categoryStreet,
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // Load initial data and auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _performSearch();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasMore = true;
    });

    try {
      final results = await _fetchResults(query, offset: 0);

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
          _hasMore = results.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppStrings.searchError;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final query = _searchController.text.trim();
      final newResults = await _fetchResults(query, offset: _results.length);

      if (mounted) {
        setState(() {
          _results.addAll(newResults);
          _isLoadingMore = false;
          _hasMore = newResults.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<List<Academy>> _fetchResults(String query, {required int offset}) async {
    List<Academy> results;

    if (query.isNotEmpty) {
      // Search by query
      results = await _repository.searchAcademies(
        query,
        limit: _pageSize,
        offset: offset,
      );

      // Filter by category if selected
      if (_selectedCategory != AppStrings.categoryAll) {
        results = results.where((academy) {
          return academy.tagList.any((tag) =>
              tag.toLowerCase().contains(_selectedCategory.toLowerCase()));
        }).toList();
      }
    } else {
      // No text query - filter by category or show all
      if (_selectedCategory == AppStrings.categoryAll) {
        results = await _repository.getAcademies(
          limit: _pageSize,
          offset: offset,
        );
      } else {
        results = await _repository.getAcademiesByTag(
          _selectedCategory,
          limit: _pageSize,
          offset: offset,
        );
      }
    }

    // Apply distance filter if enabled
    if (_distanceFilterEnabled && _userPosition != null) {
      results = results.where((academy) {
        final location = academy.location;
        if (location == null || !location.isValid) return false;
        final distance = _calculateDistanceKm(
          _userPosition!.latitude,
          _userPosition!.longitude,
          location.latitude!,
          location.longitude!,
        );
        return distance <= _maxDistanceKm;
      }).toList();
    }

    return results;
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _performSearch();
  }

  Future<void> _enableDistanceFilter() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.locationServiceDisabled)),
          );
          setState(() {
            _isLoadingLocation = false;
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.locationPermissionDenied)),
            );
            setState(() {
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.locationPermissionDenied)),
          );
          setState(() {
            _isLoadingLocation = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userPosition = position;
          _distanceFilterEnabled = true;
          _isLoadingLocation = false;
        });
        _performSearch();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _disableDistanceFilter() {
    setState(() {
      _distanceFilterEnabled = false;
    });
    _performSearch();
  }

  void _onDistanceChanged(double value) {
    setState(() {
      _maxDistanceKm = value;
    });
  }

  void _onDistanceChangeEnd(double value) {
    _performSearch();
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedCategory = AppStrings.categoryAll;
    });
    _performSearch();
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
        title: _buildSearchField(),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryFilter(),
            const SizedBox(height: 8),
            _buildDistanceFilter(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.searchHint,
          hintStyle: const TextStyle(
            color: AppColors.textHint,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                )
              : const Icon(
                  Icons.search,
                  color: AppColors.textHint,
                ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return GestureDetector(
            onTap: () => _onCategorySelected(category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: _distanceFilterEnabled
                        ? AppColors.primary
                        : AppColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.distanceFilter,
                    style: TextStyle(
                      color: _distanceFilterEnabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else
                Switch(
                  value: _distanceFilterEnabled,
                  onChanged: (value) {
                    if (value) {
                      _enableDistanceFilter();
                    } else {
                      _disableDistanceFilter();
                    }
                  },
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: AppColors.textPrimary,
                ),
            ],
          ),
          if (_distanceFilterEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.border,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _maxDistanceKm,
                      min: _minDistance,
                      max: _maxDistance,
                      divisions: 49,
                      onChanged: _onDistanceChanged,
                      onChangeEnd: _onDistanceChangeEnd,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_maxDistanceKm.round()} ${AppStrings.distanceKm}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_results.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildResultsList();
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.noSearchResults,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.tryDifferentSearch,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? AppStrings.searchError,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _performSearch,
            child: const Text(
              AppStrings.retry,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _results.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final academy = _results[index];
        return AcademyCard(
          academy: academy,
          variant: AcademyCardVariant.listTile,
        );
      },
    );
  }
}