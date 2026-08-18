import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'storage_service.dart';

class WorkerService {
  static String get _base => '${AuthService.baseUrl}/api/v1';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getMyWorkerProfile() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/workers/me/profile'), headers: await _authHeaders())
          .timeout(const Duration(seconds: 5));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'data': null};
    }
  }

  static Future<Map<String, dynamic>> updateMyWorkerProfile(Map<String, dynamic> data) async {
    try {
      final response = await http
          .patch(Uri.parse('$_base/workers/me'), headers: await _authHeaders(), body: jsonEncode(data))
          .timeout(const Duration(seconds: 5));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> setAvailability({bool? isOnline}) async {
    try {
      final body = <String, dynamic>{};
      if (isOnline != null) body['isOnline'] = isOnline;
      final response = await http
          .patch(Uri.parse('$_base/workers/me/availability'), headers: await _authHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 5));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': true};
    }
  }

  static Future<Map<String, dynamic>> createPost({
    required String title,
    String? categoryId,
    String? description,
    double startingPrice = 0,
    double serviceRadiusKm = 10,
  }) async {
    final body = {
      'title': title,
      if (categoryId != null) 'categoryId': categoryId,
      if (description != null) 'description': description,
      'startingPrice': startingPrice,
      'serviceRadiusKm': serviceRadiusKm,
    };
    try {
      final response = await http
          .post(Uri.parse('$_base/worker-posts'), headers: await _authHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 5));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<List<dynamic>> getMyPosts() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/worker-posts/me/all'), headers: await _authHeaders())
          .timeout(const Duration(seconds: 5));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/categories'), headers: await _authHeaders())
          .timeout(const Duration(seconds: 5));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      return [];
    }
  }
}
