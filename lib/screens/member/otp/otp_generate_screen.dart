/*
  날짜: 2025/12/29
  내용: OTP 생성 화면
  이름: 오서정
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tkbank/services/otp_code_service.dart';
import 'package:tkbank/services/otp_pin_storage_service.dart';
import 'package:tkbank/widgets/otp_pin_verify_sheet.dart';

const Color bnkPrimary = Color(0xFF6A1B9A);

enum OtpGenStep { intro, pin, active, expired }

class OtpGenerateScreen extends StatefulWidget {
  const OtpGenerateScreen({super.key});

  @override
  State<OtpGenerateScreen> createState() => _OtpGenerateScreenState();
}

class _OtpGenerateScreenState extends State<OtpGenerateScreen> {
  final _otpService = OtpCodeService();
  final _pinStore = OtpPinStorageService();

  Timer? _timer;
  String? _otp;
  int _remain = 0;

  OtpGenStep _step = OtpGenStep.intro;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    // ✅ 1) 이미 유효 OTP가 있으면 그대로 복구 (재진입 시 PIN 스킵)
    if (_otpService.hasValidOtp) {
      setState(() {
        _otp = _otpService.currentOtp;
        _remain = _otpService.remainSeconds;
        _step = OtpGenStep.active;
      });
      _startTicker();
      return;
    }

    // ✅ 2) OTP가 없으면: 처음 진입부터 PIN 단계로 전환 + PIN 입력창(바텀시트) 자동 오픈
    setState(() {
      _step = OtpGenStep.pin;
      _otp = null;
      _remain = 0;
    });

    // 첫 빌드 이후에 바텀시트 띄우기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _generateWithAuthIfNeeded();
    });
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      final r = _otpService.remainSeconds;
      setState(() => _remain = r);

      if (r <= 0) {
        t.cancel();
        _otpService.clear();
        setState(() {
          _otp = null;
          _step = OtpGenStep.expired;
        });
      }
    });
  }

  Future<void> _generateWithAuthIfNeeded() async {
    // PIN 등록 체크
    final hasPin = await _pinStore.hasOtpPin();
    if (!hasPin) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP 비밀번호가 등록되어 있지 않습니다.')),
      );
      return;
    }

    // ✅ 최근 인증이면 PIN 생략
    if (!_otpService.isRecentAuthed) {
      setState(() => _step = OtpGenStep.pin);

      final ok = await showOtpPinVerifySheet(context);
      if (!ok) {
        if (!mounted) return;
        // PIN 취소하면 다시 만료(대기) 상태로
        setState(() => _step = OtpGenStep.expired);
        return;
      }
      _otpService.markAuthed();
    }

    // ✅ OTP 생성
    final generated = _otpService.generate();
    setState(() {
      _otp = generated;
      _remain = _otpService.remainSeconds;
      _step = OtpGenStep.active;
    });
    _startTicker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatRemain(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _step == OtpGenStep.active;
    final isExpired = _step == OtpGenStep.expired;
    final isPinStep = _step == OtpGenStep.pin;

    final primaryBtnStyle = ElevatedButton.styleFrom(
      backgroundColor: bnkPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

    final secondaryBtnStyle = OutlinedButton.styleFrom(
      foregroundColor: bnkPrimary,
      minimumSize: const Size.fromHeight(52),
      side: BorderSide(color: bnkPrimary.withOpacity(0.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

    Widget infoCard({required Widget child}) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP 인증번호 생성'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F7FA),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: ElevatedButton(
            style: primaryBtnStyle,
            onPressed: () => Navigator.pop(context, isActive),
            child: Text(isActive ? '확인' : '닫기'),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isActive
                  ? '인증번호를 뱅킹거래 화면에\n입력해주세요.'
                  : (isPinStep
                  ? '안전한 금융거래를 위해\n디지털OTP 인증번호 생성을\n시작합니다.'
                  : '인증번호가 없습니다.\n생성해 주세요.'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: isExpired ? Colors.grey.shade900 : Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 14),

            infoCard(
              child: Column(
                children: [
                  // ✅ PIN 단계면 안내만 보여주고, OTP 박스 자체를 숨김
                  if (!isPinStep) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          isActive ? (_otp ?? '') : '----  ----',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                            color: isActive ? Colors.black : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ✅ 아래 상태문구도 PIN 단계면 안내형으로
                  Text(
                    isActive
                        ? '유효시간 ${_formatRemain(_remain)}'
                        : (isPinStep
                        ? '디지털OTP 비밀번호를 입력하면 인증번호가 생성됩니다.\n• 인증번호는 2분간 유효합니다.\n• 타인에게 인증번호를 공유하지 마세요.'
                        : '생성 버튼을 눌러주세요.'),
                    style: TextStyle(
                      color: isActive ? Colors.red : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  OutlinedButton.icon(
                    style: secondaryBtnStyle,
                    onPressed: isPinStep ? null : _generateWithAuthIfNeeded, // ✅ PIN 입력 중엔 비활성 추천
                    icon: const Icon(Icons.refresh),
                    label: Text(isActive ? '다시 생성' : '생성하기'),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }



}
