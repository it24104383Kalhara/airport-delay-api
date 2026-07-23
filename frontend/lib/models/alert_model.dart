// ============================================================
//  alert_model.dart
//  Dart model mirroring the Go FlightDelayAlert struct.
//  - fromJson parses snake_case JSON from the API.
//  - toJson produces snake_case JSON for POST / PUT payloads.
//  - DateTime fields are always stored as UTC internally.
//    Use .toLocal() only in the UI layer for display.
// ============================================================

import '../core/constants.dart';

class FlightDelayAlert {
  final String? id;               // null when creating (backend generates)
  final String flightNumber;
  final String airline;
  final String destination;
  final String terminalZone;
  final DateTime originalDeparture; // stored as UTC
  final DateTime newDeparture;      // stored as UTC
  final String delayReason;
  final SeverityLevel severityLevel;
  final AlertStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FlightDelayAlert({
    this.id,
    required this.flightNumber,
    required this.airline,
    required this.destination,
    required this.terminalZone,
    required this.originalDeparture,
    required this.newDeparture,
    required this.delayReason,
    required this.severityLevel,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  // ── Factory: JSON (API) → Dart ──────────────────────────
  factory FlightDelayAlert.fromJson(Map<String, dynamic> json) {
    return FlightDelayAlert(
      id: json['id'] as String?,
      flightNumber: json['flight_number'] as String? ?? '',
      airline: json['airline'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      terminalZone: json['terminal_zone'] as String? ?? '',
      // Parse ISO8601 strings and ensure they are UTC-flagged
      originalDeparture: DateTime.parse(
        json['original_departure'] as String,
      ).toUtc(),
      newDeparture: DateTime.parse(
        json['new_departure'] as String,
      ).toUtc(),
      delayReason: json['delay_reason'] as String? ?? '',
      severityLevel: SeverityLevel.fromString(
        json['severity_level'] as String?,
      ),
      status: AlertStatus.fromString(
        json['status'] as String?,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toUtc()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toUtc()
          : null,
    );
  }

  // ── Serialiser: Dart → JSON (API) ────────────────────────
  /// IMPORTANT: timestamps are sent as strict UTC ISO-8601
  /// (e.g. "2026-07-21T15:30:00.000Z") as required by the backend.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'flight_number': flightNumber,
      'airline': airline,
      'destination': destination,
      'terminal_zone': terminalZone,
      // Always transmit in UTC — toUtc() is a no-op if already UTC
      'original_departure': originalDeparture.toUtc().toIso8601String(),
      'new_departure': newDeparture.toUtc().toIso8601String(),
      'delay_reason': delayReason,
      'severity_level': severityLevel.value,
      'status': status.value,
    };
  }

  // ── copyWith (for local state mutations) ─────────────────
  FlightDelayAlert copyWith({
    String? id,
    String? flightNumber,
    String? airline,
    String? destination,
    String? terminalZone,
    DateTime? originalDeparture,
    DateTime? newDeparture,
    String? delayReason,
    SeverityLevel? severityLevel,
    AlertStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlightDelayAlert(
      id: id ?? this.id,
      flightNumber: flightNumber ?? this.flightNumber,
      airline: airline ?? this.airline,
      destination: destination ?? this.destination,
      terminalZone: terminalZone ?? this.terminalZone,
      originalDeparture: originalDeparture ?? this.originalDeparture,
      newDeparture: newDeparture ?? this.newDeparture,
      delayReason: delayReason ?? this.delayReason,
      severityLevel: severityLevel ?? this.severityLevel,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'FlightDelayAlert(id: $id, flight: $flightNumber, status: ${status.value})';
}
