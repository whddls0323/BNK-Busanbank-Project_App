import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/flutter_api_service.dart';
import '../../models/news_analysis_result.dart';
import 'news_result_screen.dart';
import 'package:tkbank/theme/app_colors.dart';

class NewsAnalysisMainScreen extends StatefulWidget {
  final String baseUrl;

  const NewsAnalysisMainScreen({
    super.key,
    required this.baseUrl,
  });

  @override
  State<NewsAnalysisMainScreen> createState() => _NewsAnalysisMainScreenState();
}

class _NewsAnalysisMainScreenState extends State<NewsAnalysisMainScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late FlutterApiService _apiService;

  File? _selectedImage;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();

    // ✅ baseUrl 정리: /api와 중복된 /busanbank... 제거
    String cleanUrl = widget.baseUrl
        .replaceAll('/api', '')                    // /api 제거
        .replaceAll(RegExp(r'/busanbank.*'), '/busanbank');  // 중복 제거

    _apiService = FlutterApiService(baseUrl: cleanUrl);

    print('🔥 AI 분석 정리된 baseUrl: $cleanUrl');
  } // 26.01.08 _ 시연 영상 제작 중 경로 에러가 나서 급하게 수정함 - 수빈

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // URL 기반 분석
  Future<void> _analyzeUrl() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      _showError('URL을 입력해주세요.');
      return;
    }

    if (!url.startsWith('http')) {
      _showError('올바른 URL을 입력해주세요. (http:// 또는 https://)');
      return;
    }

    setState(() => _analyzing = true);

    try {
      final result = await _apiService.analyzeNewsUrl(url);

      setState(() => _analyzing = false);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsResultScreen(
            baseUrl: widget.baseUrl,
            result: result,
          ),
        ),
      );
    } catch (e) {
      setState(() => _analyzing = false);
      _showError('분석 실패: $e');
    }
  }

  // 이미지 선택
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('이미지 선택 실패: $e');
    }
  }

  // 이미지 기반 분석
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showError('이미지를 선택해주세요.');
      return;
    }

    setState(() => _analyzing = true);

    try {
      final result = await _apiService.analyzeNewsImage(_selectedImage!);

      setState(() => _analyzing = false);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewsResultScreen(
            baseUrl: widget.baseUrl,
            result: result,
          ),
        ),
      );
    } catch (e) {
      setState(() => _analyzing = false);
      _showError('분석 실패: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [

            Stack(
              clipBehavior: Clip.none,
              children: [
                // 상단 이미지
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.35,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/ai_main.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black38,
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Stack(
                      children: [
                        // 뒤로가기 버튼
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton(
                            icon: const Icon(
                              Icons.chevron_left,
                              color: AppColors.white,
                              size: 34,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        // 중앙 타이틀 & 카피
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.03,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  '기사/콘텐츠 분석 (AI)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'URL을 입력하고 "AI 분석" 버튼을 누르면\n기사 요약 / 키워드 / 추천 상품을 제공합니다',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.white,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 아래 콘텐츠와 연결되는 라운드 영역
                Positioned(
                  bottom: MediaQuery.of(context).size.height * -0.05,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.1,
                    decoration: const BoxDecoration(
                      color: AppColors.gray1,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // 📝 URL 입력 섹션
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 0), // ← 아래로 떨어지는 그림자
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.blue, Colors.blue[600]!],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.link,
                                  color: AppColors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'URL로 분석하기',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              hintText: '뉴스 기사 URL을 입력하세요',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: AppColors.gray1,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.blue,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.web, color: AppColors.blue),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: _analyzing ? null : _analyzeUrl,
                              icon: _analyzing
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(Icons.analytics, size: 28),
                              label: Text(
                                _analyzing ? '분석 중...' : 'AI 분석',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                foregroundColor: AppColors.white,
                                elevation: 0, // ← 반드시 0
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  _dashedDivider(),
                  const SizedBox(height: 40),

                  // 📷 이미지 업로드 섹션
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 0), // 아래로 떨어지는 그림자
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.pink, AppColors.primary],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                '이미지로 분석하기',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 이미지 선택 버튼
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt, size: 24),
                                  label: const Text(
                                    '카메라',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(20),
                                    side: BorderSide(
                                      color: Colors.purple[300]!,
                                      width: 2,
                                    ),
                                    foregroundColor: Colors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library, size: 24),
                                  label: const Text(
                                    '갤러리',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.all(20),
                                    side: BorderSide(
                                      color: Colors.purple[300]!,
                                      width: 2,
                                    ),
                                    foregroundColor: Colors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_selectedImage != null) ...[
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 분석 버튼
                            Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _analyzing ? null : _analyzeImage,
                                icon: _analyzing
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.analytics, size: 28),
                                label: Text(
                                  _analyzing ? '분석 중...' : 'AI 분석',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 점선 Divider
  Widget _dashedDivider() {
    return LayoutBuilder(
      builder: (_, constraints) {
        return Row(
          children: List.generate(
            (constraints.maxWidth / 6).floor(),
                (index) =>
                Expanded(
                  child: Container(
                    height: 1,
                    color:
                    index.isEven ? AppColors.gray4 : Colors.transparent,
                  ),
                ),
          ),
        );
      },
    );
  }
}