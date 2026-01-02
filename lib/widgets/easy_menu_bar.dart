import 'package:flutter/material.dart';
import 'package:tkbank/theme/app_colors.dart';
import '../core/menu/main_menu_config.dart';
import '../core/menu/main_menu_controller.dart';
import '../core/menu/main_menu_item.dart';
import 'package:tkbank/screens/product/interest_calculator_screen.dart';
import 'package:tkbank/screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';
import 'package:tkbank/screens/product/news_analysis_screen.dart';

class EasyMenuBar extends StatefulWidget {
  final MainMenuType menuType;
  final String baseUrl;

  const EasyMenuBar({
    super.key,
    required this.menuType,
    required this.baseUrl,
  });

  @override
  State<EasyMenuBar> createState() => _EasyMenuBarState();
}

class _EasyMenuBarState extends State<EasyMenuBar> {
  late MainMenuController controller;
  late List<MainMenuItem> menus;

  // 👇 메뉴별 설명 텍스트
  final Map<MainMenuAction, String> menuDescriptions = {
    MainMenuAction.analysis: '똑똑한 딸깍이와 함께\n뉴스를 분석해 보아요.',
    MainMenuAction.calculator: '한번에 딸깍!\n쉽게 금리를 계산해요.',
    MainMenuAction.game: '게임도 하고!\n금리도 쌓고!',
    MainMenuAction.cs: '딸깍은행은 항상\n여러분 곁에 있어요.',
  };

  @override
  void initState() {
    super.initState();
    menus = MainMenuConfig.getMenus(type: widget.menuType);
    controller = MainMenuController(
      totalCount: menus.length,
      itemWidth: 202.0,
    );
  }

  @override
  void dispose() {
    controller.disposeController();
    super.dispose();
  }

  void _handleMenuTap(MainMenuAction action) {
    switch (action) {
      case MainMenuAction.analysis:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewsAnalysisMainScreen(baseUrl: widget.baseUrl),
          ),
        );
        break;

      case MainMenuAction.calculator:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InterestCalculatorScreen(),
          ),
        );
        break;

      case MainMenuAction.game:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameMenuScreen(baseUrl: widget.baseUrl),
          ),
        );
        break;

      case MainMenuAction.cs:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CustomerSupportScreen(),
          ),
        );
        break;

      case MainMenuAction.more:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 헤더 (추천 메뉴 + 페이지네이션)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '추천 메뉴',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  controller.progressText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray4,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 👇 가로 스크롤 카드
        SizedBox(
          height: 260,
          child: ListView.builder(
            controller: controller.scrollController,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 5,
            ),
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final item = menus[index];
              return _menuCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _menuCard(MainMenuItem item) {
    // 메뉴별 3D 아이콘 이미지 경로
    final Map<MainMenuAction, String> menuIcons = {
      MainMenuAction.analysis: 'assets/images/analysis.png',
      MainMenuAction.calculator: 'assets/images/calculator.png',
      MainMenuAction.game: 'assets/images/game.png',
      MainMenuAction.cs: 'assets/images/cs.png',
    };

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleMenuTap(item.action),
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D PNG 아이콘
              SizedBox(
                width: 60,
                height: 60,
                child: Image.asset(
                  menuIcons[item.action]!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    // 이미지 로드 실패하면 여기로 fallback
                    decoration: BoxDecoration(
                      color: AppColors.gray3,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      item.icon,
                      size: 35,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 제목
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 5),

              // 설명
              Text(
                menuDescriptions[item.action] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray5,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}