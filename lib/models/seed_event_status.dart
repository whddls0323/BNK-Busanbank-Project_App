enum SeedResult { none, success, fail }
enum SeedUIState {
  success,
  waiting,
  failedCanRetry,
  canPlant,
}
class SeedEventStatus  {
  final String todayStatus; // NONE / WAIT / SUCCESS / FAIL
  final String pastStatus;
  final double? minPrice;
  final double? maxPrice;
  final double todayPrice;
  final double? errorRate;
  final double? errorAmount;

  SeedEventStatus ({
    required this.todayStatus,
    required this.pastStatus,
    required this.todayPrice,
    this.minPrice,
    this.maxPrice,
    this.errorRate,
    this.errorAmount,
  });

  factory SeedEventStatus.fromJson(Map<String, dynamic> json) {
    return SeedEventStatus (
      todayStatus: json['todayStatus'],
      pastStatus: json['pastStatus'],
      todayPrice: (json['todayPrice'] as num).toDouble(),
      minPrice: json['minPrice'] != null ? (json['minPrice'] as num).toDouble() : null,
      maxPrice: json['maxPrice'] != null ? (json['maxPrice'] as num).toDouble() : null,
      errorRate: json['errorRate'] != null ? (json['errorRate'] as num).toDouble() : null,
      errorAmount: json['errorAmount'] != null ? (json['errorAmount'] as num).toDouble() : null,
    );
  }

  SeedResult get todayResult {
    switch (todayStatus) {
      case 'SUCCESS':
        return SeedResult.success;
      case 'FAIL':
        return SeedResult.fail;
      default:
        return SeedResult.none;
    }
  }

  SeedResult get pastResult {
    switch (pastStatus) {
      case 'SUCCESS':
        return SeedResult.success;
      case 'FAIL':
        return SeedResult.fail;
      default:
        return SeedResult.none;
    }
  }

  SeedUIState get uiState {
    // 🎉 성공 (오늘이든 과거든)
    if (todayResult == SeedResult.success ||
        pastResult == SeedResult.success) {
      return SeedUIState.success;
    }

    // ⏳ 결과 대기
    if (todayStatus == 'WAIT' || pastStatus == 'WAIT') {
      return SeedUIState.waiting;
    }

    // ❌ 실패 (오늘 실패 or 과거 실패)
    if (todayResult == SeedResult.fail ||
        pastResult == SeedResult.fail) {
      return SeedUIState.failedCanRetry;
    }

    // 🌱 아직 참여 안 함
    return SeedUIState.canPlant;
  }



}
