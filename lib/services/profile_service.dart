// 2025/12/23 - 사용자 프로필 관리 서비스 - 작성자: 진원

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'token_storage_service.dart';

class ProfileService {
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// 닉네임 중복 확인
  Future<Map<String, dynamic>> checkNickname(String nickname) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flutter/profile/check-nickname?nickname=$nickname';

      final response = await http.get(
        Uri.parse(url),
      );

      print('[ProfileService] 닉네임 중복 확인 - 응답 코드: ${response.statusCode}');
      print('[ProfileService] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '닉네임 중복 확인 실패');
      }
    } catch (e) {
      print('[ProfileService] 에러 발생: $e');
      throw Exception('닉네임 중복 확인 실패: $e');
    }
  }

  /// 닉네임 업데이트
  Future<Map<String, dynamic>> updateNickname({
    required String userNo,
    required String nickname,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flutter/profile/update-nickname';
      final requestBody = {
        'userNo': userNo,
        'nickname': nickname,
      };

      // JWT 토큰 가져오기
      final token = await _tokenStorage.readToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('[ProfileService] 닉네임 업데이트 - URL: $url');
      print('[ProfileService] 요청 데이터: $requestBody');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );

      print('[ProfileService] 응답 코드: ${response.statusCode}');
      print('[ProfileService] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '닉네임 변경 실패');
      }
    } catch (e) {
      print('[ProfileService] 에러 발생: $e');
      throw Exception('닉네임 변경 실패: $e');
    }
  }

  /// 아바타 이미지 업로드
  Future<Map<String, dynamic>> uploadAvatar({
    required String userNo,
    required File avatarFile,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flutter/profile/upload-avatar';

      // JWT 토큰 가져오기
      final token = await _tokenStorage.readToken();

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // 헤더 추가
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 파일 추가 (2025-12-28 수정 - contentType 명시 - 작성자: 진원)
      String fileName = avatarFile.path.split('/').last;
      String extension = fileName.split('.').last.toLowerCase();

      // 확장자에 따른 MIME 타입 결정
      MediaType contentType;
      if (extension == 'jpg' || extension == 'jpeg') {
        contentType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        contentType = MediaType('image', 'png');
      } else if (extension == 'gif') {
        contentType = MediaType('image', 'gif');
      } else {
        contentType = MediaType('image', 'jpeg'); // 기본값
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          avatarFile.path,
          contentType: contentType,
        ),
      );

      // userNo 추가
      request.fields['userNo'] = userNo;

      print('[ProfileService] 아바타 업로드 - URL: $url');
      print('[ProfileService] userNo: $userNo');
      print('[ProfileService] 파일 경로: ${avatarFile.path}');
      print('[ProfileService] 파일명: $fileName');
      print('[ProfileService] 확장자: $extension');
      print('[ProfileService] ContentType: ${contentType.mimeType}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[ProfileService] 응답 코드: ${response.statusCode}');
      print('[ProfileService] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '아바타 업로드 실패');
      }
    } catch (e) {
      print('[ProfileService] 에러 발생: $e');
      throw Exception('아바타 업로드 실패: $e');
    }
  }
}
