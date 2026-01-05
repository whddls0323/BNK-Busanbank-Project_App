import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/services/flutter_api_service.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

// 2025-12-16 - 영업점 체크인 화면 (API 연동) - 작성자: 진원
// 2025-12-17 - FlutterApiService 사용하도록 수정 (JWT 토큰 자동 추가) - 작성자: 진원
// 2026/01/04 - UI/UX 개선 (내위치 버튼, 체크인 반경 표시) - 작성자: 진원
// 2026/01/05 - 카카오 지도 WebView 기반으로 전환, 마커 및 위치 기능 추가 - 작성자: 진원
class BranchCheckinScreen extends StatefulWidget {
  final String baseUrl;

  const BranchCheckinScreen({super.key, required this.baseUrl});

  @override
  State<BranchCheckinScreen> createState() => _BranchCheckinScreenState();
}

class _BranchCheckinScreenState extends State<BranchCheckinScreen> {
  late FlutterApiService _apiService;
  late WebViewController _webViewController;
  bool isLoading = true;
  int totalCheckins = 0;
  int earnedPoints = 0;
  String? lastCheckinBranch;
  String? lastCheckinDate;

  List<Map<String, dynamic>> branches = [];

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);
    _initWebViewController();
    _requestLocationPermissionAndLoad();
  }

  /// 2026/01/05 - 위치 권한 요청 및 데이터 로드 - 작성자: 진원
  Future<void> _requestLocationPermissionAndLoad() async {
    await _requestLocationPermission();
    await _loadData();
    await _sendLocationToWebView();
  }

  /// 2026/01/05 - 위치 권한 요청 - 작성자: 진원
  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 2026/01/05 - 현재 위치를 JavaScript로 전달 - 작성자: 진원
  Future<void> _sendLocationToWebView() async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('위치 서비스가 비활성화되어 있습니다.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('위치 서비스를 활성화해주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('위치 권한이 거부되었습니다.');
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // JavaScript로 위치 전달
      final jsCode = '''
        if (typeof updateMyLocation === 'function') {
          updateMyLocation(${position.latitude}, ${position.longitude});
        }
      ''';

      await _webViewController.runJavaScript(jsCode);
      debugPrint('위치 정보 전달 완료: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('위치 정보 가져오기 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('위치 정보를 가져올 수 없습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// WebView 컨트롤러 초기화
  void _initWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          // JavaScript에서 체크인 요청 수신
          _handleCheckinRequest(message.message);
        },
      )
      ..loadFlutterAsset('assets/branch_map.html');
  }

  /// JavaScript에서 받은 체크인 요청 처리
  Future<void> _handleCheckinRequest(String message) async {
    try {
      final data = jsonDecode(message);
      final branchId = data['branchId'];
      final branchName = data['branchName'];
      final latitude = data['latitude'];
      final longitude = data['longitude'];

      await _checkin(branchId, branchName, latitude, longitude);
    } catch (e) {
      debugPrint('체크인 요청 처리 실패: $e');
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCheckinHistory(),
      _loadBranches(),
    ]);
  }

  Future<void> _loadCheckinHistory() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인이 필요합니다');
      }

      final data = await _apiService.getCheckinHistory(userNo);

      setState(() {
        totalCheckins = data['totalCheckins'] ?? 0;
        earnedPoints = data['earnedPoints'] ?? 0;

        if (data['lastCheckin'] != null) {
          lastCheckinBranch = data['lastCheckin']['branchName'];
          lastCheckinDate = data['lastCheckin']['checkinDate'];
        }
      });
    } catch (e) {
      debugPrint('체크인 기록 로드 실패: $e');
    }
  }

  Future<void> _loadBranches() async {
    setState(() {
      isLoading = true;
    });

    try {
      final branchList = await _apiService.getBranches();

      setState(() {
        branches = branchList.map((branch) {
          return {
            'branchId': branch.branchId,
            'branchName': branch.branchName,
            'branchAddr': branch.branchAddr,
            'latitude': branch.latitude,
            'longitude': branch.longitude,
          };
        }).toList();
        isLoading = false;
      });

      // JavaScript로 영업점 데이터 전달
      _sendBranchesToWebView();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  /// JavaScript로 영업점 데이터 전송
  Future<void> _sendBranchesToWebView() async {
    if (branches.isEmpty) return;

    final branchesJson = jsonEncode(branches);
    final jsCode = 'loadBranchesFromFlutter($branchesJson);';

    try {
      await _webViewController.runJavaScript(jsCode);
    } catch (e) {
      debugPrint('JavaScript 실행 실패: $e');
    }
  }

  Future<void> _checkin(int branchId, String branchName, double latitude, double longitude) async {
    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인이 필요합니다');
      }

      final data = await _apiService.checkin(
        userId: userNo,
        branchId: branchId,
        latitude: latitude,
        longitude: longitude,
      );

      setState(() {
        isLoading = false;
      });

      if (data['success'] == true) {
        await _loadCheckinHistory();

        // JavaScript로 체크인 성공 알림
        final points = data['earnedPoints'] ?? 20;
        await _webViewController.runJavaScript(
          'onCheckinResult(true, "$branchName 체크인 완료", $points);',
        );
      } else {
        // JavaScript로 체크인 실패 알림
        final message = data['message'] ?? '체크인 실패';
        await _webViewController.runJavaScript(
          'onCheckinResult(false, "$message", 0);',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('체크인 실패: $e');

      // JavaScript로 에러 알림
      await _webViewController.runJavaScript(
        'onCheckinResult(false, "체크인 실패: $e", 0);',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영업점 체크인'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadData();
            },
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 카카오 지도 WebView
          WebViewWidget(controller: _webViewController),

          // 상단 정보 카드
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          icon: Icons.location_on,
                          label: '총 체크인',
                          value: '$totalCheckins회',
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white30,
                        ),
                        _buildStatColumn(
                          icon: Icons.stars,
                          label: '획득 포인트',
                          value: '$earnedPoints P',
                        ),
                      ],
                    ),
                    if (lastCheckinBranch != null) ...[
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white30, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '최근: $lastCheckinBranch',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 로딩 표시
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
