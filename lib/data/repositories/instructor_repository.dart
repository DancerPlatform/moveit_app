import '../../core/services/supabase_service.dart';
import '../models/instructor.dart';

/// Repository for fetching and managing instructors from Supabase.
class InstructorRepository {
  static const String _tableName = 'instructors';

  /// Fetch all instructors
  Future<List<Instructor>> getInstructors({
    int? limit,
    int? offset,
  }) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .order('created_at', ascending: false)
        .range(offset ?? 0, (offset ?? 0) + (limit ?? 50) - 1);

    return (response as List<dynamic>)
        .map((json) => Instructor.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single instructor by ID
  Future<Instructor?> getInstructorById(String id) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Instructor.fromJson(response);
  }

  /// Search instructors by name (Korean or English)
  Future<List<Instructor>> searchInstructors(
    String query, {
    int? limit,
    int? offset,
  }) async {
    final effectiveLimit = limit ?? 20;
    final effectiveOffset = offset ?? 0;

    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .or('name_kr.ilike.%$query%,name_en.ilike.%$query%')
        .order('name_kr', ascending: true)
        .range(effectiveOffset, effectiveOffset + effectiveLimit - 1);

    return (response as List<dynamic>)
        .map((json) => Instructor.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch instructors by specialty
  Future<List<Instructor>> getInstructorsBySpecialty(
    String specialty, {
    int? limit,
    int? offset,
  }) async {
    final effectiveLimit = limit ?? 20;
    final effectiveOffset = offset ?? 0;

    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .ilike('specialties', '%$specialty%')
        .order('name_kr', ascending: true)
        .range(effectiveOffset, effectiveOffset + effectiveLimit - 1);

    return (response as List<dynamic>)
        .map((json) => Instructor.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch popular instructors (sorted by like count)
  Future<List<Instructor>> getPopularInstructors({
    int? limit,
  }) async {
    final response = await SupabaseService.client
        .from(_tableName)
        .select()
        .order('like', ascending: false)
        .limit(limit ?? 10);

    return (response as List<dynamic>)
        .map((json) => Instructor.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Stream instructors for real-time updates
  Stream<List<Instructor>> streamInstructors() {
    return SupabaseService.client
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .map((data) => data
            .map((json) => Instructor.fromJson(json))
            .toList());
  }
}
