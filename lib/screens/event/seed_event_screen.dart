import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/models/seed_event_status.dart';
import 'package:tkbank/providers/seed_event_provider.dart';

class SeedEventScreen extends StatefulWidget {
  const SeedEventScreen({super.key});

  @override
  State<SeedEventScreen> createState() => _SeedEventScreenState();
}

class _SeedEventScreenState extends State<SeedEventScreen> {
  bool _showPlantingAnimation = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SeedEventProvider>();
    final status = provider.status;

    if (status == null) {
      provider.loadStatus();
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canPlantToday =
        status.uiState == SeedUIState.canPlant ||
            status.uiState == SeedUIState.failedCanRetry;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF7),
      appBar: AppBar(
        title: const Text('🌱 금열매 이벤트'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              _buildGoldPriceHeader(status.todayPrice),
              const SizedBox(height: 130),
              /// 🌱 Lottie 영역 (Hero)
              SizedBox(
                height: 350, // ← 여기서 조절
                child: Center(
                  child: _buildLottieByState(status.uiState),
                ),
              ),
              const SizedBox(height: 15),
              /// ✍️ 텍스트 + 버튼 영역
              Column(
                children: [
                  _buildStatusMessage(status),
                  // 👇 상태별 정보 카드 추가
                  const SizedBox(height: 35),
                  if (status.uiState == SeedUIState.waiting)
                    _buildWaitingInfoCard(status),

                  if (status.uiState == SeedUIState.success ||
                      status.uiState == SeedUIState.failedCanRetry)
                    _buildResultHistoryCard(status),

                  const SizedBox(height: 35),
                  if (canPlantToday)
                    _buildWideSeedButton(
                      isLoading: provider.isLoading,
                      onPressed: () async {
                        await _playPlantingAnimation(provider);
                      },
                    ),
                ],
              ),
            ],
          ),

          /// 🌳 심기 애니메이션 오버레이
          if (_showPlantingAnimation)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.9),
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/Tree_Plantation.json',
                    repeat: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  Widget _buildLottieByState(SeedUIState state) {
    String asset;

    switch (state) {
      case SeedUIState.success:
        asset = 'assets/lottie/Reward.json';
        break;

      case SeedUIState.waiting:
        asset = 'assets/lottie/Plant_Sprout.json';
        break;

      case SeedUIState.failedCanRetry:
        asset = 'assets/lottie/Animated_plant_loader.json';
        break;

      case SeedUIState.canPlant:
        asset = 'assets/lottie/Save_Amazon_Jungle.json';
        break;
    }

    return Lottie.asset(
      asset,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
    );
  }
  Future<void> _playPlantingAnimation(SeedEventProvider provider) async {
    setState(() {
      _showPlantingAnimation = true;
    });

    /// 🌳 애니메이션 시간 (2초 추천)
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      provider.plantSeed(),
    ]);

    if (!mounted) return;

    setState(() {
      _showPlantingAnimation = false;
    });
  }

  Widget _buildStatusMessage(SeedEventStatus status) {
    switch (status.uiState) {
      case SeedUIState.success:
        return const Text(
          '🌟 축하해요! 황금 열매가 열렸어요!\n쿠폰함을 확인해 주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );

      case SeedUIState.waiting:
        return const Text(
          '🌱 씨앗을 심었어요!\n결과는 다음 금 시세 반영 후 확인할 수 있어요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        );

      case SeedUIState.failedCanRetry:
        return const Text(
          '🌿 일반 열매가 자랐어요.\n다시 씨앗을 심어볼까요?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        );

      case SeedUIState.canPlant:
        return const Text(
          '오늘의 씨앗을 아직 심지 않았어요. 🌱\n씨앗을 심으면 내일 금 시세를 예측할 수 있어요.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        );
    }
  }

  Widget _buildWideSeedButton({
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF66BB6A),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.spa, // 🌿 나뭇잎 느낌
                  size: 30,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  '씨앗 심기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildGoldPriceHeader(double price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1), // 아주 연한 골드
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '🟡 오늘의 금 시세 $price원',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF8D6E00),
        ),
      ),
    );
  }

  Widget _buildWaitingInfoCard(SeedEventStatus status) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '나의 예측 정보',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('오차 범위: ±${status.errorRate}%'),
          Text(
            '예측 금액: ${status.minPrice} ~ ${status.maxPrice}원',
          ),
        ],
      ),
    );
  }

  Widget _buildResultHistoryCard(SeedEventStatus status) {
    final isSuccess = status.todayResult == SeedResult.success;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFFF1F8E9)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.redAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSuccess ? '🌟 금열매 심기 성공' : '❌ 금열매 심기 실패',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text('오차 범위: ±${status.errorRate}%'),
          Text('예측 금액: ${status.minPrice} ~ ${status.maxPrice}원'),
          Text(
            '실제 금 시세: ${status.todayPrice}원',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }



}

