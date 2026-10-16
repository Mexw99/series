import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'rest_series_model.dart';

class RestApiException implements Exception {
  final String message;

  const RestApiException(this.message);

  @override
  String toString() => message;
}

class RestApiService {
  static const String baseUrl = String.fromEnvironment(
    'REST_API_BASE_URL',
    defaultValue: 'https://series-rest-api.onrender.com/api',
  );

  static Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null || token.isEmpty) {
      throw const RestApiException('กรุณาเข้าสู่ระบบก่อนใช้ REST API');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    try {
      final headers = await _headers();
      return await request(headers).timeout(const Duration(seconds: 60));
    } on http.ClientException {
      throw const RestApiException(
        'ขออภัย ขณะนี้ยังเชื่อมต่อเซิร์ฟเวอร์ไม่ได้\n'
        'กรุณาตรวจสอบอินเทอร์เน็ตแล้วกด “ลองใหม่” อีกครั้ง',
      );
    } on TimeoutException {
      throw const RestApiException(
        'ขออภัย เซิร์ฟเวอร์ตอบสนองช้า\nกรุณากด “ลองใหม่” อีกครั้ง',
      );
    }
  }

  static Future<List<RestSeriesItem>> getSeries() async {
    final response = await _send(
      (headers) => http.get(Uri.parse('$baseUrl/series'), headers: headers),
    );
    _checkSuccess(response, expectedStatus: 200);

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(RestSeriesItem.fromJson)
        .toList();
  }

  static Future<RestSeriesItem> createSeries(RestSeriesItem item) async {
    final response = await _send(
      (headers) => http.post(
        Uri.parse('$baseUrl/series'),
        headers: headers,
        body: jsonEncode(item.toJson()),
      ),
    );
    _checkSuccess(response, expectedStatus: 201);

    return RestSeriesItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<RestSeriesItem> updateSeries(RestSeriesItem item) async {
    final id = item.id;
    if (id == null) {
      throw const RestApiException('ไม่พบรหัสซีรีส์ที่ต้องการแก้ไข');
    }

    final response = await _send(
      (headers) => http.put(
        Uri.parse('$baseUrl/series/$id'),
        headers: headers,
        body: jsonEncode(item.toJson()),
      ),
    );
    _checkSuccess(response, expectedStatus: 200);

    return RestSeriesItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  static Future<void> deleteSeries({required int id}) async {
    final response = await _send(
      (headers) =>
          http.delete(Uri.parse('$baseUrl/series/$id'), headers: headers),
    );
    _checkSuccess(response, expectedStatus: 204);
  }

  static void _checkSuccess(
    http.Response response, {
    required int expectedStatus,
  }) {
    if (response.statusCode == expectedStatus) return;

    String message = 'REST API ทำงานไม่สำเร็จ (${response.statusCode})';
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['message'] is String) message = data['message'] as String;
    } catch (_) {}
    throw RestApiException(message);
  }
}
