import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService.initialize();

  // Initialize location provider early
  final locationProvider = LocationProvider();
  // Don't await - let it load in background to avoid blocking app startup
  locationProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: locationProvider),
      ],
      child: const DancerApp(),
    ),
  );
}
