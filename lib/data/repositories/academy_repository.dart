import '../../core/services/supabase_service.dart';
import '../models/academy.dart';

/// Repository for fetching and managing academies from Supabase.
class AcademyRepository {
  static const String _tableName = 'academies';

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
  Future<List<Academy>> searchAcademies(String query) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('is_active', true)
        .or('name_kr.ilike.%$query%,name_en.ilike.%$query%')
        .order('name_kr', ascending: true)
        .limit(20);

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
  Future<List<Academy>> getAcademiesByTag(String tag) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('is_active', true)
        .ilike('tags', '%$tag%')
        .order('name_kr', ascending: true);

    return (response as List<dynamic>)
        .map((json) => Academy.fromJson(json as Map<String, dynamic>))
        .toList();
  }

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
}
