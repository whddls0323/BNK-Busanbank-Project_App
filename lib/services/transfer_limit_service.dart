/*
  날짜: 2025/12/29
  내용: 이체한도 설정 서비스
  작성자: 오서정
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

class TransferLimitService {
  final String baseUrl = 'http://192.168.219.105:8080/busanbank';
  final TokenStorageService _tokenStorage = TokenStorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getTransferLimit() async {
    final headers = await _getHeaders();

    final res = await http.get(
      Uri.parse('$baseUrl/api/transfer/limit'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception('이체한도 조회 실패: ${res.statusCode}');
    }

    return jsonDecode(res.body);
  }

  Future<void> updateTransferLimit(int onceLimit, int dailyLimit) async {
    final headers = await _getHeaders();

    final res = await http.post(
      Uri.parse('$baseUrl/api/transfer/limit'),
      headers: headers,
      body: jsonEncode({
        'onceLimit': onceLimit,
        'dailyLimit': dailyLimit,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('이체한도 변경 실패: ${res.statusCode}');
    }
  }
}
