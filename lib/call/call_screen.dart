import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tkbank/config/api_config.dart';
import 'voice_call_api.dart';
import 'voice_call_controller.dart';
import 'voice_websocket_service.dart';
import 'agora_call_screen.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final VoiceCallController controller;

  bool _navigatedToAgora = false; // ✅ Agora 중복 이동 방지
  bool _showDebug = false;
  String _debugLog = '';

  @override
  void initState() {
    super.initState();

    controller = VoiceCallController(
      api: VoiceCallApi(baseUrl: ApiConfig.baseUrl),
      ws: VoiceWebSocketService(),
    )
      ..addListener(() => setState(() {}))
      ..onAccepted = _moveToAgora
      ..onEnded = _onEndedByServer;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // =========================
  // Debug util (화면에는 숨김)
  // =========================
  void _d(String s) {
    if (!mounted) return;
    setState(() => _debugLog = '$_debugLog\n$s');
  }

  String _newSessionId() {
    // ✅ TEST_SESSION_* 대신 실제 서비스 느낌
    // 예: VOICE_APP_20260106_141522_123456
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final r = Random().nextInt(900000) + 100000;
    return 'VOICE_APP_${stamp}_$r';
  }

  // =========================
  // Agora 이동 (1회만)
  // =========================
  Future<void> _moveToAgora() async {
    if (_navigatedToAgora) return;
    _navigatedToAgora = true;

    final sid = controller.sessionId;
    final channel = controller.agoraChannel;

    _d('[VOICE] ACCEPTED → Agora 이동 (sid=$sid, channel=$channel)');

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgoraCallScreen(
          voiceSessionId: sid,
          agoraChannel: channel,
        ),
      ),
    );

    // Agora 화면 종료 후 복귀
    _d('[UI] back from Agora');
    _navigatedToAgora = false;
  }

  // =========================
  // 서버에서 VOICE_ENDED 수신
  // =========================
  void _onEndedByServer() {
    _d('[VOICE] 서버에서 종료 이벤트 수신');
    _navigatedToAgora = false;
  }

  // =========================
  // UI helpers
  // =========================
  String _titleFor(UiVoiceCallState state) {
    switch (state) {
      case UiVoiceCallState.idle:
        return '전화 상담';
      case UiVoiceCallState.requesting:
        return '전화 연결 요청 중';
      case UiVoiceCallState.waiting:
        return '상담사 연결 대기';
      case UiVoiceCallState.accepted:
        return '연결됨';
      case UiVoiceCallState.ended:
        return '통화 종료';
      case UiVoiceCallState.error:
        return '오류';
    }
  }

  String _subtitleFor(UiVoiceCallState state) {
    switch (state) {
      case UiVoiceCallState.idle:
        return '버튼을 눌러 상담을 요청해 주세요.';
      case UiVoiceCallState.requesting:
        return '요청을 전송하고 있습니다.';
      case UiVoiceCallState.waiting:
        return '상담사 배정 후 자동으로 통화 화면으로 이동합니다.';
      case UiVoiceCallState.accepted:
        return '통화 화면으로 이동 중입니다.';
      case UiVoiceCallState.ended:
        return '통화가 종료되었습니다.';
      case UiVoiceCallState.error:
        return controller.errorMsg.isEmpty ? '오류가 발생했습니다.' : controller.errorMsg;
    }
  }

  IconData _iconFor(UiVoiceCallState state) {
    switch (state) {
      case UiVoiceCallState.idle:
        return Icons.phone_in_talk_outlined;
      case UiVoiceCallState.requesting:
        return Icons.sync;
      case UiVoiceCallState.waiting:
        return Icons.support_agent;
      case UiVoiceCallState.accepted:
        return Icons.check_circle_outline;
      case UiVoiceCallState.ended:
        return Icons.call_end;
      case UiVoiceCallState.error:
        return Icons.error_outline;
    }
  }

  bool get _canRequest => controller.state == UiVoiceCallState.idle;
  bool get _canEnd =>
      controller.sessionId.isNotEmpty &&
          controller.state != UiVoiceCallState.accepted &&
          controller.state != UiVoiceCallState.idle;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('전화 상담'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            children: [
              _HeaderCard(
                icon: _iconFor(state),
                title: _titleFor(state),
                subtitle: _subtitleFor(state),
                sessionId: controller.sessionId,
                wsOn: controller.ws.isConnected,
              ),
              const SizedBox(height: 16),

              // 큰 액션 버튼 영역
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BigRoundButton(
                      label: '전화 요청',
                      icon: Icons.phone,
                      enabled: _canRequest,
                      onTap: () async {
                        final sid = _newSessionId();
                        _d('[REQ] enqueue $sid');

                        await controller.requestCall(newSessionId: sid);
                        _d('[OK] WAITING...');
                        controller.attachWs(baseWs: ApiConfig.wsBase);
                      },
                    ),
                    const SizedBox(height: 14),
                    _BigRoundButton(
                      label: '종료',
                      icon: Icons.call_end,
                      enabled: _canEnd,
                      isDestructive: true,
                      onTap: () async {
                        _d('[END] ${controller.sessionId}');
                        await controller.endCall();
                        _d('[OK] end requested');
                      },
                    ),
                    const SizedBox(height: 22),

                    // 디버그 토글(릴리즈에서는 숨김)
                    if (kDebugMode) ...[
                      GestureDetector(
                        onLongPress: () => setState(() => _showDebug = !_showDebug),
                        child: Opacity(
                          opacity: 0.7,
                          child: Text(
                            '길게 눌러 디버그 표시',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (kDebugMode && _showDebug) ...[
                const SizedBox(height: 8),
                _DebugPanel(text: _debugLog),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// UI Components
// =========================
class _HeaderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String sessionId;
  final bool wsOn;

  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.sessionId,
    required this.wsOn,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(icon, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, height: 1.35),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Pill(
                      text: 'WS ${wsOn ? "ON" : "OFF"}',
                      ok: wsOn,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sessionId.isEmpty ? 'sessionId: -' : 'sessionId: $sessionId',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final bool ok;
  const _Pill({required this.text, required this.ok});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ok ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ok ? cs.onPrimaryContainer : cs.onErrorContainer,
        ),
      ),
    );
  }
}

class _BigRoundButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback onTap;

  const _BigRoundButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = isDestructive ? cs.error : cs.primary;
    final fg = isDestructive ? cs.onError : cs.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: cs.surfaceContainerHighest,
          disabledForegroundColor: cs.onSurfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  final String text;
  const _DebugPanel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        child: Text(
          text.isEmpty ? '(debug empty)' : text,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
