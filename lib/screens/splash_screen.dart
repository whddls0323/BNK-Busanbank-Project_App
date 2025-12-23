// 생성자 : 천수빈
// 생성일 : 25/12/22
// 내용 : Splash Screen 영상 실행

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../main.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Lottie.asset(
            'assets/lottie/TKlogo_intro.json',
            repeat: false,
            fit: BoxFit.contain,
            onLoaded: (composition) {
              Future.delayed(composition.duration, () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(
                      baseUrl: MyApp.baseUrl,
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }
}