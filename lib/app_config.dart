import 'package:flutter/material.dart';

var this_year = DateTime.now().year.toString();

class AppConfig {
  static String copyright_text = "© Afriomarkets " + this_year;
  static String app_name = "Afriomarkets";

  // Purchase code (retained from legacy, update with real code when ready)
  static String purchase_code = "";

  // ═══════════════════════════════════════════════════════════════════════════
  // API Configuration
  // The app talks to both Medusa (e-commerce) and Supabase (auth/data).
  // The legacy ActiveItZone REST API path is kept for backward compatibility
  // but will be replaced by Medusa/Supabase calls via the Repository pattern.
  // ═══════════════════════════════════════════════════════════════════════════

  static const bool HTTPS = true;

  // TODO: Replace with your Medusa storefront URL
  static const DOMAIN_PATH = "eke.afriomarkets.com";

  // Legacy API paths (to be replaced by Medusa SDK calls)
  static const String API_V1_ENDPATH = "store";
  static const String API_V2_ENDPATH = "store/v2";

  // Active API Version
  static const String API_ENDPATH = API_V1_ENDPATH;

  static const String PUBLIC_FOLDER = "public";
  static const String PROTOCOL = HTTPS ? "https://" : "http://";
  static const String RAW_BASE_URL = "${PROTOCOL}${DOMAIN_PATH}";
  static const String BASE_URL = "${RAW_BASE_URL}/${API_ENDPATH}";
  static const String BASE_PATH = "${RAW_BASE_URL}/${PUBLIC_FOLDER}/";

  // ═══════════════════════════════════════════════════════════════════════════
  // Supabase Configuration
  // ═══════════════════════════════════════════════════════════════════════════
  static const String SUPABASE_URL = "https://ehhevvujhtrjgcznewzg.supabase.co";
  static const String SUPABASE_ANON_KEY =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVoaGV2dnVqaHRyamdjem5ld3pnIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTUwNTkzMjksImV4cCI6MjAxMDYzNTMyOX0.a9M0o-hG6NemMGxXJLZb4dIzA-2r4m1bzBB8dCfr7_Q";

  // ═══════════════════════════════════════════════════════════════════════════
  // Medusa Configuration
  // ═══════════════════════════════════════════════════════════════════════════
  static const String MEDUSA_BASE_URL = "https://eke.afriomarkets.com";
}
