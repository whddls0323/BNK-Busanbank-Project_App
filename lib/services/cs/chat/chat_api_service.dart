import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tkbank/models/chat_history_message.dart';
import 'package:tkbank/models/chat_session_summary.dart';
import 'package:tkbank/models/cursor_page.dart';

import '../../token_storage_service.dart';

class ChatApiService {
  final String baseUrl = "http://10.0.2.2:8080/busanbank";

  /// 세션 생성 API 호출 (JWT 필요)
  Future<int?> startChatSession({
    required String inquiryType,
  }) async {
    final url = Uri.parse("$baseUrl/api/chat/start");

    final token = await TokenStorageService().readToken();
    if (token == null || token.isEmpty) {
      print("❌ 토큰 없음. 로그인 필요");
      return null;
    }

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "inquiryType": inquiryType,
      }),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json["status"] == "SUCCESS") return json["sessionId"] as int;
      print("❌ 세션 생성 실패: ${json["message"]}");
      return null;
    }

    print("❌ 세션 생성 HTTP 오류: ${response.statusCode} / body=${response.body}");
    return null;
  }

  // =========================
  // ✅ 지난 상담 세션 목록
  // =========================
  Future<CursorPage<ChatSessionSummary>> fetchChatHistorySessions({
    String? cursor,
    int size = 20,
  }) async {
    final token = await TokenStorageService().readToken();
    if (token == null || token.isEmpty) {
      throw Exception("토큰이 없습니다. 다시 로그인 해주세요.");
    }

    final uri = Uri.parse("$baseUrl/api/chat/history/sessions").replace(
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) "cursor": cursor,
        "size": size.toString(),
      },
    );

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    });

    final bodyText = utf8.decode(response.bodyBytes);
    print("🟦 [history sessions] GET $uri");
    print("🟥 status=${response.statusCode}");
    print("🟥 body=$bodyText");

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}: $bodyText");
    }

    final root = jsonDecode(bodyText);

    // ✅ 1) 서버가 {status, data}로 감싸는 경우 대응
    final data = (root is Map && root["data"] != null) ? root["data"] : root;

    // ✅ 2) items가 null이면 빈 리스트
    final rawItems = (data["items"] as List?) ?? const [];
    final items = rawItems
        .map((e) => ChatSessionSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    return CursorPage(
      items: items,
      nextCursor: data["nextCursor"] as String?,
    );
  }


  // =========================
  // ✅ 지난 상담 메시지
  // =========================
  Future<CursorPage<ChatHistoryMessage>> fetchChatHistoryMessages({
    required int sessionId,
    String? cursor,
    int size = 50,
  }) async {
    final token = await TokenStorageService().readToken();
    if (token == null || token.isEmpty) {
      throw Exception("토큰이 없습니다. 다시 로그인 해주세요.");
    }

    final uri = Uri.parse(
        "$baseUrl/api/chat/history/sessions/$sessionId/messages").replace(
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) "cursor": cursor,
        "size": size.toString(),
      },
    );

    final response = await http.get(uri, headers: {
      "Authorization": "Bearer $token",
    });

    final bodyText = utf8.decode(response.bodyBytes);
    print("🟦 [history messages] GET $uri");
    print("🟥 status=${response.statusCode}");
    print("🟥 body=$bodyText");

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}: $bodyText");
    }

    final root = jsonDecode(bodyText);
    final data = (root is Map && root["data"] != null) ? root["data"] : root;

    final rawItems = (data["items"] as List?) ?? const [];
    final items = rawItems
        .map((e) => ChatHistoryMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    return CursorPage(
      items: items,
      nextCursor: data["nextCursor"] as String?,
    );
  }
}
