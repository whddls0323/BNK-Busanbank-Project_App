import 'package:flutter/material.dart';

import '../../../models/code_detail.dart';
import '../../../models/email_counsel_create_request.dart';
import '../../../models/email_counsel_form_data.dart';
import '../../../services/cs/email_counsel_api_service.dart';

class EmailCounselFormScreen extends StatefulWidget {
  const EmailCounselFormScreen({super.key});

  @override
  State<EmailCounselFormScreen> createState() => _EmailCounselFormScreenState();
}

class _EmailCounselFormScreenState extends State<EmailCounselFormScreen> {
  final _api = EmailCounselApiService();

  EmailCounselFormData? _form;
  bool _loading = true;
  bool _submitting = false;

  CodeDetail? _selectedCategory;

  final _emailCtrl = TextEditingController();   // ✅ 추가: 회신 이메일(기본값 자동)
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() => _loading = true);
    try {
      final form = await _api.fetchForm();
      if (!mounted) return;

      setState(() {
        _form = form;
        _selectedCategory = form.categories.isNotEmpty ? form.categories.first : null;

        // ✅ 서버에서 내려준 회원 이메일을 기본값으로 세팅 (사용자는 수정 가능)
        _emailCtrl.text = form.email ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("폼 정보를 불러오지 못했습니다: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_form == null) return;

    final cat = _selectedCategory?.code ?? '';
    final email = _emailCtrl.text.trim();
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (cat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("문의 분야를 선택해 주세요.")),
      );
      return;
    }
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("회신 이메일을 입력해 주세요.")),
      );
      return;
    }
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("제목과 내용을 입력해 주세요.")),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _api.submit(
        EmailCounselCreateRequest(
          csCategory: cat,
          title: title,
          content: content,
          contactEmail: email, // ✅ 핵심: 서버로 전송
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("접수되었습니다.")),
      );
      Navigator.of(context).pop(true); // ✅ 목록 새로고침 트리거 용도
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("등록 실패: $e")),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = _form;

    return Scaffold(
      appBar: AppBar(title: const Text("1:1 문의")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (form == null)
          ? Center(
        child: ElevatedButton(
          onPressed: _loadForm,
          child: const Text("다시 시도"),
        ),
      )
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ 자동 채움 영역 (읽기 전용)
              _ReadOnlyRow(label: "이름", value: form.userName ?? "-"),
              const SizedBox(height: 8),
              _ReadOnlyRow(label: "휴대폰", value: form.hp ?? "-"),
              const SizedBox(height: 16),

              // ✅ 회신 이메일 (수정 가능 + 기본값 자동)
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "회신 이메일",
                  hintText: "example@email.com",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ 문의분야 드롭다운
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: "문의 분야",
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CodeDetail>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: form.categories
                        .map(
                          (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.codeName ?? c.code ?? ''),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ 제목
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: "제목",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ 내용
              TextField(
                controller: _contentCtrl,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: "내용",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ 제출 버튼
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text("제출"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: false,
      ),
      child: Text(value),
    );
  }
}
