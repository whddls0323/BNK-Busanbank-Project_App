class SeedPlantResult {
  final bool already;
  final double? minPrice;
  final double? maxPrice;
  final double? todayPrice;
  final double? errorRate;

  SeedPlantResult({
    required this.already,
    this.minPrice,
    this.maxPrice,
    this.todayPrice,
    this.errorRate,
  });

  factory SeedPlantResult.fromJson(Map<String, dynamic> json) {
    return SeedPlantResult(
      already: json['already'] as bool,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      todayPrice: (json['todayPrice'] as num?)?.toDouble(),
      errorRate: (json['errorRate'] as num?)?.toDouble(),
    );
  }
}
