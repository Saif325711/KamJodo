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

  static Future<List<dynamic>> getMyBookings({String? status}) async {
    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      final uri = Uri.parse('$_base/bookings/me').replace(queryParameters: params);
      final response = await http.get(uri, headers: await _authHeaders()).timeout(const Duration(seconds: 5));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['data'] as List<dynamic>?) ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> acceptBooking(String bookingId) async {
    try {
      final response = await http
          .post(Uri.parse('$_base/bookings/$bookingId/accept'), headers: await _authHeaders())
          .timeout(const Duration(seconds: 5));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> rejectBooking(String bookingId, {String? reason}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_base/bookings/$bookingId/reject'),
            headers: await _authHeaders(),
            body: jsonEncode({'reason': reason ?? ''}),
          )
          .timeout(const Duration(seconds: 5));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_base/bookings/$bookingId/status'),
            headers: await _authHeaders(),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 5));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }
}
