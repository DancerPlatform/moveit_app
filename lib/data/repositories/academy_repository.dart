import 'dart:math';

import '../../core/services/supabase_service.dart';
import '../models/academy.dart';
import '../models/dance_class.dart';
import '../models/hall.dart';
import '../models/instructor.dart';

/// Repository for fetching and managing academies from Supabase.
class AcademyRepository {
  static const String _tableName = 'academies';
  static const String _classesTable = 'classes';
  static const String _hallsTable = 'halls';
  static const String _academyInstructorsTable = 'academy_instructors';
  static const String _instructorsTable = 'instructors';

  /// Fetch all active academies
  Future<List<Academy>> getAcademies({
    bool activeOnly = true,
    int? limit,
    int? offset,
  }) async {
    var query = SupabaseService.client
        .from(_tableName)
        .select();

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1);

    return (response as List<dynamic>)
        .map((json) => Academy.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single academy by ID
  Future<Academy?> getAcademyById(String id) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Academy.fromJson(response);
  }

  /// Search academies by name (Korean or English)
  Future<List<Academy>> searchAcademies(
    String query, {
    int? limit,
    int? offset,
  }) async {
    final effectiveLimit = limit ?? 20;
    final effectiveOffset = offset ?? 0;

    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('is_active', true)
        .or('name_kr.ilike.%$query%,name_en.ilike.%$query%')
        .order('name_kr', ascending: true)
        .range(effectiveOffset, effectiveOffset + effectiveLimit - 1);

    return (response as List<dynamic>)
        .map((json) => Academy.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch academies within map bounds
  Future<List<Academy>> getAcademiesInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    bool activeOnly = true,
  }) async {
    var query = SupabaseService.client
        .from(_tableName)
        .select()
        .gte('location->latitude', minLat)
        .lte('location->latitude', maxLat)
        .gte('location->longitude', minLng)
        .lte('location->longitude', maxLng);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query;

    return (response as List<dynamic>)
        .map((json) => Academy.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch academies by tag
  Future<List<Academy>> getAcademiesByTag(
    String tag, {
    int? limit,
    int? offset,
  }) async {
    final effectiveLimit = limit ?? 20;
    final effectiveOffset = offset ?? 0;

    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('is_active', true)
        .ilike('tags', '%$tag%')
        .order('name_kr', ascending: true)
        .range(effectiveOffset, effectiveOffset + effectiveLimit - 1);

    return (response as List<dynamic>)
        .map((json) => Academy.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch academies within a specified distance (default 5km)
  Future<List<Academy>> getNearbyAcademies({
    required double userLat,
    required double userLng,
    double maxDistanceKm = 5.0,
    bool activeOnly = true,
    int? limit,
  }) async {
    // Calculate bounding box for initial filtering
    // 1 degree latitude ≈ 111km
    final latDelta = maxDistanceKm / 111.0;
    // 1 degree longitude varies by latitude
    final lngDelta = maxDistanceKm / (111.0 * cos(userLat * pi / 180));

    final minLat = userLat - latDelta;
    final maxLat = userLat + latDelta;
    final minLng = userLng - lngDelta;
    final maxLng = userLng + lngDelta;

    // Fetch academies within bounding box
    var query = SupabaseService.client
        .from(_tableName)
        .select()
        .gte('location->latitude', minLat)
        .lte('location->latitude', maxLat)
        .gte('location->longitude', minLng)
        .lte('location->longitude', maxLng);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query;

    // Parse and filter by actual distance using Haversine formula
    final academies = (response as List<dynamic>)
        .map((json) => Academy.fromJson(json as Map<String, dynamic>))
        .where((academy) {
          final location = academy.location;
          if (location == null || !location.isValid) return false;
          final distance = _calculateDistanceKm(
            userLat,
            userLng,
            location.latitude!,
            location.longitude!,
          );
          return distance <= maxDistanceKm;
        })
        .toList();

    // Sort by distance
    academies.sort((a, b) {
      final distA = _calculateDistanceKm(
        userLat, userLng, a.location!.latitude!, a.location!.longitude!);
      final distB = _calculateDistanceKm(
        userLat, userLng, b.location!.latitude!, b.location!.longitude!);
      return distA.compareTo(distB);
    });

    if (limit != null && academies.length > limit) {
      return academies.sublist(0, limit);
    }

    return academies;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Stream academies for real-time updates
  Stream<List<Academy>> streamAcademies({bool activeOnly = true}) {
    var query = SupabaseService.client
        .from(_tableName)
        .stream(primaryKey: ['id']);

    return query.map((data) {
      var academies = data
          .map((json) => Academy.fromJson(json))
          .toList();

      if (activeOnly) {
        academies = academies.where((a) => a.isActive).toList();
      }

      return academies;
    });
  }

  /// Fetch classes for a specific academy
  Future<List<DanceClass>> getClassesByAcademyId(
    String academyId, {
    bool activeOnly = true,
    int? limit,
  }) async {
    var query = SupabaseService.client
        .from(_classesTable)
        .select()
        .eq('academy_id', academyId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit ?? 50);

    return (response as List<dynamic>)
        .map((json) => DanceClass.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch halls for a specific academy
  Future<List<Hall>> getHallsByAcademyId(String academyId) async {
    final response = await SupabaseService.client
        .from(_hallsTable)
        .select()
        .eq('academy_id', academyId)
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Hall.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch instructors for a specific academy (via academy_instructors junction table)
  Future<List<Instructor>> getInstructorsByAcademyId(
    String academyId, {
    bool activeOnly = true,
  }) async {
    var query = SupabaseService.client
        .from(_academyInstructorsTable)
        .select('instructor_id, is_active, $_instructorsTable(*)')
        .eq('academy_id', academyId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query;

    return (response as List<dynamic>)
        .where((json) => json[_instructorsTable] != null)
        .map((json) => Instructor.fromJson(json[_instructorsTable] as Map<String, dynamic>))
        .toList();
  }

  /// Fetch full academy details with related data
  Future<AcademyDetails?> getAcademyDetails(String academyId) async {
    final academy = await getAcademyById(academyId);
    if (academy == null) return null;

    final results = await Future.wait([
      getInstructorsByAcademyId(academyId),
      getClassesByAcademyId(academyId),
      getHallsByAcademyId(academyId),
    ]);

    return AcademyDetails(
      academy: academy,
      instructors: results[0] as List<Instructor>,
      classes: results[1] as List<DanceClass>,
      halls: results[2] as List<Hall>,
    );
  }
}

/// Combined academy details with related data
class AcademyDetails {
  final Academy academy;
  final List<Instructor> instructors;
  final List<DanceClass> classes;
  final List<Hall> halls;

  const AcademyDetails({
    required this.academy,
    required this.instructors,
    required this.classes,
    required this.halls,
  });
}
