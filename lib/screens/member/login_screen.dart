/*
  날짜 : 2025/12/15
  내용 : 로그인 페이지 추가
  작성자 : 오서정

  날짜 : 2025/12/16
  내용 : AuthProvider 병합  - 진원, 수진
*/
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/screens/member/find_id_screen.dart';
import 'package:tkbank/screens/member/find_pw_screen.dart';
import 'package:tkbank/screens/member/terms_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  static const Color purple900 = Color(0xFF662382);
  static const Color purple500 = Color(0xFFBD9FCD);

  void _procLogin() async {
    final userId = _idController.text.trim();
    final userPw = _pwController.text.trim();

    if (userId.isEmpty || userPw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디와 비밀번호를 입력하세요')),
      );
      return;
    }

    try {
      // AuthProvider에서 직접 API 호출
      await context.read<AuthProvider>().login(userId, userPw);

      print('[DEBUG] AuthProvider.login() 호출 완료!');
      print('[DEBUG] isLoggedIn: ${context.read<AuthProvider>().isLoggedIn}');
      print('[DEBUG] userNo: ${context.read<AuthProvider>().userNo}');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (err) {
      print('[ERROR] 로그인 실패: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $err')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: purple900),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple900, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple500),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2F8),
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
        backgroundColor: purple900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                // 로고 or 타이틀
                const Text(
                  '딸깍 은행',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: purple900,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                // 아이디
                TextField(
                  controller: _idController,
                  decoration: _inputDecoration('아이디'),
                ),

                const SizedBox(height: 16),

                // 비밀번호
                TextField(
                  controller: _pwController,
                  obscureText: true,
                  decoration: _inputDecoration('비밀번호'),
                ),

                const SizedBox(height: 24),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _procLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 하단 메뉴 (아이디 찾기 | 회원가입 | 비밀번호 찾기)
                // 오버플로우 수정 - 수진
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(  // ✅ 추가!
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FindIdScreen()),
                          );
                        },
                        child: const Text(
                          '아이디 찾기',
                          style: TextStyle(
                            color: purple900,
                            fontSize: 12,  // ✅ 14 → 12
                          ),
                        ),
                      ),
                    ),

                    Expanded(  // ✅ 추가!
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '회원가입',
                          style: TextStyle(
                            color: purple900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,  // ✅ 14 → 12
                          ),
                        ),
                      ),
                    ),

                    Expanded(  // ✅ 추가!
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FindPwScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          '비밀번호 찾기',
                          style: TextStyle(
                            color: purple900,
                            fontSize: 12,  // ✅ 14 → 12
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }
}