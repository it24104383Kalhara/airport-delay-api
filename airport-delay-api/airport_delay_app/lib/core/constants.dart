// ============================================================
//  constants.dart
//  Central place for all app-wide constants, enums, and the
//  API base URL. To switch between emulator and production,
//  comment/uncomment the two kBaseUrl lines below.
// ============================================================

// --------------- API BASE URL --------------------------------
/// EMULATOR TESTING: Android emulator maps 10.0.2.2 → host's localhost.
const String kBaseUrl = 'http://10.0.2.2:8080';

/// PRODUCTION (WSO2 Choreo): When you are ready to build the release APK,
/// comment out the emulator URL above and uncomment the line below,
/// replacing the placeholder with your actual Choreo service URL.
/// Example:
// const String kBaseUrl = 'https://your-service-name.choreoapis.dev';

// --------------- API ENDPOINTS -------------------------------
const String kAlertsEndpoint = '/api/alerts';

// --------------- SEVERITY LEVELS -----------------------------
/// Maps to the backend `severity_level` column values.
enum SeverityLevel {
  critical,
  moderate,
  low;

  /// Returns the exact string the backend/database expects.
  /// NOTE: The DB column uses 'MEDIUM' (not 'MODERATE') due to
  /// the Supabase CHECK constraint matching the Go model default.
  String get value {
    switch (this) {
      case SeverityLevel.critical:
        return 'CRITICAL';
      case SeverityLevel.moderate:
        return 'MEDIUM'; // DB CHECK constraint: LOW | MEDIUM | HIGH | CRITICAL
      case SeverityLevel.low:
        return 'LOW';
    }
  }

  /// Parses a raw string from the API into the enum.
  /// Handles both 'MEDIUM' (DB value) and 'MODERATE' (legacy) gracefully.
  static SeverityLevel fromString(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'CRITICAL':
        return SeverityLevel.critical;
      case 'MODERATE': // legacy / display alias
      case 'MEDIUM':   // actual DB value
      case 'HIGH':     // if DB uses HIGH
        return SeverityLevel.moderate;
      default:
        return SeverityLevel.low;
    }
  }

  String get label {
    switch (this) {
      case SeverityLevel.critical:
        return 'CRITICAL';
      case SeverityLevel.moderate:
        return 'MODERATE';
      case SeverityLevel.low:
        return 'LOW';
    }
  }
}

// --------------- ALERT STATUS --------------------------------
/// Maps to the backend `status` column values.
enum AlertStatus {
  active,
  resolved,
  cancelled,
  archived;

  String get value {
    switch (this) {
      case AlertStatus.active:
        return 'ACTIVE';
      case AlertStatus.resolved:
        return 'RESOLVED';
      case AlertStatus.cancelled:
        return 'CANCELLED';
      case AlertStatus.archived:
        return 'ARCHIVED';
    }
  }

  static AlertStatus fromString(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'RESOLVED':
        return AlertStatus.resolved;
      case 'CANCELLED':
        return AlertStatus.cancelled;
      case 'ARCHIVED':
        return AlertStatus.archived;
      default:
        return AlertStatus.active;
    }
  }

  String get label {
    switch (this) {
      case AlertStatus.active:
        return 'ACTIVE';
      case AlertStatus.resolved:
        return 'RESOLVED';
      case AlertStatus.cancelled:
        return 'CANCELLED';
      case AlertStatus.archived:
        return 'ARCHIVED';
    }
  }
}
