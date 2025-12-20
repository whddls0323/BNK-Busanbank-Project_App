// lib/model/product_terms.dart

class ProductTerms {
  final int termId;
  final int productNo;
  final String termType;      // ✅ 추가! (ESSENTIAL/OPTIONAL)
  final String termTitle;
  final String termContent;
  final bool isRequired;      // ✅ 유지 (termType == 'ESSENTIAL')

  ProductTerms({
    required this.termId,
    required this.productNo,
    required this.termType,   // ✅ 추가!
    required this.termTitle,
    required this.termContent,
    required this.isRequired,
  });

  factory ProductTerms.fromJson(Map<String, dynamic> json) {
    // ✅ termType으로 isRequired 판단
    final termType = json['termType'] as String? ?? '';
    final isRequired = termType.toUpperCase() == 'ESSENTIAL' ||
        json['isRequired'] == 1 ||
        json['isRequired'] == true;

    return ProductTerms(
      termId: json['termId'] ?? 0,
      productNo: json['productNo'] ?? 0,
      termType: termType,         // ✅ 추가!
      termTitle: json['termTitle'] ?? '',
      termContent: json['termContent'] ?? '',
      isRequired: isRequired,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'termId': termId,
      'productNo': productNo,
      'termType': termType,       // ✅ 추가!
      'termTitle': termTitle,
      'termContent': termContent,
      'isRequired': isRequired,
    };
  }
}