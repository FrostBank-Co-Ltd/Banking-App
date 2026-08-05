import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central configuration for Supabase integration in FrostBank.
class SupabaseConfig {
  SupabaseConfig._();

  /// URL of the Supabase project. Can be provided via `--dart-define=SUPABASE_URL=...`
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://twkivwbonwzbkgiyllpo.supabase.co',
  );

  /// Anonymous key for the Supabase project. Can be provided via `--dart-define=SUPABASE_ANON_KEY=...`
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3a2l2d2Jvbnd6YmtnaXlsbHBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5MTI2MTQsImV4cCI6MjEwMTQ4ODYxNH0.qRHmgAYRoqDJMs9G2uOm6J8gbPUmtTrznimnh4Ykxtw',
  );

  /// Explicit flag to force-enable or disable Supabase backend.
  static const bool enabled = bool.fromEnvironment(
    'USE_SUPABASE',
    defaultValue: false,
  );

  /// Returns true if Supabase URL and Anon Key are validly set.
  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;

  /// Whether Supabase should be active (both enabled/configured).
  static bool get shouldInitialize => isConfigured || enabled;

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Initializes the Supabase client if credentials are configured.
  static Future<void> initialize() async {
    if (_initialized) return;

    if (!isConfigured) {
      debugPrint(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define or configure lib/core/supabase_config.dart.',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _initialized = true;
      debugPrint('Supabase initialized successfully.');
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
    }
  }

  /// Helper getter for the global Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;
}
