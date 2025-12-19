import 'package:flutter/material.dart';
import 'package:tkbank/screens/cs/chat/chat_history_screen.dart';
import 'package:tkbank/screens/cs/email/email_counsel_list_screen.dart';

class CounselHistoryHubScreen extends StatelessWidget {
  const CounselHistoryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('지난 상담내역'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '1:1 문의'),
              Tab(text: '채팅 상담'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EmailCounselListScreen(),
            ChatHistoryScreen(), // ✅ api 제거
          ],
        ),
      ),
    );
  }
}

