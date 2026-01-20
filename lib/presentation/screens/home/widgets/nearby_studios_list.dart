import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/academy.dart';
import '../../../../data/repositories/academy_repository.dart';
import '../../../../providers/location_provider.dart';
import '../../../widgets/academy/academy_card.dart';

class NearbyStudiosList extends StatefulWidget {
  const NearbyStudiosList({super.key});

  @override
  State<NearbyStudiosList> createState() => _NearbyStudiosListState();
}

class _NearbyStudiosListState extends State<NearbyStudiosList> {
  final AcademyRepository _repository = AcademyRepository();

  List<_AcademyWithDistance> _nearbyAcademies = [];
  bool _isLoading = false;
  bool _hasFetched = false;
  String? _error;

  static const double _maxDistanceKm = 10.0;

  @override
  void initState() {
    super.initState();
    // Listen to location changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyAcademiesIfReady();
    });
  }

  void _loadNearbyAcademiesIfReady() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.hasLocation && !_hasFetched) {
      _loadNearbyAcademies(locationProvider);
    }
  }

  Future<void> _loadNearbyAcademies(LocationProvider locationProvider) async {
    final position = locationProvider.currentPosition;
    if (position == null) {
      setState(() {
        _error = '위치 정보를 가져올 수 없습니다';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch nearby academies (already filtered and sorted by distance)
      final academies = await _repository.getNearbyAcademies(
        userLat: position.latitude,
        userLng: position.longitude,
        maxDistanceKm: _maxDistanceKm,
        limit: 20,
      );

      // Calculate distance for display purposes
      final academiesWithDistance = academies.map((academy) {
        final distanceMeters = locationProvider.distanceTo(
          academy.location!.latitude!,
          academy.location!.longitude!,
        );
        return _AcademyWithDistance(
          academy: academy,
          distanceKm: (distanceMeters ?? 0) / 1000,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _nearbyAcademies = academiesWithDistance;
          _isLoading = false;
          _hasFetched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '데이터를 불러올 수 없습니다';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retry() async {
    final locationProvider = context.read<LocationProvider>();

    // If no location, try to get it first
    if (!locationProvider.hasLocation) {
      await locationProvider.getCurrentLocation();
    }

    if (locationProvider.hasLocation) {
      await _loadNearbyAcademies(locationProvider);
    }
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        // Auto-load when location becomes available
        if (locationProvider.hasLocation && !_hasFetched && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadNearbyAcademies(locationProvider);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                AppStrings.nearbyFacilities,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildContent(locationProvider),
          ],
        );
      },
    );
  }

  Widget _buildContent(LocationProvider locationProvider) {
    // Show loading while location is being fetched or academies are loading
    if (locationProvider.isLoading || _isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Show error if location failed or data fetch failed
    if (_error != null || locationProvider.errorMessage != null) {
      final errorMsg = _error ?? locationProvider.errorMessage ?? '오류가 발생했습니다';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_off_outlined,
                color: AppColors.textHint,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      errorMsg,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _retry,
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

    // Show empty state if no academies found
    if (_nearbyAcademies.isEmpty && _hasFetched) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.location_searching,
                color: AppColors.textHint,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                '주변 10km 내에 등록된 학원이 없습니다',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show waiting for location if not yet available
    if (!locationProvider.hasLocation && !_hasFetched) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _nearbyAcademies.length,
        itemBuilder: (context, index) {
          final item = _nearbyAcademies[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < _nearbyAcademies.length - 1 ? 12 : 0,
            ),
            child: AcademyCard(
              academy: item.academy,
              variant: AcademyCardVariant.compact,
              distance: _formatDistance(item.distanceKm),
            ),
          );
        },
      ),
    );
  }
}

/// Helper class to hold academy with calculated distance
class _AcademyWithDistance {
  final Academy academy;
  final double distanceKm;

  const _AcademyWithDistance({
    required this.academy,
    required this.distanceKm,
  });
}
