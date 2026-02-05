/*
  날짜: 2025/12/29
  내용: otp 인증번호 생성 서비스
  작성자: 오서정
*/
import 'dart:math';

class OtpCodeService {
  static final OtpCodeService _instance = OtpCodeService._internal();
  factory OtpCodeService() => _instance;
  OtpCodeService._internal();

  String? _otp;
  DateTime? _expiresAt;

  DateTime? _lastAuthAt; // ✅ 마지막 PIN 인증 시각

  // 유효시간(초)
  final int ttlSeconds = 120;

  /// OTP 존재 + 만료 여부
  bool get hasValidOtp {
    if (_otp == null || _expiresAt == null) return false;
    return DateTime.now().isBefore(_expiresAt!);
  }

  /// 남은 시간
  int get remainSeconds {
    if (!hasValidOtp) return 0;
    final diff = _expiresAt!.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  /// 현재 OTP
  String? get currentOtp => hasValidOtp ? _otp : null;

  /// 🔐 PIN 인증 직후 호출
  void markAuthed() {
    _lastAuthAt = DateTime.now();
  }

  /// 🔐 PIN 재입력 생략 가능 여부
  /// (은행앱 보통 1~3분)
  bool get isRecentAuthed {
    if (_lastAuthAt == null) return false;
    return DateTime.now()
        .difference(_lastAuthAt!)
        .inMinutes < 2;
  }

  /// OTP 생성 (6자리)
  String generate() {
    final rnd = Random.secure();
    _otp = (100000 + rnd.nextInt(900000)).toString();
    _expiresAt = DateTime.now().add(Duration(seconds: ttlSeconds));
    return _otp!;
  }

  /// OTP 검증
  bool verify(String input) {
    if (!hasValidOtp) return false;
    return input == _otp;
  }

  /// OTP 초기화 (만료 or 성공 후)
  void clear() {
    _otp = null;
    _expiresAt = null;
    // ⚠️ PIN 인증 시각은 유지 (재생성 정책에 사용)
  }
}
