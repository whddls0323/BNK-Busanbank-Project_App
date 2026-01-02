import 'package:flutter/material.dart';
import 'package:tkbank/services/otp_code_service.dart';
import 'package:tkbank/widgets/otp_box_row.dart';
import 'package:tkbank/widgets/pin_dots.dart';
import 'package:tkbank/widgets/pin_keypad_panel.dart';

Future<bool> showOtpInputSheet(BuildContext context) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (ctx) => SizedBox(
      width: MediaQuery.of(ctx).size.width,
      child: const _OtpInputSheet(),
    ),
  ) ?? false;
}

class _OtpInputSheet extends StatefulWidget {
  const _OtpInputSheet();

  @override
  State<_OtpInputSheet> createState() => _OtpInputSheetState();
}

class _OtpInputSheetState extends State<_OtpInputSheet> {
  final _otpService = OtpCodeService();

  String _otp = '';
  String? _error;

  void _onNumber(String v) {
    if (_otp.length >= 6) return;

    setState(() {
      _otp += v;
      _error = null;
    });

    if (_otp.length == 6) {
      final ok = _otpService.verify(_otp);
      if (!ok) {
        setState(() {
          _error = 'OTP가 올바르지 않습니다.';
          _otp = '';
        });
        return;
      }

      // 성공 시 재사용 방지
      _otpService.clear();
      Navigator.pop(context, true);
    }
  }

  void _onDelete() {
    if (_otp.isEmpty) return;
    setState(() => _otp = _otp.substring(0, _otp.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            const Text(
              'OTP 인증번호 입력',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '인증센터에서 생성한 6자리 OTP를 입력하세요.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OtpBoxRow(
                value: _otp,
                obscure: false, // 숫자 그대로
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 14),

            PinKeypadPanel(
              onNumber: _onNumber,
              onDelete: _onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBoxes(String otp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final totalGap = gap * 5;
        final boxW = (constraints.maxWidth - totalGap) / 6;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final c = i < otp.length ? otp[i] : '';
            return Container(
              width: boxW.clamp(38.0, 56.0), // 너무 작아지지/커지지 않게
              height: 54,
              margin: EdgeInsets.only(right: i == 5 ? 0 : gap),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                c,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
          }),
        );
      },
    );
  }

}
