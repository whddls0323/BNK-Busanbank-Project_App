import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/token_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  int? _userNo;  // ✅ 추가!
  String? _userId;  // ✅ 추가!

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  int? get userNo => _userNo;  // ✅ getter 추가!
  String? get userId => _userId;  // ✅ getter 추가!

  bool get isLoggedIn => _accessToken != null;

  Future<void> login(String userId, String userPw) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/busanbank/api/member/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userPw': userPw,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _userNo = data['userNo'];  // ✅ Backend에서 받아온 userNo 저장!
        _userId = userId;

        // 토큰 저장
        await TokenStorageService().saveToken(_accessToken!);

        notifyListeners();
      } else {
        throw Exception('로그인 실패');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _userNo = null;  // ✅ 로그아웃 시 초기화!
    _userId = null;

    await TokenStorageService().deleteToken();
    notifyListeners();
  }
}