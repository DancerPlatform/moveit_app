import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/supabase_service.dart';

class FavoriteProvider extends ChangeNotifier {
  static const String _academyFavoritesTable = 'academy_favorites';
  static const String _instructorFavoritesTable = 'instructor_favorites';

  Set<String> _favoriteAcademyIds = {};
  Set<String> _favoriteInstructorIds = {};
  bool _isLoading = false;
  StreamSubscription? _authSubscription;

  FavoriteProvider() {
    _authSubscription = SupabaseService.authStateChanges.listen((state) {
      if (state.session?.user != null) {
        loadFavorites();
      } else {
        _clearFavorites();
      }
    });

    // Load favorites if already logged in
    if (SupabaseService.isLoggedIn) {
      loadFavorites();
    }
  }

  Set<String> get favoriteAcademyIds => _favoriteAcademyIds;
  Set<String> get favoriteInstructorIds => _favoriteInstructorIds;
  bool get isLoading => _isLoading;

  bool isAcademyFavorite(String academyId) =>
      _favoriteAcademyIds.contains(academyId);

  bool isInstructorFavorite(String instructorId) =>
      _favoriteInstructorIds.contains(instructorId);

  void _clearFavorites() {
    _favoriteAcademyIds = {};
    _favoriteInstructorIds = {};
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _loadAcademyFavorites(userId),
        _loadInstructorFavorites(userId),
      ]);

      _favoriteAcademyIds = results[0];
      _favoriteInstructorIds = results[1];
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Set<String>> _loadAcademyFavorites(String userId) async {
    final response = await SupabaseService.client
        .from(_academyFavoritesTable)
        .select('academy_id')
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .map((row) => row['academy_id'] as String)
        .toSet();
  }

  Future<Set<String>> _loadInstructorFavorites(String userId) async {
    final response = await SupabaseService.client
        .from(_instructorFavoritesTable)
        .select('instructor_id')
        .eq('user_id', userId);

    return (response as List<dynamic>)
        .map((row) => row['instructor_id'] as String)
        .toSet();
  }

  Future<bool> toggleAcademyFavorite(String academyId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    final isFavorite = _favoriteAcademyIds.contains(academyId);

    // Optimistic update
    if (isFavorite) {
      _favoriteAcademyIds.remove(academyId);
    } else {
      _favoriteAcademyIds.add(academyId);
    }
    notifyListeners();

    try {
      if (isFavorite) {
        await SupabaseService.client
            .from(_academyFavoritesTable)
            .delete()
            .eq('user_id', userId)
            .eq('academy_id', academyId);
      } else {
        await SupabaseService.client.from(_academyFavoritesTable).insert({
          'user_id': userId,
          'academy_id': academyId,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error toggling academy favorite: $e');
      // Revert optimistic update on error
      if (isFavorite) {
        _favoriteAcademyIds.add(academyId);
      } else {
        _favoriteAcademyIds.remove(academyId);
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleInstructorFavorite(String instructorId) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return false;

    final isFavorite = _favoriteInstructorIds.contains(instructorId);

    // Optimistic update
    if (isFavorite) {
      _favoriteInstructorIds.remove(instructorId);
    } else {
      _favoriteInstructorIds.add(instructorId);
    }
    notifyListeners();

    try {
      if (isFavorite) {
        await SupabaseService.client
            .from(_instructorFavoritesTable)
            .delete()
            .eq('user_id', userId)
            .eq('instructor_id', instructorId);
      } else {
        await SupabaseService.client.from(_instructorFavoritesTable).insert({
          'user_id': userId,
          'instructor_id': instructorId,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error toggling instructor favorite: $e');
      // Revert optimistic update on error
      if (isFavorite) {
        _favoriteInstructorIds.add(instructorId);
      } else {
        _favoriteInstructorIds.remove(instructorId);
      }
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}