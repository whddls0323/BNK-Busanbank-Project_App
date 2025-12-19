import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tkbank/screens/member/login_screen.dart';

class FindPwResultScreen extends StatelessWidget {
  const FindPwResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
          width: 150,
          height: 150,
          child: Lottie.asset('assets/lottie/TickSuccess.json'),
        ),
            const SizedBox(height: 16),
            const Text(
              '비밀번호 변경 완료',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('로그인하러 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
