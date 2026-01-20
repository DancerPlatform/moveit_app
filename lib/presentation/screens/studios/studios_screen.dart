import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/academy.dart';
import '../../../data/repositories/academy_repository.dart';
import '../../widgets/academy/academy_widgets.dart';

class StudiosScreen extends StatefulWidget {
  const StudiosScreen({super.key});

  @override
  State<StudiosScreen> createState() => _StudiosScreenState();
}

class _StudiosScreenState extends State<StudiosScreen> {
  final MapController _mapController = MapController();
  final AcademyRepository _academyRepository = AcademyRepository();

  static final LatLng _defaultPosition = LatLng(37.5665, 126.9780); // Seoul, South Korea

  Position? _currentPosition;
  bool _isLoading = true;
  bool _isFetchingAcademies = false;
  String? _errorMessage;
  List<Academy> _academies = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  List<Marker> get _markers {
    final markers = <Marker>[];

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 40,
          ),
        ),
      );
    }

    // Add academy markers
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

  void _showAcademyInfo(Academy academy) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.danceStudios),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: '현재 위치로 이동',
          ),
        ],
      ),
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dancer_app',
              ),
              MarkerLayer(markers: _markers),
            ],
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
