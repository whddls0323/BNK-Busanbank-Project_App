import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tkbank/screens/member/otp_issue_intro_screen.dart';
const Color bnkPrimary = Color(0xFF6A1B9A);   // 메인 보라
const Color bnkPrimarySoft = Color(0xFFF3E5F5); // 연보라 배경
const Color bnkGrayText = Color(0xFF6B7280);
const Color bnkCardBg = Colors.white;

class OtpManageScreen extends StatelessWidget {
  const OtpManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디지털OTP'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _menuItem(
            context,
            title: '디지털OTP(재)발급',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OtpIssueIntroScreen(),
                ),
              );
            },
          ),
          _menuItem(
            context,
            title: '디지털OTP 해지',
            onTap: () {
              // TODO: OTP 해지 플로우
            },
          ),
          _menuItem(
            context,
            title: 'PIN번호 재등록',
            onTap: () {
              // TODO: OTP PIN 변경
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
