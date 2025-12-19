import 'package:flutter/material.dart';

class SecurityCenterScreen extends StatelessWidget {
  const SecurityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인증센터'),
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _SecurityItem(
              icon: Icons.password,
              title: '간편 비밀번호',
              subtitle: '등록 / 변경 / 해제',
              onTap: () {
                // TODO: 간편 비밀번호 관리 화면
              },
            ),

            const SizedBox(height: 16),

            _SecurityItem(
              icon: Icons.fingerprint,
              title: '생체 인증',
              subtitle: '지문 또는 Face ID 설정',
              onTap: () {
                // TODO: 생체 인증 설정
              },
            ),

            const SizedBox(height: 16),

            _SecurityItem(
              icon: Icons.logout,
              title: '로그아웃',
              subtitle: '로그인 세션 종료',
              onTap: () {
                // TODO: 로그아웃 처리
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecurityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.grey.shade800),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
