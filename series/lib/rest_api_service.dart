import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'rest_series_model.dart';

/// ข้อผิดพลาดที่เกิดจาก REST API
class RestApiException implements Exception {
  final String message;

  const RestApiException(this.message);

  @override
  String toString() => message;
}

/// ชั้นติดต่อเซิร์ฟเวอร์ของแท็บ “ซีรีส์ออนไลน์ (REST API)”
///
/// เปลี่ยน URL ตอนรันได้ เช่น:
/// flutter run --dart-define=REST_API_BASE_URL=http://10.0.2.2:3000/api
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

  /// GET: อ่านซีรีส์ทั้งหมดของผู้ใช้จากเซิร์ฟเวอร์
  static Future<List<RestSeriesItem>> getSeries() async {
    final response = await http.get(
      Uri.parse('$baseUrl/series'),
      headers: await _headers(),
    );
    _checkSuccess(response, expectedStatus: 200);

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(RestSeriesItem.fromJson)
        .toList();
  }

  /// POST: เพิ่มซีรีส์ใหม่บนเซิร์ฟเวอร์
  static Future<RestSeriesItem> createSeries(RestSeriesItem item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/series'),
      headers: await _headers(),
      body: jsonEncode(item.toJson()),
    );
    _checkSuccess(response, expectedStatus: 201);

    return RestSeriesItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// PUT: แทนที่ข้อมูลซีรีส์เดิมด้วยข้อมูลชุดใหม่
  static Future<RestSeriesItem> updateSeries(RestSeriesItem item) async {
    final id = item.id;
    if (id == null) {
      throw const RestApiException('ไม่พบรหัสซีรีส์ที่ต้องการแก้ไข');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/series/$id'),
      headers: await _headers(),
      body: jsonEncode(item.toJson()),
    );
    _checkSuccess(response, expectedStatus: 200);

    return RestSeriesItem.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// DELETE: ลบซีรีส์ออกจากเซิร์ฟเวอร์
  static Future<void> deleteSeries({required int id}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/series/$id'),
      headers: await _headers(),
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
    } catch (_) {
      // ใช้ข้อความเริ่มต้นเมื่อเซิร์ฟเวอร์ส่งคำตอบที่ไม่ใช่ JSON
    }
    throw RestApiException(message);
  }
}
