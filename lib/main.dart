import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 2025/12/21 - 웹 플랫폼 체크용 - 작성자: 진원
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/providers/seed_event_provider.dart';
import 'package:tkbank/services/FcmService.dart';
import 'package:tkbank/services/seed_event_service.dart';
import 'package:tkbank/screens/splash_screen.dart';
import 'navigator_key.dart';
import 'package:tkbank/screens/product/join/join_step4_screen.dart';
import 'package:tkbank/screens/product/join/join_step3_screen.dart';
import 'package:tkbank/screens/product/join/join_step2_screen.dart';
import 'package:tkbank/models/product_join_request.dart';
import 'package:tkbank/theme/app_colors.dart'; // 25.12.30 천수빈

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  // 2025/12/21 - 웹에서는 Firebase 초기화 건너뛰기 - 작성자: 진원
  if (!kIsWeb) {
    await FcmService.init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        // 2025/12/23 -  금열매 이벤트 Provider 추가 - 작성자: 오서정
        ChangeNotifierProvider(create: (_) => SeedEventProvider(SeedEventService()),),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String baseUrl = 'http://10.0.2.2:8080/busanbank/api';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TK 딸깍은행',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.white, // [25.12.29] 전체 배경 연보라색 제거 - 수빈

        // 👇 전체 앱에 폰트 적용!
        fontFamily: 'Pretendard',
      ),
      navigatorKey: navigatorKey, // 푸시 알림 페이지 이동을 위한 키 설정 - 작성자: 윤종인
      onGenerateRoute: (settings) {
        if (settings.name == '/product/join/step2') {
          final request = settings.arguments as ProductJoinRequest;
          return MaterialPageRoute(
            builder: (context) => JoinStep2Screen(
              baseUrl: baseUrl,
              request: request,
            ),
          );
        }

        if (settings.name == '/product/join/step3') {
          final request = settings.arguments as ProductJoinRequest;
          return MaterialPageRoute(
            builder: (context) => JoinStep3Screen(request: request),
          );
        }

        if (settings.name == '/product/join/step4') {
          final request = settings.arguments as ProductJoinRequest;
          return MaterialPageRoute(
            builder: (context) => JoinStep4Screen(
              baseUrl: baseUrl,
              request: request,
            ),
          );
        }

        return null;
      },
      home: const SplashScreen(),
    );
  }
}