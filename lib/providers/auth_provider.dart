import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  late final StreamSubscription<AuthState> _authSubscription;

  AuthProvider() {
    _user = SupabaseService.currentUser;
    _authSubscription = SupabaseService.authStateChanges.listen((state) {
      _user = state.session?.user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.id;
  String? get userEmail => _user?.email;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign out
  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await SupabaseService.client.auth.resetPasswordForEmail(email);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
