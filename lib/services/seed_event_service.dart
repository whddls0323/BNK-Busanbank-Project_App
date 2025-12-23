import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tkbank/models/seed_event_status.dart';
import 'package:tkbank/models/seed_plant_result.dart';
import 'token_storage_service.dart';

class SeedEventService {
  final String baseUrl = 'http://10.0.2.2:8080/busanbank';
  final TokenStorageService _tokenStorage = TokenStorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 이벤트 상태 조회
  Future<SeedEventStatus> getStatus() async {
    final headers = await _getHeaders();

    final response = await http.get(
      Uri.parse('$baseUrl/api/event/status'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('이벤트 상태 조회 실패: ${response.statusCode}');
    }

    return SeedEventStatus.fromJson(
      jsonDecode(response.body),
    );
  }

  /// 금열매 (이벤트 참여)
  Future<SeedPlantResult> plantSeed() async {
    final headers = await _getHeaders();

    final response = await http.post(
      Uri.parse('$baseUrl/api/event/gold'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('씨앗 심기 실패: ${response.statusCode}');
    }

    return SeedPlantResult.fromJson(
      jsonDecode(response.body),
    );
  }
}
