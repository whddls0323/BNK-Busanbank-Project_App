import 'package:flutter/material.dart';
import 'package:tkbank/services/otp_pin_storage_service.dart';
import 'package:tkbank/widgets/otp_box_row.dart';
import 'package:tkbank/widgets/pin_dots.dart';
import 'package:tkbank/widgets/pin_keypad_panel.dart';

Future<bool> showOtpPinVerifySheet(BuildContext context) async {
  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (ctx) => SizedBox(
      width: MediaQuery.of(ctx).size.width,
      child: const _OtpPinVerifySheet(),
    ),
  ) ?? false;
}

class _OtpPinVerifySheet extends StatefulWidget {
  const _OtpPinVerifySheet();

  @override
  State<_OtpPinVerifySheet> createState() => _OtpPinVerifySheetState();
}

class _OtpPinVerifySheetState extends State<_OtpPinVerifySheet> {
  final _service = OtpPinStorageService();

  String _pin = '';
  String? _error;
  bool _loading = false;

  void _onNumber(String v) async {
    if (_loading) return;
    if (_pin.length >= 6) return;

    setState(() {
      _pin += v;
      _error = null;
    });

    if (_pin.length == 6) {
      setState(() => _loading = true);
      final ok = await _service.verifyOtpPin(_pin);
      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = '비밀번호가 일치하지 않습니다.';
          _pin = '';
          _loading = false;
        });
      }
    }
  }

  void _onDelete() {
    if (_loading) return;
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
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
              '디지털OTP PIN번호를 입력해 주세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OtpBoxRow(
                value: _pin,
                obscure: true, // ⭐ 점으로 표시
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
}
