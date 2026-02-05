import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final screenHeight = MediaQuery.of(context).size.height;

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
          /// 1️⃣ 메인 화면 (스크롤 없는 반응형 이벤트 화면)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    const SizedBox(height: 20),

                    /// 🟡 금 시세 헤더
                    _buildGoldPriceHeader(status.todayPrice),

                    const SizedBox(height: 20),

                    /// 🌱 Lottie 영역 (화면 비율)
                    Expanded(
                      flex: 4,
                      child: _buildLottieByState(status.uiState),
                    ),

                    /// ✍️ 상태 메시지
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildStatusMessage(status),
                    ),

                    const SizedBox(height: 16),

                    if (status.uiState == SeedUIState.waiting)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildWaitingInfoCard(status),
                      ),

                    if (status.uiState == SeedUIState.success ||
                        status.uiState == SeedUIState.failedCanRetry)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildResultHistoryCard(status),
                      ),

                    const Spacer(),

                    /// 🌱 하단 버튼
                    if (canPlantToday)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                          bottom: 35,
                        ),
                        child: _buildWideSeedButton(
                          isLoading: provider.isLoading,
                          onPressed: () async {
                            await _playPlantingAnimation(provider);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          /// 2️⃣ 🌳 씨앗 심기 애니메이션 오버레이 (복구!)
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
    // 1️⃣ 심는 애니메이션 시작
    setState(() {
      _showPlantingAnimation = true;
    });

    // 2️⃣ 충분히 보여주기 (UX용)
    await Future.delayed(const Duration(milliseconds: 6000));

    if (!mounted) return;

    // 3️⃣ 서버에 심기 요청 → WAIT 상태로 변경
    await provider.plantSeed();

    if (!mounted) return;

    // 4️⃣ 애니메이션 종료 → WAIT 화면 노출
    setState(() {
      _showPlantingAnimation = false;
    });
  }


  Widget _buildStatusMessage(SeedEventStatus status) {
    switch (status.uiState) {
      case SeedUIState.success:
        return Column(
          children: const [
            Text(
              '금 열매가 열렸어요 🌟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '쿠폰함에서 보상을 확인해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        );

      case SeedUIState.waiting:
        return Column(
          children: const [
            Text(
              '씨앗을 심었어요 🌱',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '내일 금 시세가 반영되면\n결과를 확인할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        );

      case SeedUIState.failedCanRetry:
        return Column(
          children: const [
            Text(
              '이번엔 일반 열매였어요 🌿',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '다시 씨앗을 심고\n금 열매에 도전해 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        );

      case SeedUIState.canPlant:
        return Column(
          children: const [
            Text(
              '오늘의 씨앗을 심어보세요 🌱',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '씨앗을 심고 내일 금 시세를 맞히면\n금 열매가 열려요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ],
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
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '🟡 오늘의 금 시세 ${formatUsd(price)}',
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
            '예측 금액: ${formatUsd(status.minPrice)} ~ ${formatUsd(status.maxPrice)}',
          ),
        ],
      ),
    );
  }

  Widget _buildResultHistoryCard(SeedEventStatus status) {
    final isSuccess = status.uiState == SeedUIState.success;

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
          Text(
            '예측 금액: ${formatUsd(status.minPrice)} ~ ${formatUsd(status.maxPrice)}',
          ),
          if (status.resultPrice != null)
            Text(
              '실제 금 시세: ${formatUsd(status.resultPrice)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }




}

String formatUsd(num? price) {
  if (price == null) return '-';

  return NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  ).format(price);
}
