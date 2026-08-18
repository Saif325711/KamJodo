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

  // ─── Search Workers ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> searchWorkers({
    String? categoryId,
    double? latitude,
    double? longitude,
    double radiusKm = 20,
    bool? availableNow,
    bool? verifiedOnly,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (categoryId != null) params['categoryId'] = categoryId;
    if (latitude != null) params['latitude'] = latitude.toString();
    if (longitude != null) params['longitude'] = longitude.toString();
    if (availableNow == true) params['availableNow'] = 'true';
    if (verifiedOnly == true) params['verifiedOnly'] = 'true';
    if (search != null && search.isNotEmpty) params['search'] = search;
    params['radiusKm'] = radiusKm.toString();

    final uri = Uri.parse('$_base/workers').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _authHeaders());
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Get Worker Profile (Public) ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getWorkerProfile(String workerId) async {
    final response = await http.get(
      Uri.parse('$_base/workers/$workerId'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Get Own Worker Profile ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyWorkerProfile() async {
    final response = await http.get(
      Uri.parse('$_base/workers/me/profile'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Update Own Worker Profile / Onboarding ──────────────────────────────────
  static Future<Map<String, dynamic>> updateMyWorkerProfile(Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$_base/workers/me'),
      headers: await _authHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Toggle Worker Availability ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> setAvailability({bool? isOnline, bool? isAvailable}) async {
    final body = <String, dynamic>{};
    if (isOnline != null) body['isOnline'] = isOnline;
    if (isAvailable != null) body['isAvailable'] = isAvailable;

    final response = await http.patch(
      Uri.parse('$_base/workers/me/availability'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Worker Posts CRUD ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createPost({
    required String title,
    String? categoryId,
    String? description,
    double startingPrice = 0,
    double serviceRadiusKm = 10,
    List<String>? images,
  }) async {
    final body = {
      'title': title,
      if (categoryId != null) 'categoryId': categoryId,
      if (description != null) 'description': description,
      'startingPrice': startingPrice,
      'serviceRadiusKm': serviceRadiusKm,
      if (images != null) 'images': images,
    };

    final response = await http.post(
      Uri.parse('$_base/worker-posts'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMyPosts() async {
    final response = await http.get(
      Uri.parse('$_base/worker-posts/me/all'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>?) ?? [];
  }

  static Future<List<dynamic>> getWorkerPosts(String workerId) async {
    final response = await http.get(
      Uri.parse('$_base/workers/$workerId/posts'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>?) ?? [];
  }

  // ─── Worker Reviews ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getWorkerReviews(String workerId, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$_base/workers/$workerId/reviews?page=$page'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Categories ────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$_base/categories'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>?) ?? [];
  }

  // ─── Follow / Unfollow ──────────────────────────────────────────────────────
  static Future<bool> followWorker(String workerId) async {
    final response = await http.post(
      Uri.parse('$_base/workers/$workerId/follow'),
      headers: await _authHeaders(),
    );
    return response.statusCode == 201;
  }

  static Future<bool> unfollowWorker(String workerId) async {
    final response = await http.delete(
      Uri.parse('$_base/workers/$workerId/follow'),
      headers: await _authHeaders(),
    );
    return response.statusCode == 200;
  }

  static Future<bool> isFollowing(String workerId) async {
    final response = await http.get(
      Uri.parse('$_base/workers/$workerId/follow-status'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data']?['isFollowing'] == true;
  }
}
