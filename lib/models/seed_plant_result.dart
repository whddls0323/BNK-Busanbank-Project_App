class SeedPlantResult {
  final bool already;
  final double? min;
  final double? max;
  final double? hiddenGold;
  final double? iceThickness;

  SeedPlantResult({
    required this.already,
    this.min,
    this.max,
    this.hiddenGold,
    this.iceThickness,
  });

  factory SeedPlantResult.fromJson(Map<String, dynamic> json) {
    return SeedPlantResult(
      already: json['already'],
      min: json['min'] != null ? (json['min'] as num).toDouble() : null,
      max: json['max'] != null ? (json['max'] as num).toDouble() : null,
      hiddenGold: json['todayPrice'] != null ? (json['todayPrice'] as num).toDouble() : null,
      iceThickness: json['errorRate'] != null ? (json['errorRate'] as num).toDouble() : null,
    );
  }
}
