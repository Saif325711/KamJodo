import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'storage_service.dart';

class BookingService {
  static String get _base => '${AuthService.baseUrl}/api/v1';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Customer creates a booking
  static Future<Map<String, dynamic>> createBooking({
    required String workerId,
    String? categoryId,
    String? description,
    String? notes,
    DateTime? scheduledAt,
    double estimatedPrice = 0,
    Map<String, dynamic>? customerAddress,
  }) async {
    final body = {
      'workerId': workerId,
      if (categoryId != null) 'categoryId': categoryId,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      'estimatedPrice': estimatedPrice,
      if (customerAddress != null) 'customerAddress': customerAddress,
    };

    final response = await http.post(
      Uri.parse('$_base/bookings'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get my bookings (customer or worker perspective)
  static Future<List<dynamic>> getMyBookings({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$_base/bookings/me').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _authHeaders());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>?) ?? [];
  }

  /// Get single booking detail
  static Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    final response = await http.get(
      Uri.parse('$_base/bookings/$bookingId'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['success'] == true ? body['data'] as Map<String, dynamic>? : null;
  }

  /// Worker accepts booking
  static Future<Map<String, dynamic>> acceptBooking(String bookingId) async {
    final response = await http.post(
      Uri.parse('$_base/bookings/$bookingId/accept'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Worker rejects booking
  static Future<Map<String, dynamic>> rejectBooking(String bookingId, {String? reason}) async {
    final response = await http.post(
      Uri.parse('$_base/bookings/$bookingId/reject'),
      headers: await _authHeaders(),
      body: jsonEncode({'reason': reason ?? ''}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Worker updates booking status (worker_on_the_way -> arrived -> service_started -> service_completed)
  static Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    final response = await http.patch(
      Uri.parse('$_base/bookings/$bookingId/status'),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Cancel booking (Customer or Worker)
  static Future<bool> cancelBooking(String bookingId, {String reason = ''}) async {
    final response = await http.post(
      Uri.parse('$_base/bookings/$bookingId/cancel'),
      headers: await _authHeaders(),
      body: jsonEncode({'reason': reason}),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['success'] == true;
  }

  /// Submit review after completed booking
  static Future<Map<String, dynamic>> submitReview(
    String bookingId, {
    required int rating,
    String comment = '',
  }) async {
    final response = await http.post(
      Uri.parse('$_base/bookings/$bookingId/review'),
      headers: await _authHeaders(),
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
