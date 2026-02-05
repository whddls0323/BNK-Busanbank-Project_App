// 2025/12/18 - 쿠폰 조회/등록 서비스 - 작성자: 진원
// 2025/12/18 - JWT 토큰 인증 추가 - 작성자: 진원
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coupon.dart';
import 'token_storage_service.dart';

class CouponService {
  final String baseUrl = "http://192.168.219.105:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  // 사용자 쿠폰 목록 조회
  Future<List<Coupon>> getUserCoupons(int userNo) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/flutter/coupons/user/$userNo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Coupon.fromJson(json)).toList();
    } else {
      throw Exception('쿠폰 조회 실패');
    }
  }

  // 쿠폰 등록
  // 2026/01/06 - 백엔드 API와 일치하도록 쿼리 파라미터로 전송 - 작성자: 진원
  Future<Map<String, dynamic>> registerCoupon(String couponCode) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded', // 폼 데이터 형식
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // 쿼리 파라미터로 쿠폰 코드 전송 (백엔드 @RequestParam과 일치)
    final response = await http.post(
      Uri.parse('$baseUrl/my/coupon/register?couponCode=$couponCode'),
      headers: headers,
    );

    print('[DEBUG] 쿠폰 등록 요청 - 쿠폰 코드: $couponCode'); // 2026/01/06 - 디버그 로그 - 작성자: 진원
    print('[DEBUG] 쿠폰 등록 응답 코드: ${response.statusCode}'); // 2026/01/06 - 디버그 로그 - 작성자: 진원
    print('[DEBUG] 쿠폰 등록 응답 내용: ${response.body}'); // 2026/01/06 - 디버그 로그 - 작성자: 진원

    // 2026/01/06 - 빈 응답 처리 추가 - 작성자: 진원
    if (response.body.isEmpty) {
      if (response.statusCode == 200) {
        return {'success': true, 'message': '쿠폰이 등록되었습니다'};
      } else {
        throw Exception('쿠폰 등록 실패: 서버 응답이 없습니다 (상태 코드: ${response.statusCode})');
      }
    }

    // 2026/01/06 - JSON 파싱 오류 처리 개선 - 작성자: 진원
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? '쿠폰 등록 실패');
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('서버 응답 형식 오류: ${response.body}');
      }
      rethrow;
    }
  }
}
