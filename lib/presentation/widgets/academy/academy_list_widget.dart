import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/academy.dart';
import '../../../data/repositories/academy_repository.dart';
import 'academy_card.dart';

/// A reusable widget for displaying a list of academies.
///
/// Supports multiple layout modes:
/// - [AcademyListLayout.horizontal] - Horizontal scrolling list
/// - [AcademyListLayout.vertical] - Vertical scrolling list
/// - [AcademyListLayout.grid] - Grid layout
///
/// Can fetch data automatically from Supabase or accept a pre-fetched list.
class AcademyListWidget extends StatefulWidget {
  /// Pre-fetched list of academies (if null, will fetch from repository)
  final List<Academy>? academies;

  /// Layout mode for displaying academies
  final AcademyListLayout layout;

  /// Card variant to use for each academy
  final AcademyCardVariant cardVariant;

  /// Optional title to display above the list
  final String? title;

  /// Whether to show a "See All" button
  final bool showSeeAll;

  /// Callback when "See All" is tapped
  final VoidCallback? onSeeAllTap;

  /// Callback when an academy card is tapped
  final void Function(Academy academy)? onAcademyTap;

  /// Maximum number of items to display (null for no limit)
  final int? maxItems;

  /// Whether to use real-time stream (only works when academies is null)
  final bool useRealtime;

  /// Number of columns for grid layout
  final int gridCrossAxisCount;

  /// Spacing between items
  final double spacing;

  /// Padding around the list
  final EdgeInsets padding;

  /// Optional distances map (academy ID -> formatted distance string)
  final Map<String, String>? distances;

  const AcademyListWidget({
    super.key,
    this.academies,
    this.layout = AcademyListLayout.horizontal,
    this.cardVariant = AcademyCardVariant.compact,
    this.title,
    this.showSeeAll = false,
    this.onSeeAllTap,
    this.onAcademyTap,
    this.maxItems,
    this.useRealtime = false,
    this.gridCrossAxisCount = 2,
    this.spacing = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.distances,
  });

  @override
  State<AcademyListWidget> createState() => _AcademyListWidgetState();
}

class _AcademyListWidgetState extends State<AcademyListWidget> {
  final AcademyRepository _repository = AcademyRepository();
  List<Academy>? _fetchedAcademies;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.academies == null && !widget.useRealtime) {
      _fetchAcademies();
    }
  }

  Future<void> _fetchAcademies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final academies = await _repository.getAcademies(limit: widget.maxItems);
      if (mounted) {
        setState(() {
          _fetchedAcademies = academies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Academy> get _displayAcademies {
    final academies = widget.academies ?? _fetchedAcademies ?? [];
    if (widget.maxItems != null && academies.length > widget.maxItems!) {
      return academies.take(widget.maxItems!).toList();
    }
    return academies;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) _buildHeader(),
        if (widget.useRealtime && widget.academies == null)
          _buildRealtimeList()
        else
          _buildContent(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title!,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.showSeeAll)
            GestureDetector(
              onTap: widget.onSeeAllTap,
              child: const Text(
                '전체보기',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_displayAcademies.isEmpty) {
      return _buildEmptyState();
    }

    return switch (widget.layout) {
      AcademyListLayout.horizontal => _buildHorizontalList(),
      AcademyListLayout.vertical => _buildVerticalList(),
      AcademyListLayout.grid => _buildGridList(),
    };
  }

  Widget _buildRealtimeList() {
    return StreamBuilder<List<Academy>>(
      stream: _repository.streamAcademies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(error: snapshot.error.toString());
        }

        final academies = snapshot.data ?? [];
        if (academies.isEmpty) {
          return _buildEmptyState();
        }

        // Temporarily set fetched academies for display
        _fetchedAcademies = academies;

        return switch (widget.layout) {
          AcademyListLayout.horizontal => _buildHorizontalList(),
          AcademyListLayout.vertical => _buildVerticalList(),
          AcademyListLayout.grid => _buildGridList(),
        };
      },
    );
  }

  Widget _buildHorizontalList() {
    return Column(
      children: [
        if (widget.title != null) const SizedBox(height: 16),
        SizedBox(
          height: _getListHeight(),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            itemCount: _displayAcademies.length,
            itemBuilder: (context, index) {
              final academy = _displayAcademies[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < _displayAcademies.length - 1 ? widget.spacing : 0,
                ),
                child: AcademyCard(
                  academy: academy,
                  variant: widget.cardVariant,
                  distance: widget.distances?[academy.id],
                  onTap: widget.onAcademyTap != null
                      ? () => widget.onAcademyTap!(academy)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalList() {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          if (widget.title != null) const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _displayAcademies.length,
            separatorBuilder: (_, __) => SizedBox(height: widget.spacing),
            itemBuilder: (context, index) {
              final academy = _displayAcademies[index];
              return AcademyCard(
                academy: academy,
                variant: widget.cardVariant,
                distance: widget.distances?[academy.id],
                onTap: widget.onAcademyTap != null
                    ? () => widget.onAcademyTap!(academy)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridList() {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          if (widget.title != null) const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.gridCrossAxisCount,
              crossAxisSpacing: widget.spacing,
              mainAxisSpacing: widget.spacing,
              childAspectRatio: 0.75,
            ),
            itemCount: _displayAcademies.length,
            itemBuilder: (context, index) {
              final academy = _displayAcademies[index];
              return AcademyCard(
                academy: academy,
                variant: widget.cardVariant,
                distance: widget.distances?[academy.id],
                onTap: widget.onAcademyTap != null
                    ? () => widget.onAcademyTap!(academy)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 150,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorState({String? error}) {
    return Padding(
      padding: widget.padding,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '데이터를 불러올 수 없습니다',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _fetchAcademies,
                    child: const Text(
                      '다시 시도',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: widget.padding,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.business_outlined,
              color: AppColors.textHint,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              '등록된 학원이 없습니다',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getListHeight() {
    return switch (widget.cardVariant) {
      AcademyCardVariant.compact => 200,
      AcademyCardVariant.standard => 280,
      AcademyCardVariant.detailed => 380,
      AcademyCardVariant.listTile => 130,
    };
  }
}

/// Layout modes for AcademyListWidget
enum AcademyListLayout {
  /// Horizontal scrolling list
  horizontal,

  /// Vertical scrolling list
  vertical,

  /// Grid layout
  grid,
}
