import 'dart:io';

class ApiConfig {
  static const host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '192.168.219.105', // 에뮬 기본
  );

  static String get baseUrl => 'http://$host:8080/busanbank';
  static String get wsBase  => 'ws://$host:8080/busanbank';
}

