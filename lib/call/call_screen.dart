import 'dart:math';
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

  String _log = '';
  bool _navigatedToAgora = false; // ✅ 중복 push 방지

  @override
  void initState() {
    super.initState();

    controller = VoiceCallController(
      api: VoiceCallApi(baseUrl: ApiConfig.baseUrl),
      ws: VoiceWebSocketService(),
    )
      ..addListener(() => setState(() {}))
      ..onAccepted = _goAgora
      ..onEnded = () => _append('[VOICE] ended pushed');
  }

  String _newSessionId() {
    final r = Random().nextInt(900000) + 100000;
    return 'TEST_SESSION_APP_$r';
  }

  void _append(String s) {
    setState(() => _log = '$_log\n$s');
  }

  void _goAgora() async {
    // ✅ ACCEPTED 이벤트가 여러 번 오거나 setState 반복될 수 있으니 1회만 이동
    if (_navigatedToAgora) return;
    _navigatedToAgora = true;

    final sid = controller.sessionId;
    final ch = controller.agoraChannel;

    _append('[VOICE] ACCEPTED -> move Agora (sid=$sid channel=$ch)');

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgoraCallScreen(
          voiceSessionId: controller.sessionId,
          agoraChannel: controller.agoraChannel,
          consultantId: controller.consultantId,
        ),
      ),
    );

    // ✅ Agora 화면에서 pop 되어 돌아오면, 다음 통화를 위해 상태를 정리
    // (서버 end는 Agora에서 이미 호출함)
    _append('[UI] back from Agora');
    _navigatedToAgora = false;

    // 화면만 초기화하고 싶으면 여기서 세션을 비워도 됩니다.
    // 단, 서버에서 VOICE_ENDED가 push되는 구조면 controller.state=ended로 바뀌어 있을 가능성이 큼.
    // 여기서는 UI가 다음 호출을 할 수 있도록 최소한만 초기화:
    // controller.sessionId를 컨트롤러 내부에서 직접 바꾸지 않는 구조면,
    // 사용자가 "전화 요청" 다시 누를 수 있게 화면을 idle로 돌리는 로직을 컨트롤러에 추가하는 게 정석.
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = controller.state;

    return Scaffold(
      appBar: AppBar(title: const Text('전화 상담 (고객)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatusCard(
              state: s,
              sessionId: controller.sessionId,
              wsOn: controller.ws.isConnected,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('전화 요청'),
                    onPressed: (s == UiVoiceCallState.idle)
                        ? () async {
                      final sid = _newSessionId();
                      _append('[REQ] enqueue $sid');

                      await controller.requestCall(newSessionId: sid);
                      _append('[OK] WAITING... (WS connect)');

                      // ✅ enqueue 성공 후 고객 WS 연결
                      controller.attachWs(baseWs: ApiConfig.wsBase);
                    }
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call_end),
                    label: const Text('종료'),
                    // ✅ 통화가 ACCEPTED 이후에는 Agora 화면에서 종료만 하게(여기서 중복 종료 방지)
                    onPressed: (controller.sessionId.isNotEmpty &&
                        s != UiVoiceCallState.accepted)
                        ? () async {
                      _append('[END] ${controller.sessionId}');
                      await controller.endCall();
                      _append('[OK] end requested');
                    }
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty ? '(log empty)' : _log,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),

            if (s == UiVoiceCallState.error) ...[
              const SizedBox(height: 8),
              Text(
                'ERROR: ${controller.errorMsg}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final UiVoiceCallState state;
  final String sessionId;
  final bool wsOn;

  const _StatusCard({
    required this.state,
    required this.sessionId,
    required this.wsOn,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;

    switch (state) {
      case UiVoiceCallState.idle:
        label = '대기';
        icon = Icons.hourglass_empty;
        break;
      case UiVoiceCallState.requesting:
        label = '요청 중...';
        icon = Icons.sync;
        break;
      case UiVoiceCallState.waiting:
        label = '상담사 연결 대기';
        icon = Icons.support_agent;
        break;
      case UiVoiceCallState.accepted:
        label = '연결됨 (Agora 이동)';
        icon = Icons.check_circle;
        break;
      case UiVoiceCallState.ended:
        label = '종료됨';
        icon = Icons.call_end;
        break;
      case UiVoiceCallState.error:
        label = '오류';
        icon = Icons.error;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('sessionId: ${sessionId.isEmpty ? "-" : sessionId}'),
              ],
            ),
          ),
          Text('WS: ${wsOn ? "ON" : "OFF"}'),
        ],
      ),
    );
  }
}
