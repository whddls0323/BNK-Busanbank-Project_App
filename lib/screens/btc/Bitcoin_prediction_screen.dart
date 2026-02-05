import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/bitcoin_service.dart';

class BitcoinPredictionScreen extends StatefulWidget { // 비트코인 예측 이벤트 - 작성자: 윤종인 2025.12.23
  final Function(String)? onPredictionSelected;

  const BitcoinPredictionScreen({
    Key? key,
    this.onPredictionSelected,
  }) : super(key: key);

  @override
  State<BitcoinPredictionScreen> createState() =>
      _BitcoinPredictionScreenState();
}

class _BitcoinPredictionScreenState extends State<BitcoinPredictionScreen> {
  final BitcoinService _bitcoinService = BitcoinService();

  String? _previousClosePrice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrice();
  }

  Future<void> _loadPrice() async {
    try {
      final result = await _bitcoinService.fetchResult();

      setState(() {
        _previousClosePrice = '${result.today} USD';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _previousClosePrice = '불러오기 실패';
        _loading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '예측이 접수됐어요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '내일 결과를 알려드릴게요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handlePrediction(String prediction) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;
      print('userNo 테스트: $userNo');

      if (userNo == null) {
        print('사용자 정보가 없습니다.');
        return;
      }

      await _bitcoinService.submitEventResult(
        prediction,
        userNo,
        needsAuth: true
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      print('예측 처리 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray1,

      body: Stack(
        children: [
          // 1️⃣ 메인 콘텐츠
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
              child: Column(
                children: [
                  _buildUnifiedHeader(),
                  const SizedBox(height: 40),

                  _buildStockInfo(),
                  const SizedBox(height: 30),

                  _buildQuestion(),
                  const SizedBox(height: 30),

                  _buildSelectionButtons(),
                  const SizedBox(height: 30),

                  _buildFooter(),
                ],
              ),
            ),
          ),

          // 2️⃣ 공통 뒤로가기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                size: 34,
                color: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedHeader() {
    return SizedBox(
      width: double.infinity, // ⭐️ 핵심
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎁 ', style: TextStyle(fontSize: 18)),
                Text(
                  '이벤트',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '비트코인 예측 챌린지',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            '다음 시세를 예측하고\n리워드를 받아보세요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(65, 40, 65, 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            _loading ? '로딩 중...' : _previousClosePrice ?? '-',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '현재가',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.gray5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return const Text(
      '다음 시세는 어떻게 될까요?',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSelectionButtons() {
    return Row(
      children: [
        // 상승 버튼
        Expanded(
          child: _buildPredictionButton(
            label: '상승',
            icon: Icons.trending_up,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF22C55E), Color(0xFF059669)],
            ),
            onTap: _loading ? null : () => _handlePrediction('UP'),
          ),
        ),
        const SizedBox(width: 12),
        // 하락 버튼
        Expanded(
          child: _buildPredictionButton(
            label: '하락',
            icon: Icons.trending_down,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEF4444), Color(0xFFE11D48)],
            ),
            onTap: _loading ? null : () => _handlePrediction('DOWN'),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      '선택 후 결과를 확인할 수 있습니다',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.gray5,
      ),
      textAlign: TextAlign.center,
    );
  }
}