import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/user_model.dart';


class AuthResult {
  final User? user;
  final String? token;
  final String? error;

  AuthResult({this.user, this.token, this.error});
}

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  Uri _uri(String path) {
    if (kBaseUrl.startsWith('http')) {
      return Uri.parse('$kBaseUrl$path');
    }
    return Uri.http(kBaseUrl, path);
  }

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<AuthResult> register(String username, String password) async {
    try {
      final response = await http.post(
        _uri('/api/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return AuthResult(
          user: User.fromJson(data['user']),
          token: data['token'],
        );
      } else {
        final data = jsonDecode(response.body);
        return AuthResult(error: data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      return AuthResult(error: 'Network error: $e');
    }
  }

  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await http.post(
        _uri('/api/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AuthResult(
          user: User.fromJson(data['user']),
          token: data['token'],
        );
      } else {
        final data = jsonDecode(response.body);
        return AuthResult(error: data['error'] ?? 'Login failed');
      }
    } catch (e) {
      return AuthResult(error: 'Network error: $e');
    }
  }
}
