import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/academy.dart';
import '../../../data/repositories/academy_repository.dart';
import '../../widgets/academy/academy_widgets.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final AcademyRepository _academyRepository = AcademyRepository();

  static final LatLng _defaultPosition = LatLng(37.5665, 126.9780); // Seoul, South Korea

  Position? _currentPosition;
  bool _isLoading = true;
  bool _isFetchingAcademies = false;
  String? _errorMessage;
  List<Academy> _academies = [];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchAcademiesInBounds() async {
    if (_isFetchingAcademies) return;

    final bounds = _mapController.camera.visibleBounds;

    setState(() => _isFetchingAcademies = true);

    try {
      final academies = await _academyRepository.getAcademiesInBounds(
        minLat: bounds.south,
        maxLat: bounds.north,
        minLng: bounds.west,
        maxLng: bounds.east,
      );
      if (mounted) {
        setState(() {
          _academies = academies;
          _isFetchingAcademies = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching academies: $e');
      if (mounted) {
        setState(() => _isFetchingAcademies = false);
      }
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      _fetchAcademiesInBounds();
    }
  }

  Marker? get _currentLocationMarker {
    if (_currentPosition == null) return null;
    return Marker(
      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      width: 40,
      height: 40,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Opacity(
          opacity: _pulseAnimation.value,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        ),
      ),
    );
  }

  List<Marker> get _academyMarkers {
    final markers = <Marker>[];
    for (final academy in _academies) {
      if (academy.location != null && academy.location!.isValid) {
        markers.add(
          Marker(
            point: LatLng(
              academy.location!.latitude!,
              academy.location!.longitude!,
            ),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showAcademyInfo(academy),
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),
        );
      }
    }
    return markers;
  }

  Academy? _getAcademyForMarker(Marker marker) {
    for (final academy in _academies) {
      if (academy.location != null &&
          academy.location!.latitude == marker.point.latitude &&
          academy.location!.longitude == marker.point.longitude) {
        return academy;
      }
    }
    return null;
  }

  List<Academy> _getAcademiesForMarkers(List<Marker> markers) {
    final academies = <Academy>[];
    for (final marker in markers) {
      final academy = _getAcademyForMarker(marker);
      if (academy != null) {
        academies.add(academy);
      }
    }
    return academies;
  }

  String? _getDistanceForAcademy(Academy academy) {
    if (_currentPosition == null || academy.location?.isValid != true) {
      return null;
    }

    final distanceMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      academy.location!.latitude!,
      academy.location!.longitude!,
    );

    final distanceKm = distanceMeters / 1000;
    if (distanceKm < 1) {
      return '${distanceMeters.round()}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }

  Map<String, String> _getDistancesForAcademies(List<Academy> academies) {
    final distances = <String, String>{};
    for (final academy in academies) {
      final distance = _getDistanceForAcademy(academy);
      if (distance != null) {
        distances[academy.id] = distance;
      }
    }
    return distances;
  }

  void _showClusterAcademies(List<Marker> markers) {
    final academies = _getAcademiesForMarkers(markers);
    if (academies.isEmpty) return;

    final distances = _getDistancesForAcademies(academies);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${academies.length}개의 학원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: academies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => AcademyCard(
                  academy: academies[index],
                  variant: AcademyCardVariant.listTile,
                  distance: distances[academies[index].id],
                  onTap: () {
                    Navigator.pop(context);
                    _showAcademyInfo(academies[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAcademyInfo(Academy academy) {
    final distance = _getDistanceForAcademy(academy);
    final distances = distance != null ? {academy.id: distance} : <String, String>{};

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
        child: AcademyListWidget(
          academies: [academy],
          layout: AcademyListLayout.vertical,
          cardVariant: AcademyCardVariant.listTile,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          distances: distances,
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = '위치 서비스가 비활성화되어 있습니다.';
          _isLoading = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = '위치 권한이 거부되었습니다.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 활성화해주세요.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move map to current position
      _mapController.move(currentLatLng, 17.0);

      // Fetch academies in the new visible area
      _fetchAcademiesInBounds();
    } catch (e) {
      setState(() {
        _errorMessage = '위치를 가져오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isPrimary = false,
  }) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: isPrimary ? AppColors.primary : Colors.black,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultPosition,
              initialZoom: 17.0,
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  disableClusteringAtZoom: 18,
                  size: const Size(50, 50),
                  markers: _academyMarkers,
                  builder: (context, markers) => GestureDetector(
                    onTap: () => _showClusterAcademies(markers),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${markers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_currentLocationMarker != null)
                MarkerLayer(markers: [_currentLocationMarker!]),
            ],
          ),
          // Map controls
          Positioned(
            right: 20,
            bottom: 20,
            child: Column(
              children: [
                _buildMapControlButton(
                  icon: Icons.add,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom + 1,
                    );
                  },
                  tooltip: '확대',
                ),
                const SizedBox(height: 8),
                _buildMapControlButton(
                  icon: Icons.remove,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(
                      _mapController.camera.center,
                      currentZoom - 1,
                    );
                  },
                  tooltip: '축소',
                ),
                const SizedBox(height: 16),
                _buildMapControlButton(
                  icon: Icons.my_location,
                  onPressed: _getCurrentLocation,
                  tooltip: '현재 위치로 이동',
                  isPrimary: true,
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          if (_errorMessage != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                color: AppColors.error,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _getCurrentLocation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
