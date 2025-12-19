import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/email_counsel_form_data.dart';
import '../../models/email_counsel_create_request.dart';
import '../../models/email_counsel_item.dart';
import '../token_storage_service.dart';

class EmailCounselApiService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";

  Future<String> _mustToken() async {
    final token = await TokenStorageService().readToken();
    if (token == null || token.isEmpty) {
      throw Exception("토큰이 없습니다. 다시 로그인 해주세요.");
    }
    return token;
  }

  // GET /api/cs/email/form
  Future<EmailCounselFormData> fetchForm() async {
    final token = await _mustToken();

    final uri = Uri.parse("$baseUrl/api/cs/email/form");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    });

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: $body");
    }

    final root = jsonDecode(body);
    final data = (root is Map && root["data"] != null) ? root["data"] : root;

    return EmailCounselFormData.fromJson((data as Map).cast<String, dynamic>());
  }

  // POST /api/cs/email
  Future<void> submit(EmailCounselCreateRequest req) async {
    final token = await _mustToken();

    final uri = Uri.parse("$baseUrl/api/cs/email");
    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(req.toJson()),
    );

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: $body");
    }
  }

  // GET /api/cs/email/my
  Future<List<EmailCounselItem>> fetchMyList() async {
    final token = await _mustToken();

    final uri = Uri.parse("$baseUrl/api/cs/email/my");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    });

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: $body");
    }

    final root = jsonDecode(body);
    final data = (root is Map && root["data"] != null) ? root["data"] : root;

    final list = (data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => EmailCounselItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  // GET /api/cs/email/{id}
  Future<EmailCounselItem> fetchDetail(int ecounselId) async {
    final token = await _mustToken();

    final uri = Uri.parse("$baseUrl/api/cs/email/$ecounselId");
    final res = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    });

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: $body");
    }

    final root = jsonDecode(body);
    final data = (root is Map && root["data"] != null) ? root["data"] : root;

    return EmailCounselItem.fromJson((data as Map).cast<String, dynamic>());
  }
}
