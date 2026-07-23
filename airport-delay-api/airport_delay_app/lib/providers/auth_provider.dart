import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthState { initial, unauthenticated, authenticating, authenticated, error }

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _token;
  AuthState _state = AuthState.initial;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _user?.isAdmin ?? false;

  final AuthService _authService = AuthService.instance;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userData = prefs.getString('auth_user');

    if (token != null && userData != null) {
      _token = token;
      _user = User.fromJson(jsonDecode(userData));
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _setState(AuthState.authenticating);
    final result = await _authService.login(username, password);
    return _handleAuthResult(result);
  }

  Future<bool> register(String username, String password) async {
    _setState(AuthState.authenticating);
    final result = await _authService.register(username, password);
    return _handleAuthResult(result);
  }

  Future<bool> _handleAuthResult(AuthResult result) async {
    if (result.user != null && result.token != null) {
      _user = result.user;
      _token = result.token;
      
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_user', jsonEncode({
        'id': _user!.id,
        'username': _user!.username,
        'is_admin': _user!.isAdmin,
      }));

      _setState(AuthState.authenticated);
      return true;
    } else {
      _errorMessage = result.error;
      _setState(AuthState.error);
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    _setState(AuthState.unauthenticated);
  }

  void _setState(AuthState s) {
    _state = s;
    if (s != AuthState.error) _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
