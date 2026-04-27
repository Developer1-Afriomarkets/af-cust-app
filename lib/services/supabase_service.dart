import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afriomarkets_cust_app/app_config.dart';

/// Central Supabase service — single source of truth for the Supabase client.
/// Initialize once in main.dart and access anywhere via [SupabaseService.client].
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Call this from main() before runApp()
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.SUPABASE_URL,
      anonKey: AppConfig.SUPABASE_ANON_KEY,
    );
  }
}
