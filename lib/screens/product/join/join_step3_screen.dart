import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product_join_request.dart';
import '../../../models/user_coupon.dart';
import '../../../services/flutter_api_service.dart';
import '../../../services/token_storage_service.dart';
import '../../member/login_screen.dart';
import 'join_step4_screen.dart';
import 'dart:math' as math;

/// 🔥 STEP 3: 포인트/쿠폰 선택, 금리 계산
///
/// 기능:
/// - 사용자 포인트 조회
/// - 포인트 사용 입력 (1000점당 0.1% 보너스)
/// - 쿠폰 선택
/// - 실시간 금리 계산
/// - 예상 이자 계산
class JoinStep3Screen extends StatefulWidget {
  final String baseUrl;
  final ProductJoinRequest request;

  const JoinStep3Screen({
    super.key,
    required this.baseUrl,
    required this.request,
  });

  @override
  State<JoinStep3Screen> createState() => _JoinStep3ScreenState();
}

class _JoinStep3ScreenState extends State<JoinStep3Screen> {
  late FlutterApiService _apiService;

  // 포인트
  int _totalPoints = 0;
  int _usedPoints = 0;
  final TextEditingController _pointsCtrl = TextEditingController();
  bool _loadingPoints = true;

  // 쿠폰
  List<UserCoupon> _coupons = [];
  int? _selectedCouponId;
  bool _loadingCoupons = true;

  // 금리 계산
  double _baseRate = 0.0;
  double _pointBonusRate = 0.0;
  double _couponBonusRate = 0.0;
  double _finalRate = 0.0;

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);
    _baseRate = widget.request.baseRate ?? 0.0;
    _finalRate = _baseRate;

    // ✅ 로그인 체크 후 데이터 로드
    _checkLoginAndLoadData();
  }

  @override
  void dispose() {
    _pointsCtrl.dispose();
    super.dispose();
  }

  /// ✅ 로그인 체크 및 데이터 로드
  Future<void> _checkLoginAndLoadData() async {
    final token = await TokenStorageService().readToken();

    if (token == null) {
      // ❌ 로그인 안 됨
      if (!mounted) return;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('로그인 필요'),
            ],
          ),
          content: const Text('포인트와 쿠폰 조회를 위해 로그인이 필요합니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('로그인하기'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (result == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        Navigator.pop(context);
      }
      return;
    }

    // ✅ 로그인 됨 → 데이터 로드
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 🔥 김부산 userNo = 231837269 (하드코딩)
    const userNo = 231837269;

    try {
      // 포인트 조회
      final pointsData = await _apiService.getUserPoints(userNo);
      setState(() {
        _totalPoints = pointsData['totalPoints'] ?? 0;
        _loadingPoints = false;
      });
    } catch (e) {
      setState(() => _loadingPoints = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('포인트 조회 실패: $e')),
        );
      }
    }

    try {
      // 쿠폰 조회
      final coupons = await _apiService.getUserCoupons(userNo);
      setState(() {
        _coupons = coupons;
        _loadingCoupons = false;
      });
    } catch (e) {
      setState(() => _loadingCoupons = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('쿠폰 조회 실패: $e')),
        );
      }
    }
  }

  void _onPointsChanged(String value) {
    final points = int.tryParse(value) ?? 0;
    if (points > _totalPoints) {
      _pointsCtrl.text = _totalPoints.toString();
      return;
    }
    setState(() {
      _usedPoints = points;
      _pointBonusRate = (points / 1000) * 0.1;
      _recalculateRate();
    });
  }

  void _onCouponSelected(int? couponId) {
    setState(() {
      _selectedCouponId = couponId;
      if (couponId == null) {
        _couponBonusRate = 0.0;
      } else {
        final coupon = _coupons.firstWhere((c) => c.couponId == couponId);
        _couponBonusRate = coupon.bonusRate;
      }
      _recalculateRate();
    });
  }

  void _recalculateRate() {
    setState(() {
      _finalRate = _baseRate + _pointBonusRate + _couponBonusRate;
    });
  }

  int _calculateInterest() {
    final amount = widget.request.principalAmount ?? 0;
    final months = widget.request.contractTerm ?? 0;
    final interest = (amount * (_finalRate / 100) * (months / 12)).toInt();
    return interest;
  }

  void _goNext() {
    final updated = widget.request.copyWith(
      usedPoints: _usedPoints,
      selectedCouponId: _selectedCouponId,
      applyRate: _finalRate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinStep4Screen(
          baseUrl: widget.baseUrl,
          request: updated,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 3/4 - 금리 우대'),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPointsSection(),
                  const SizedBox(height: 24),
                  _buildCouponsSection(),
                  const SizedBox(height: 24),
                  _buildRateSection(),
                  const SizedBox(height: 24),
                  _buildInterestSection(),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStep(1, true),
          _buildLine(true),
          _buildStep(2, true),
          _buildLine(true),
          _buildStep(3, true),
          _buildLine(false),
          _buildStep(4, false),
        ],
      ),
    );
  }

  Widget _buildStep(int step, bool active) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        color: active ? Theme.of(context).primaryColor : Colors.grey[300],
      ),
    );
  }

  Widget _buildPointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '포인트 사용',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '1,000점당 0.1% 금리 우대',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (_loadingPoints)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('보유 포인트'),
                    Text(
                      '${_totalPoints.toString()}P',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pointsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onPointsChanged,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: '사용할 포인트',
                  suffixText: 'P',
                  helperText: '최대 ${_totalPoints}P',
                ),
              ),
              if (_usedPoints > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '금리 우대: +${_pointBonusRate.toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildCouponsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '쿠폰 선택',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_loadingCoupons)
          const Center(child: CircularProgressIndicator())
        else if (_coupons.isEmpty)
          const Text(
            '사용 가능한 쿠폰이 없습니다.',
            style: TextStyle(color: Colors.grey),
          )
        else
          Column(
            children: _coupons.map((coupon) {
              final isSelected = _selectedCouponId == coupon.couponId;
              return GestureDetector(
                onTap: () => _onCouponSelected(
                  isSelected ? null : coupon.couponId,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected ? Colors.blue[50] : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon.couponName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '금리 +${coupon.bonusRate.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildRateSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildRateRow('기본 금리', _baseRate, Colors.black),
          if (_pointBonusRate > 0) ...[
            const Divider(),
            _buildRateRow('포인트 우대', _pointBonusRate, Colors.blue),
          ],
          if (_couponBonusRate > 0) ...[
            const Divider(),
            _buildRateRow('쿠폰 우대', _couponBonusRate, Colors.green),
          ],
          const Divider(thickness: 2),
          _buildRateRow(
            '최종 적용 금리',
            _finalRate,
            Colors.red,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow(String label, double rate, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${rate.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: bold ? 18 : 16,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestSection() {
    final interest = _calculateInterest();
    final amount = widget.request.principalAmount ?? 0;
    final total = amount + interest;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '예상 수익',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAmountRow('가입 금액', amount),
          const SizedBox(height: 8),
          _buildAmountRow('예상 이자', interest, color: Colors.blue),
          const Divider(),
          _buildAmountRow('만기 금액', total, bold: true),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, int amount,
      {Color? color, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${amount.toString().replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                (Match m) => '${m[1]},',
          )}원',
          style: TextStyle(
            fontSize: bold ? 18 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _goNext,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text(
            '다음 (STEP 4)',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}