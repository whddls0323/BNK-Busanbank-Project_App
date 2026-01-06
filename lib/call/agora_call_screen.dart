import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:tkbank/config/api_config.dart';
import 'package:tkbank/services/token_storage_service.dart';

class AgoraCallScreen extends StatefulWidget {
  final String voiceSessionId;
  final String agoraChannel;

  const AgoraCallScreen({
    super.key,
    required this.voiceSessionId,
    required this.agoraChannel,
  });

  @override
  State<AgoraCallScreen> createState() => _AgoraCallScreenState();
}

class _AgoraCallScreenState extends State<AgoraCallScreen> {
  final _tokenStorage = TokenStorageService();

  // ===== API =====
  Uri _statusUri(String sid) =>
      Uri.parse('${ApiConfig.baseUrl}/api/call/$sid/status-with-token');

  Uri _endUri(String sid) => Uri.parse('${ApiConfig.baseUrl}/api/call/$sid/end');

  // ===== Agora =====
  RtcEngine? _engine;
  Timer? _pollTimer;

  bool _joined = false;
  bool _loading = true;
  bool _muted = false;
  bool _ending = false;

  int _localUid = 0;
  int? _remoteUid;

  // UI 상태
  String _status = '초기화 중...';

  // 통화 타이머
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;

  // Debug
  bool _showDebug = false;
  String _debugLog = '';

  void _d(String s) {
    if (!mounted) return;
    setState(() => _debugLog += '\n$s');
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _callTimer?.cancel();
    _leaveAgora();
    super.dispose();
  }

