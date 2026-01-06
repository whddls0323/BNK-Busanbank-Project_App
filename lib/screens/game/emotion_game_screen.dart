// 2025/12/28 - 감정 분석 게임 통합 화면 - 작성자: 진원
// 2026/01/04 - 눈 깜빡임 감지 개선 및 수동 촬영 버튼 추가 - 작성자: 진원
// 2026/01/05 - 눈 깜빡임 감지 조건 완화 및 InputImage 포맷 수정 - 작성자: 진원

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../services/emotion_game_service.dart';

class EmotionGameScreen extends StatefulWidget {
  const EmotionGameScreen({Key? key}) : super(key: key);

  @override
  State<EmotionGameScreen> createState() => _EmotionGameScreenState();
}

class _EmotionGameScreenState extends State<EmotionGameScreen> {
  final EmotionGameService _gameService = EmotionGameService();

  // 게임 상태
  String? _selectedGameType;
  String? _targetEmotion; // 감정 표현 게임 미션
  bool _isCameraReady = false;
  bool _isProcessing = false;
  bool _isBlinkDetected = false;

  // 카메라 관련
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // 얼굴 감지
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  // 눈 깜빡임 감지 상태
  bool _wasEyesClosed = false;
  int _blinkCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  /// 카메라 초기화
  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        // 전면 카메라 사용
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        // 2026/01/06 - 얼굴 감지 개선을 위해 해상도 high로 변경 - 작성자: 진원
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high, // medium → high (얼굴 감지 정확도 향상)
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('[EmotionGame] 카메라 초기화 실패: $e');
    }
  }

  /// 게임 시작
  void _startGame(String gameType) {
    // 감정 표현 게임이면 랜덤 미션 선택
    String? targetEmotion;
    if (gameType == 'EMOTION_EXPRESS') {
      final emotions = ['joy', 'sorrow', 'anger', 'surprise'];
      targetEmotion = emotions[DateTime.now().millisecond % emotions.length];
    }

    setState(() {
      _selectedGameType = gameType;
      _targetEmotion = targetEmotion;
      _isCameraReady = true;
      _blinkCount = 0;
      _isBlinkDetected = false;
    });

    // 카메라 스트리밍 시작 (눈 깜빡임 감지)
    _startBlinkDetection();
  }

  /// 눈 깜빡임 감지 시작
  /// 2026/01/05 - 눈 깜빡임 감지 조건 완화 및 디버그 로그 추가 - 작성자: 진원
  void _startBlinkDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print('[EmotionGame] ⚠️ 카메라가 초기화되지 않음');
      return;
    }

    print('[EmotionGame] 👁️ 눈 깜빡임 감지 시작...');

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing || _isBlinkDetected) return;

      _isProcessing = true;

      try {
        // 2026/01/06 - 얼굴 감지 개선: 회전 각도 동적 계산 - 작성자: 진원
        // 카메라 센서의 실제 회전 각도 계산
        final sensorOrientation = _cameraController!.description.sensorOrientation;
        final rotationCompensation = sensorOrientation ~/ 90;

        // Android 전면 카메라 회전 매핑
        InputImageRotation rotation;
        switch (rotationCompensation) {
          case 0:
            rotation = InputImageRotation.rotation0deg;
            break;
          case 1:
            rotation = InputImageRotation.rotation90deg;
            break;
          case 2:
            rotation = InputImageRotation.rotation180deg;
            break;
          case 3:
            rotation = InputImageRotation.rotation270deg;
            break;
          default:
            rotation = InputImageRotation.rotation0deg;
        }

        // InputImage 포맷 결정 (Android는 보통 yuv420 또는 nv21)
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        // null이 아닌 값으로 설정 (기본값: nv21)
        final InputImageFormat inputImageFormat =
            image.format.group == ImageFormatGroup.yuv420
                ? InputImageFormat.yuv420
                : InputImageFormat.nv21;

        print('[EmotionGame] 📷 센서 방향: $sensorOrientation°, 회전: $rotation'); // 디버그

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation, // 동적 계산된 회전 각도 사용
            format: inputImageFormat,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        // 얼굴 감지
        final List<Face> faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          final Face face = faces.first;

          // 눈 깜빡임 감지
          final leftEyeOpen = face.leftEyeOpenProbability;
          final rightEyeOpen = face.rightEyeOpenProbability;

          if (leftEyeOpen != null && rightEyeOpen != null) {
            // 디버그: 눈 확률 출력
            print('[EmotionGame] 👁️ 왼쪽 눈: ${leftEyeOpen.toStringAsFixed(2)}, 오른쪽 눈: ${rightEyeOpen.toStringAsFixed(2)}');

            // 2026/01/05 - 눈 깜빡임 감지 조건 대폭 완화 - 작성자: 진원
            // 눈 감김 조건: 0.5 이하 (이전 0.4)
            bool eyesClosed = leftEyeOpen < 0.5 && rightEyeOpen < 0.5;
            // 눈 뜸 조건: 0.5 이상 (이전 0.6)
            bool eyesOpened = leftEyeOpen > 0.5 && rightEyeOpen > 0.5;

            // 눈 감김 → 눈 뜸: 깜빡임 감지!
            if (_wasEyesClosed && eyesOpened) {
              print('[EmotionGame] ✅ 눈 깜빡임 감지! 촬영 시작');

              setState(() {
                _blinkCount++;
                _isBlinkDetected = true;
              });

              // 카메라 스트림 중지
              await _cameraController!.stopImageStream();

              // 눈을 완전히 뜬 후 촬영하도록 약간의 딜레이 추가
              await Future.delayed(const Duration(milliseconds: 300));

              // 자동 촬영
              _captureAndAnalyze();
            }

            _wasEyesClosed = eyesClosed;
          } else {
            print('[EmotionGame] ⚠️ 눈 확률 값을 가져올 수 없음 (null)');
          }
        } else {
          print('[EmotionGame] ⚠️ 얼굴이 감지되지 않음');
        }
      } catch (e) {
        print('[EmotionGame] ❌ 얼굴 감지 에러: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  /// 사진 촬영 및 감정 분석
  Future<void> _captureAndAnalyze() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      // 사진 촬영
      final XFile imageFile = await _cameraController!.takePicture();

      // 로딩 표시
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 감정 분석 API 호출
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인이 필요합니다');
      }

      final result = await _gameService.analyzeEmotion(
        gameType: _selectedGameType!,
        userNo: userNo,
        imageFile: File(imageFile.path),
        targetEmotion: _targetEmotion,
      );

      // 로딩 닫기
      if (mounted) {
        Navigator.pop(context);
      }

      // 결과 표시
      _showResult(result);
    } catch (e) {
      // 로딩 닫기
      if (mounted) {
        Navigator.pop(context);
      }

      // 에러 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('분석 실패: $e')),
        );
      }

      // 게임 초기화
      setState(() {
        _selectedGameType = null;
        _isCameraReady = false;
        _isBlinkDetected = false;
      });
    }
  }

  /// 결과 표시
  void _showResult(Map<String, dynamic> result) {
    final bool success = result['success'] ?? false;
    final int points = result['points'] ?? 0;
    final String message = result['message'] ?? '';
    final String joyLevel = result['joyLevel'] ?? 'UNKNOWN';
    final int? happinessScore = result['happinessScore'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(success ? '🎉 성공!' : '😅 아쉬워요'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (success) ...[
              Text(
                '+${points}P',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (happinessScore != null) ...[
              Text(
                '행복 지수: $happinessScore점',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '기쁨 수준: $joyLevel',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedGameType = null;
                _isCameraReady = false;
                _isBlinkDetected = false;
              });
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedGameType == null
            ? '감정 분석 게임'
            : _gameService.getGameName(_selectedGameType!)),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: _selectedGameType == null
          ? _buildGameSelection()
          : _buildCameraView(),
    );
  }

  /// 게임 선택 화면
  Widget _buildGameSelection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '게임을 선택하세요',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildGameCard(
            gameType: 'SMILE_CHALLENGE',
            title: '웃음 챌린지',
            icon: '😊',
            reward: '50P',
            color: const Color(0xFFFFEB3B),
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            gameType: 'EMOTION_EXPRESS',
            title: '감정 표현 게임',
            icon: '🎭',
            reward: '100P',
            color: const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            gameType: 'HAPPINESS_METER',
            title: '행복 지수 측정',
            icon: '📊',
            reward: '최대 150P',
            color: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  /// 게임 카드
  Widget _buildGameCard({
    required String gameType,
    required String title,
    required String icon,
    required String reward,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _startGame(gameType),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _gameService.getGameDescription(gameType),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '보상: $reward',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 카메라 뷰
  Widget _buildCameraView() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // 카메라 프리뷰
        SizedBox.expand(
          child: CameraPreview(_cameraController!),
        ),

        // 안내 메시지
        if (!_isBlinkDetected)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // 감정 표현 게임이면 미션 표시
                  if (_selectedGameType == 'EMOTION_EXPRESS' && _targetEmotion != null) ...[
                    Text(
                      _gameService.getEmotionInfo(_targetEmotion!)['icon']!,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_gameService.getEmotionInfo(_targetEmotion!)['name']}을(를) 표현하세요!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    '👁️ 눈을 깜빡이면 자동으로 촬영됩니다',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedGameType != 'EMOTION_EXPRESS') ...[
                    const SizedBox(height: 8),
                    Text(
                      _gameService.getGameDescription(_selectedGameType!),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),

        // 2026/01/04 - 수동 촬영 버튼 추가 - 작성자: 진원
        if (!_isBlinkDetected)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const Text(
                    '또는',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!_isBlinkDetected) {
                        setState(() => _isBlinkDetected = true);

                        // 카메라 스트림 중지
                        if (_cameraController!.value.isStreamingImages) {
                          await _cameraController!.stopImageStream();
                        }

                        // 수동 촬영
                        _captureAndAnalyze();
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      '직접 촬영하기',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 깜빡임 감지 표시
        if (_blinkCount > 0)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  '깜빡임 감지! 촬영 중...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
