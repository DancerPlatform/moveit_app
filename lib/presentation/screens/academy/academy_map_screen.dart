import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/academy.dart';
import '../../../data/repositories/academy_repository.dart';
import '../../../providers/location_provider.dart';
import '../../widgets/academy/academy_widgets.dart';
import '../academy/academy_detail_screen.dart';

class AcademyMapScreen extends StatefulWidget {
  const AcademyMapScreen({super.key});

  @override
  State<AcademyMapScreen> createState() => _AcademyMapScreenState();
}

class _AcademyMapScreenState extends State<AcademyMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final AcademyRepository _academyRepository = AcademyRepository();

  static final LatLng _defaultPosition = LatLng(37.5665, 126.9780); // Seoul

  bool _isFetchingAcademies = false;
  bool _isMapReady = false;
  bool _hasMovedToUserLocation = false;
  List<Academy> _academies = [];
  final Set<String> _selectedTags = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapReady() {
    _isMapReady = true;
    _tryMoveToUserLocation();
    _fetchAcademiesInBounds();
  }

  void _tryMoveToUserLocation() {
    if (_hasMovedToUserLocation) return;

    final locationProvider = context.read<LocationProvider>();
    final position = locationProvider.currentPosition;

    if (position != null) {
      _hasMovedToUserLocation = true;
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        17.0,
      );
    }
  }

  Future<void> _fetchAcademiesInBounds() async {
    if (_isFetchingAcademies || !_isMapReady) return;

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

  Marker? _buildCurrentLocationMarker(LocationProvider locationProvider) {
    final position = locationProvider.currentPosition;
    if (position == null) return null;

    return Marker(
      point: LatLng(position.latitude, position.longitude),
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
    for (final academy in _filteredAcademies) {
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

  /// Get all unique tags from loaded academies
  Set<String> get _availableTags {
    final tags = <String>{};
    for (final academy in _academies) {
      tags.addAll(academy.tagList);
    }
    return tags;
  }

  /// Get academies filtered by selected tags
  List<Academy> get _filteredAcademies {
    if (_selectedTags.isEmpty) return _academies;
    return _academies.where((academy) {
      final academyTags = academy.tagList;
      return _selectedTags.any((tag) => academyTags.contains(tag));
    }).toList();
  }

  /// Search address using Nominatim and move map to location
  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1&countrycodes=kr',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'DancerApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final lat = double.parse(results[0]['lat']);
          final lon = double.parse(results[0]['lon']);

          if (_isMapReady) {
            _mapController.move(LatLng(lat, lon), 15.0);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('주소를 찾을 수 없습니다')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 중 오류가 발생했습니다')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  String? _getDistanceForAcademy(
      Academy academy, LocationProvider locationProvider) {
    if (!locationProvider.hasLocation || academy.location?.isValid != true) {
      return null;
    }
    return locationProvider.formatDistanceTo(
      academy.location!.latitude!,
      academy.location!.longitude!,
    );
  }

  Map<String, String> _getDistancesForAcademies(
      List<Academy> academies, LocationProvider locationProvider) {
    final distances = <String, String>{};
    for (final academy in academies) {
      final distance = _getDistanceForAcademy(academy, locationProvider);
      if (distance != null) {
        distances[academy.id] = distance;
      }
    }
    return distances;
  }

  void _showClusterAcademies(List<Marker> markers) {
    final academies = _getAcademiesForMarkers(markers);
    if (academies.isEmpty) return;

    final locationProvider = context.read<LocationProvider>();
    final distances = _getDistancesForAcademies(academies, locationProvider);

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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableTags = _availableTags.toList()..sort();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '태그 필터',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedTags.clear();
                        });
                        setState(() {});
                      },
                      child: const Text('초기화'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (availableTags.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        '현재 지역에 태그가 없습니다',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                          setState(() {});
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _selectedTags.isEmpty
                          ? '전체 보기'
                          : '${_filteredAcademies.length}개 학원 보기',
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAcademyInfo(Academy academy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AcademyDetailScreen(academyId: academy.id),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    final locationProvider = context.read<LocationProvider>();

    // Refresh location if needed
    final position = await locationProvider.getCurrentLocation(forceRefresh: true);

    if (position != null && _isMapReady) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        17.0,
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchAddress,
                decoration: InputDecoration(
                  hintText: '주소 검색 (예: 강남역, 홍대입구)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              children: [
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surface,
                  child: InkWell(
                    onTap: _showFilterBottomSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (_selectedTags.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${_selectedTags.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        // Try to move to user location once loaded
        if (locationProvider.hasLocation && !_hasMovedToUserLocation && _isMapReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _tryMoveToUserLocation();
          });
        }

        final currentLocationMarker = _buildCurrentLocationMarker(locationProvider);

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _defaultPosition,
                  initialZoom: 17.0,
                  onMapEvent: _onMapEvent,
                  onMapReady: _onMapReady,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
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
                  if (currentLocationMarker != null)
                    MarkerLayer(markers: [currentLocationMarker]),
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
                      onPressed: _goToCurrentLocation,
                      tooltip: '현재 위치로 이동',
                      isPrimary: true,
                    ),
                  ],
                ),
              ),
              // Loading indicator only during initial location fetch
              if (locationProvider.isLoading &&
                  locationProvider.status == LocationStatus.loading)
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              // Error message
              if (locationProvider.errorMessage != null)
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
                              locationProvider.errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _goToCurrentLocation,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Search bar at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildSearchBar(),
              ),
            ],
          ),
        );
      },
    );
  }
}