  // =========================================================
  // 초기 진입
  // =========================================================
  Future<void> _boot() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() {
        _status = '마이크 권한이 필요합니다.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _status = '연결 준비 중...';
      _loading = false;
    });

    // ✅ 토큰 폴링
    int tick = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      tick++;
      if (tick > 30) {
        t.cancel();
        if (!mounted) return;
        setState(() => _status = '연결 대기 시간이 초과되었습니다.');
        return;
      }

      final info = await _fetchToken();
      if (info != null) {
        t.cancel();
        await _joinAgora(info);
      }
    });
  }

  // =========================================================
  // 토큰 폴링
  // =========================================================
  Future<_TokenInfo?> _fetchToken() async {
    try {
      final jwt = await _tokenStorage.readToken();

      final res = await http.post(
        _statusUri(widget.voiceSessionId),
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'role': 'CUSTOMER'}),
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final t = data['token'];
      if (t == null) return null;

      return _TokenInfo(
        appId: t['appId'],
        channel: t['channel'],
        uid: t['uid'],
        token: t['token'],
      );
    } catch (e) {
      _d('[token error] $e');
      return null;
    }
  }

  // =========================================================
  // ✅ 연결 상태 폴링 (콜백 누락 대비)
  // =========================================================
  Future<void> _waitUntilConnected({int maxMs = 5000}) async {
    final engine = _engine;
    if (engine == null) return;

    final until = DateTime.now().add(Duration(milliseconds: maxMs));
    while (DateTime.now().isBefore(until) && mounted && !_joined) {
      try {
        final st = await engine.getConnectionState();
        _d('[conn] state=$st');
        if (st == ConnectionStateType.connectionStateConnected) {
          _d('[conn] connected by polling');
          _onConnected(reason: 'POLLING_CONNECTED');
          return;
        }
      } catch (e) {
        _d('[conn] poll error: $e');
      }
      await Future.delayed(const Duration(milliseconds: 350));
    }
    _d('[conn] polling timeout (callbacks may be missing)');
  }

  // =========================================================
  // Agora Join
  // =========================================================
  Future<void> _joinAgora(_TokenInfo info) async {
    setState(() {
      _status = '통화 연결 중...';
      _loading = true;
      _remoteUid = null;
      _callDuration = Duration.zero;
    });

    _localUid = info.uid;

    // ✅ 혹시 이전 엔진이 남아 있으면 정리 (중복 엔진/콜백 꼬임 방지)
    await _leaveAgora();

    final engine = createAgoraRtcEngine();
    _engine = engine;

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (conn, elapsed) {
          _d('[cb] onJoinChannelSuccess: localUid=$_localUid elapsed=$elapsed');
          _onConnected(reason: 'JOIN_SUCCESS');
        },
        onConnectionStateChanged: (conn, state, reason) {
          _d('[cb] onConnectionStateChanged: state=$state reason=$reason');
          if (state == ConnectionStateType.connectionStateConnected) {
            _onConnected(reason: 'STATE_CONNECTED');
          }
        },

        onUserJoined: (conn, uid, elapsed) {
          _d('[cb] onUserJoined: uid=$uid');
          if (!mounted) return;
          setState(() => _remoteUid = uid);
        },
        onUserOffline: (conn, uid, reason) {
          _d('[cb] onUserOffline: uid=$uid reason=$reason');
          if (!mounted) return;
          setState(() => _remoteUid = null);
        },

        // ✅ 상대 오디오 수신 상태(= publish/재생 상태)를 가장 확실히 볼 수 있음
        onRemoteAudioStateChanged: (conn, uid, state, reason, elapsed) {
          _d('[cb] onRemoteAudioStateChanged: uid=$uid state=$state reason=$reason');
          // state가 Decoding/Starting 쪽이면 "상대 오디오 들어오는 중"으로 판단 가능
          if (!mounted) return;
          if (_remoteUid == null) setState(() => _remoteUid = uid);
        },

        onError: (err, msg) {
          _d('[cb] onError: $err $msg');
        },
      ),
    );

    await engine.initialize(RtcEngineContext(appId: info.appId));
    await engine.enableAudio();
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // ✅ 로컬 오디오 송출 상태를 명시적으로 보장(안드로이드 안정성)
    await engine.enableLocalAudio(true);
    await engine.muteLocalAudioStream(false);

    _d('[join] channel=${info.channel} uid=${info.uid}');

    await engine.joinChannel(
      token: info.token,
      channelId: info.channel,
      uid: info.uid,
      options: const ChannelMediaOptions(),
    );

    // ✅ 콜백 누락 대비: 연결상태 폴링으로 UI 전환 보강
    await _waitUntilConnected();
  }

  void _onConnected({required String reason}) {
    if (!mounted || _joined) return;

    _d('[connected] reason=$reason');

    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _callDuration += const Duration(seconds: 1));
    });

    setState(() {
      _joined = true;
      _loading = false;
      _status = '통화 중';
    });
  }

  // =========================================================
  // Agora Leave
  // =========================================================
  Future<void> _leaveAgora() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
    _engine = null;
  }

  // =========================================================
  // 종료
  // =========================================================
  Future<void> _hangup() async {
    if (_ending) return;
    _ending = true;

    _callTimer?.cancel();
    await _leaveAgora();

    try {
      final jwt = await _tokenStorage.readToken();
      await http.post(
        _endUri(widget.voiceSessionId),
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'reason': 'CUSTOMER_HANGUP'}),
      );
    } catch (_) {}

    if (mounted) Navigator.pop(context);
  }

  String _fmt(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '${hh.toString().padLeft(2, '0')}:$mm:$ss' : '$mm:$ss';
  }

  String get _subStatus {
    if (_loading && !_joined) return '연결 준비 중';
    if (!_joined) return '채널 연결 대기 중';
    if (_joined && _remoteUid == null) return '상담사 음성 연결 대기 중';
    return '상담사 연결됨';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCalling = _joined && !_loading;

    return PopScope(
      canPop: false,
      onPopInvoked: (_) async => _hangup(),
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('통화'),
          centerTitle: true,
          actions: [
            if (kDebugMode)
              IconButton(
                onPressed: () => setState(() => _showDebug = !_showDebug),
                icon: const Icon(Icons.bug_report_outlined),
                tooltip: 'Debug',
              ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [
                // 상단 프로필/상태
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Icon(Icons.support_agent,
                            size: 40, color: cs.primary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isCalling ? _fmt(_callDuration) : '--:--',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _subStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: isCalling
                              ? () async {
                            _muted = !_muted;
                            await _engine?.muteLocalAudioStream(_muted);
                            if (mounted) setState(() {});
                          }
                              : null,
                          icon: Icon(_muted ? Icons.mic_off : Icons.mic,
                              size: 22),
                          label: Text(
                            _muted ? '마이크 켜기' : '마이크 끄기',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _hangup,
                          icon: const Icon(Icons.call_end, size: 22),
                          label: const Text(
                            '통화 종료',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Opacity(
                  opacity: 0.75,
                  child: Text(
                    '네트워크 상황에 따라 연결까지 시간이 걸릴 수 있습니다.',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),

                if (kDebugMode && _showDebug) ...[
                  const SizedBox(height: 14),
                  Expanded(
                    child: _DebugPanel(
                      text: _debugLog,
                      localUid: _localUid,
                      remoteUid: _remoteUid,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  final String text;
  final int localUid;
  final int? remoteUid;

  const _DebugPanel({
    required this.text,
    required this.localUid,
    required this.remoteUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SingleChildScrollView(
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('local=$localUid / remote=${remoteUid ?? "-"}'),
              const SizedBox(height: 8),
              Text(text.isEmpty ? '(debug empty)' : text),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// Token DTO
// =========================================================
class _TokenInfo {
  final String appId;
  final String channel;
  final int uid;
  final String token;

  _TokenInfo({
    required this.appId,
    required this.channel,
    required this.uid,
    required this.token,
  });
}
