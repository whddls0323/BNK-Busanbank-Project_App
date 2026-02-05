import 'package:flutter/material.dart';
import 'package:tkbank/screens/cs/email/email_counsel_detail_screen.dart';

import '../../../models/email_counsel_item.dart';
import '../../../services/cs/email_counsel_api_service.dart';
import 'email_counsel_form_screen.dart';

class EmailCounselListScreen extends StatefulWidget {
  const EmailCounselListScreen({super.key});

  @override
  State<EmailCounselListScreen> createState() => _EmailCounselListScreenState();
}

class _EmailCounselListScreenState extends State<EmailCounselListScreen> {
  final _api = EmailCounselApiService();

  bool _loading = true;
  List<EmailCounselItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.fetchMyList();
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("목록을 불러오지 못했습니다: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case "REGISTERED":
        return "접수";
      case "ANSWERED":
        return "답변완료";
      default:
        return s;
    }
  }

  String _fmtDate(String? s) {
    if (s == null || s.isEmpty) return "";
    try {
      final dt = DateTime.parse(s).toLocal();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return "$m.$d $hh:$mm";
    } catch (_) {
      return s; // 파싱 실패 시 원문
    }
  }

  Future<void> _openForm() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EmailCounselFormScreen()),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(int id) async {
    // 상세에서 변경이 없다면 그냥 null 반환하도록 두고,
    // 변경이 있을 경우 true 반환하면 목록 새로고침 가능
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EmailCounselDetailScreen(ecounselId: id)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("이메일 문의 내역"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _items.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text("문의 내역이 없습니다.")),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final it = _items[i];

            final catLabel =
            (it.csCategoryName != null && it.csCategoryName!.isNotEmpty)
                ? it.csCategoryName!
                : it.csCategory;

            final created = _fmtDate(it.createdAt);

            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  it.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "$catLabel · ${_statusLabel(it.status)}"
                      "${created.isNotEmpty ? " · $created" : ""}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openDetail(it.ecounselId),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        tooltip: "문의하기",
        child: const Icon(Icons.edit),
      ),
    );
  }
}
