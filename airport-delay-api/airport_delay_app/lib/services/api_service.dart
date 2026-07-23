// ============================================================
//  api_service.dart
//  Handles all HTTP communication with the Go/Gin backend.
//
//  Base URL is configured in core/constants.dart.
//  All methods throw an ApiException on non-2xx responses so
//  the Provider layer can catch and surface errors cleanly.
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/alert_model.dart';

// ─── Custom exception ────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─── Service ─────────────────────────────────────────────────
class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  // Shared headers for every request
  static const Map<String, String> _headers = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.acceptHeader: 'application/json',
  };

  // Helper: build a full URI from a path
  Uri _uri(String path) => Uri.parse('$kBaseUrl$path');

  // Helper: check response status and throw on error
  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = 'Request failed';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? message;
    } catch (_) {
      // Body wasn't JSON — use status text
      message = 'HTTP ${response.statusCode}';
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  // ── 1. READ ALL — GET /api/alerts ────────────────────────
  /// Returns all non-archived alerts ordered by latest first.
  Future<List<FlightDelayAlert>> getAlerts() async {
    try {
      final response = await http
          .get(_uri(kAlertsEndpoint), headers: _headers)
          .timeout(const Duration(seconds: 15));

      _checkResponse(response);

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .map((e) => FlightDelayAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'No connection — is the backend running?',
      );
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ── 2. READ ONE — GET /api/alerts/:id ───────────────────
  Future<FlightDelayAlert> getAlertById(String id) async {
    try {
      final response = await http
          .get(_uri('$kAlertsEndpoint/$id'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      _checkResponse(response);

      return FlightDelayAlert.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No connection — is the backend running?');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ── 3. CREATE — POST /api/alerts ─────────────────────────
  /// [alert.id] should be null; the backend generates the UUID.
  /// Timestamps in the payload are always UTC ISO-8601.
  Future<FlightDelayAlert> createAlert(FlightDelayAlert alert) async {
    try {
      final response = await http
          .post(
            _uri(kAlertsEndpoint),
            headers: _headers,
            body: jsonEncode(alert.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      _checkResponse(response);

      return FlightDelayAlert.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No connection — is the backend running?');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ── 4. UPDATE — PUT /api/alerts/:id ─────────────────────
  Future<FlightDelayAlert> updateAlert(
    String id,
    FlightDelayAlert alert,
  ) async {
    try {
      final response = await http
          .put(
            _uri('$kAlertsEndpoint/$id'),
            headers: _headers,
            body: jsonEncode(alert.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      _checkResponse(response);

      // The backend returns the original record (before update);
      // fetch fresh to guarantee the UI reflects server state.
      return getAlertById(id);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No connection — is the backend running?');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ── 5. ARCHIVE (Soft-Delete) — DELETE /api/alerts/:id ───
  /// The backend sets status = ARCHIVED rather than hard-deleting.
  /// Used for aviation compliance record-keeping (shows as 'archived' intent).
  Future<void> archiveAlert(String id) async {
    try {
      final response = await http
          .delete(_uri('$kAlertsEndpoint/$id'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      _checkResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No connection — is the backend running?');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ── 6. DELETE — DELETE /api/alerts/:id ──────────────────
  /// Explicit user-initiated delete. Calls the same DELETE endpoint;
  /// the backend soft-deletes (ARCHIVED), permanently removing it
  /// from all active dashboard views.
  Future<void> deleteAlert(String id) async {
    try {
      final response = await http
          .delete(_uri('$kAlertsEndpoint/$id'), headers: _headers)
          .timeout(const Duration(seconds: 15));

      _checkResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('No connection — is the backend running?');
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }
}
