// 2025/12/28 - 감정 분석 게임 서비스 - 작성자: 진원

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import 'token_storage_service.dart';

class EmotionGameService {
  final TokenStorageService _tokenStorage = TokenStorageService();

  /// 감정 분석 및 게임 보상 처리
  Future<Map<String, dynamic>> analyzeEmotion({
    required String gameType,
    required int userNo,
    required File imageFile,
    String? targetEmotion,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/flutter/emotion/analyze';

      // JWT 토큰 가져오기
      final token = await _tokenStorage.readToken();

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // 헤더 추가
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 이미지 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // 필드 추가
      request.fields['gameType'] = gameType;
      request.fields['userNo'] = userNo.toString();
      if (targetEmotion != null) {
        request.fields['targetEmotion'] = targetEmotion;
      }

      print('[EmotionGameService] 요청 시작 - gameType: $gameType');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[EmotionGameService] 응답 코드: ${response.statusCode}');
      print('[EmotionGameService] 응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        throw Exception(error['message'] ?? '감정 분석 실패');
      }
    } catch (e) {
      print('[EmotionGameService] 에러 발생: $e');
      throw Exception('감정 분석 실패: $e');
    }
  }

  /// 게임 타입별 설명 반환
  String getGameDescription(String gameType) {
    switch (gameType) {
      case 'SMILE_CHALLENGE':
        return '활짝 웃으면 50P 획득!\n눈을 깜빡이면 자동 촬영됩니다.';
      case 'EMOTION_EXPRESS':
        return '제시된 감정을 표현하면 100P 획득!\n감정을 확실하게 표현해주세요.';
      case 'HAPPINESS_METER':
        return '행복 지수를 측정합니다!\n점수(10~100점)만큼 포인트를 획득합니다.\n\n※ 매우 행복: 100P / 행복: 80P\n   보통: 50P / 약간 행복: 30P / 미소: 10P';
      default:
        return '';
    }
  }

  /// 게임 타입별 아이콘 반환
  String getGameIcon(String gameType) {
    switch (gameType) {
      case 'SMILE_CHALLENGE':
        return '😊';
      case 'EMOTION_EXPRESS':
        return '🎭';
      case 'HAPPINESS_METER':
        return '📊';
      default:
        return '🎮';
    }
  }

  /// 감정별 아이콘 및 이름 반환
  Map<String, String> getEmotionInfo(String emotion) {
    switch (emotion) {
      case 'joy':
        return {'icon': '😊', 'name': '기쁨'};
      case 'sorrow':
        return {'icon': '😢', 'name': '슬픔'};
      case 'anger':
        return {'icon': '😠', 'name': '화남'};
      case 'surprise':
        return {'icon': '😲', 'name': '놀람'};
      default:
        return {'icon': '🎭', 'name': '감정'};
    }
  }

  /// 게임 타입별 이름 반환
  String getGameName(String gameType) {
    switch (gameType) {
      case 'SMILE_CHALLENGE':
        return '웃음 챌린지';
      case 'EMOTION_EXPRESS':
        return '감정 표현 게임';
      case 'HAPPINESS_METER':
        return '행복 지수 측정';
      default:
        return '감정 게임';
    }
  }
}
