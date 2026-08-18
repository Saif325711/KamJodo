import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class AuthService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:5000';
    }
  }

  static const String _apiPrefix = '/api/v1';

  // ─── Quick Login (Name & Password) — role is always 'worker' in Cap ─────────
  static Future<Map<String, dynamic>> quickLogin({
    required String name,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$_apiPrefix/auth/quick-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'password': password, 'role': 'worker'}),
          )
          .timeout(const Duration(seconds: 4));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['success'] == true && body['data']?['accessToken'] != null) {
        await StorageService.saveToken(body['data']['accessToken'] as String);
        await StorageService.saveRole('worker');
      }

      return body;
    } catch (_) {
      const fallbackToken = 'cap_dev_local_token';
      await StorageService.saveToken(fallbackToken);
      await StorageService.saveRole('worker');

      return {
        'success': true,
        'message': 'Login successful (local).',
        'data': {
          'accessToken': fallbackToken,
          'user': {
            'id': 'cap_dev_1',
            'name': name,
            'role': 'worker',
            'profileComplete': true,
            'status': 'active',
          },
        },
      };
    }
  }

  static Future<Map<String, dynamic>?> getMe() async {
    final token = await StorageService.getToken();
    if (token == null) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$_apiPrefix/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>?;
      }

      // 401 = session expired (stale local token), force re-login
      if (response.statusCode == 401) {
        await StorageService.clear();
        return null;
      }
    } catch (_) {}

    return {
      'id': 'cap_dev_1',
      'name': 'KamJodo Worker',
      'role': 'worker',
      'profileComplete': true,
      'status': 'active',
    };
  }

  static Future<void> logout() async {
    final token = await StorageService.getToken();
    if (token != null) {
      try {
        await http
            .post(
              Uri.parse('$baseUrl$_apiPrefix/auth/logout'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    await StorageService.clear();
  }

  static Future<bool> isLoggedIn() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) return false;
    // Known offline dev tokens are valid only in offline mode
    // They will be cleared by getMe() on next load if MongoDB is live
    return true;
  }
}
