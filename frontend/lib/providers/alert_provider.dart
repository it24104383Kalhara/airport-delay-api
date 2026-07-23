// ============================================================
//  alert_provider.dart
//  ChangeNotifier-based state manager for the alert list.
//  Wraps ApiService and exposes loading/error state for the UI.
// ============================================================

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';

enum ProviderState { idle, loading, success, error }

class AlertProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  // ── Public state ──────────────────────────────────────────
  List<FlightDelayAlert> _alerts = [];
  ProviderState _state = ProviderState.idle;
  String? _errorMessage;

  List<FlightDelayAlert> get alerts => List.unmodifiable(_alerts);
  ProviderState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ProviderState.loading;

  // ── Derived counts (used on the Home screen) ──────────────
  int get activeCount =>
      _alerts.where((a) => a.status == AlertStatus.active).length;

  int get criticalCount =>
      _alerts
          .where(
            (a) =>
                a.status == AlertStatus.active &&
                a.severityLevel == SeverityLevel.critical,
          )
          .length;

  List<FlightDelayAlert> get criticalAlerts {
    return _alerts
        .where(
          (a) =>
              a.status == AlertStatus.active &&
              a.severityLevel == SeverityLevel.critical,
        )
        .toList();
  }

  // ── LOAD ALL ──────────────────────────────────────────────
  Future<void> loadAlerts() async {
    _setState(ProviderState.loading);
    try {
      _alerts = await _api.getAlerts();
      _setState(ProviderState.success);
    } on ApiException catch (e) {
      _setError(e.message);
    }
  }

  // ── CREATE ────────────────────────────────────────────────
  Future<bool> createAlert(FlightDelayAlert alert) async {
    _setState(ProviderState.loading);
    try {
      final created = await _api.createAlert(alert);
      _alerts.insert(0, created); // prepend so it appears at top
      _setState(ProviderState.success);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ── UPDATE ────────────────────────────────────────────────
  Future<bool> updateAlert(String id, FlightDelayAlert alert) async {
    _setState(ProviderState.loading);
    try {
      final updated = await _api.updateAlert(id, alert);
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alerts[index] = updated;
      }
      _setState(ProviderState.success);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ── ARCHIVE (Soft-Delete) ──────────────────────────────────
  Future<bool> archiveAlert(String id) async {
    _setState(ProviderState.loading);
    try {
      await _api.archiveAlert(id);
      _alerts.removeWhere((a) => a.id == id);
      _setState(ProviderState.success);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ── DELETE (user-initiated permanent remove) ───────────────
  /// Calls deleteAlert on the API and immediately removes the record
  /// from local state. From the user's perspective this is permanent.
  Future<bool> deleteAlert(String id) async {
    _setState(ProviderState.loading);
    try {
      await _api.deleteAlert(id);
      _alerts.removeWhere((a) => a.id == id);
      _setState(ProviderState.success);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }


  // ── Private helpers ───────────────────────────────────────
  void _setState(ProviderState s) {
    _state = s;
    if (s != ProviderState.error) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _state = ProviderState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear any transient error (e.g. after showing a SnackBar).
  void clearError() {
    _errorMessage = null;
    if (_state == ProviderState.error) {
      _state = ProviderState.idle;
    }
    notifyListeners();
  }
}
