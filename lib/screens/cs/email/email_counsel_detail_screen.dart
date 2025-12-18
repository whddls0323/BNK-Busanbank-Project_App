import 'package:flutter/material.dart';

import '../../../models/email_counsel_item.dart';
import '../../../services/cs/email_counsel_api_service.dart';

class EmailCounselDetailScreen extends StatefulWidget {
  final int ecounselId;
  const EmailCounselDetailScreen({super.key, required this.ecounselId});

  @override
  State<EmailCounselDetailScreen> createState() => _EmailCounselDetailScreenState();
}

class _EmailCounselDetailScreenState extends State<EmailCounselDetailScreen> {
  final _api = EmailCounselApiService();
  bool _loading = true;
  EmailCounselItem? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final item = await _api.fetchDetail(widget.ecounselId);
      setState(() => _item = item);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("상세를 불러오지 못했습니다: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("문의 상세")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_item == null)
          ? Center(
        child: ElevatedButton(
          onPressed: _load,
          child: const Text("다시 시도"),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item!.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("상태: ${_item!.status}"),
                  if (_item!.createdAt != null) Text("등록일: ${_item!.createdAt}"),
                  const Divider(height: 24),
                  const Text("문의 내용", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_item!.content),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("답변", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text((_item!.response == null || _item!.response!.isEmpty)
                      ? "아직 답변이 등록되지 않았습니다."
                      : _item!.response!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
