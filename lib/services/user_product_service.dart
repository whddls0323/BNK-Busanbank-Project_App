// 2025/12/18 - 나의 금융상품 조회/해지 서비스 - 작성자: 진원
// 2025/12/18 - JWT 토큰 인증 추가 - 작성자: 진원
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_product.dart';
import 'token_storage_service.dart';

class UserProductService {
  final String baseUrl = "http://192.168.219.105:8080/busanbank";
  final TokenStorageService _tokenStorage = TokenStorageService();

  // 사용자 가입 상품 목록 조회
  // userNo는 사용자 번호 (int)
  Future<List<UserProduct>> getUserProducts(int userNo) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/user-products/user/$userNo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        List<dynamic> data = result['data'];
        return data.map((json) => UserProduct.fromJson(json)).toList();
      } else {
        throw Exception('상품 조회 실패');
      }
    } else {
      throw Exception('상품 조회 실패');
    }
  }

  // 활성 상품만 조회
  Future<List<UserProduct>> getActiveProducts(int userNo) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('$baseUrl/api/user-products/user/$userNo/active'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        List<dynamic> data = result['data'];
        return data.map((json) => UserProduct.fromJson(json)).toList();
      } else {
        throw Exception('상품 조회 실패');
      }
    } else {
      throw Exception('상품 조회 실패');
    }
  }

  // 상품 해지 (2025/12/30 - 해지금 입금 계좌 추가 - 작성자: 진원)
  Future<Map<String, dynamic>> terminateProduct({
    required int userNo,
    required int productNo,
    required String startDate,
    required String depositAccountNo, // 입금 계좌번호 추가
  }) async {
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/api/user-products/$userNo/$productNo/terminate?startDate=$startDate&depositAccountNo=$depositAccountNo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        return {
          'success': true,
          'refundAmount': result['refundAmount'],
          'message': result['message'],
        };
      } else {
        throw Exception(result['message'] ?? '상품 해지 실패');
      }
    } else {
      throw Exception('상품 해지 실패');
    }
  }
}
