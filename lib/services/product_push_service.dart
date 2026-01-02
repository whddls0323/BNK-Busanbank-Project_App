import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tkbank/services/token_storage_service.dart';

//가입 완료 푸시 알림 - 작성자: 윤종인 2025.12.31
class ProductPushService {
  static const String baseUrl = "http://10.0.2.2:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// ✅ JWT 토큰 헤더 생성 (자동)
  Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    // 인증이 필요한 요청이면 JWT 토큰 추가
    if (needsAuth) {
      final token = await _tokenStorage.readToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<void> productPush(String? productName, String userNo, {bool needsAuth = false}) async {
    final headers = await _getHeaders(needsAuth: needsAuth);

    final response = await http.post(
      Uri.parse('$baseUrl/api/productPush'),
      headers: headers,
      body: jsonEncode({
        'productName': productName,
        'userNo': userNo,
      }),
    );

    print('productPush status = ${response.statusCode}');
    print('productPush body = ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('전송 실패');
    }
  }
}