import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../data/models/academy.dart';
import '../../../../data/repositories/academy_repository.dart';
import '../../../widgets/academy/academy_card.dart';

class NearbyStudiosList extends StatefulWidget {
  const NearbyStudiosList({super.key});

  @override
  State<NearbyStudiosList> createState() => _NearbyStudiosListState();
}

class _NearbyStudiosListState extends State<NearbyStudiosList> {
  final AcademyRepository _repository = AcademyRepository();

  List<_AcademyWithDistance> _nearbyAcademies = [];
  bool _isLoading = true;
  String? _error;

  static const double _maxDistanceKm = 10.0;

  @override
  void initState() {
    super.initState();
    _loadNearbyAcademies();
  }

  Future<void> _loadNearbyAcademies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get user's current location
      final position = await _getCurrentPosition();
      if (position == null) {
        if (mounted) {
          setState(() {
            _error = '위치 정보를 가져올 수 없습니다';
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch all academies
      final academies = await _repository.getAcademies(limit: 100);

      // Calculate distance and filter
      final academiesWithDistance = <_AcademyWithDistance>[];

      for (final academy in academies) {
        if (academy.location?.isValid == true) {
          final distanceMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            academy.location!.latitude!,
            academy.location!.longitude!,
          );

          final distanceKm = distanceMeters / 1000;

          // Only include academies within max distance
          if (distanceKm <= _maxDistanceKm) {
            academiesWithDistance.add(_AcademyWithDistance(
              academy: academy,
              distanceKm: distanceKm,
            ));
          }
        }
      }

      // Sort by distance (closest first)
      academiesWithDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      if (mounted) {
        setState(() {
          _nearbyAcademies = academiesWithDistance;
          _isLoading = false;
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

  Future<Position?> _getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
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
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
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

    if (_error != null) {
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
                      _error!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _loadNearbyAcademies,
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

    if (_nearbyAcademies.isEmpty) {
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
              onTap: () {
                // TODO: Navigate to academy detail screen
              },
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
