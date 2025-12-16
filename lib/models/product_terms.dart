// lib/model/product_terms.dart

class ProductTerms {
  final int termId;
  final int productNo;
  final String termTitle;
  final String termContent;
  final bool isRequired;

  ProductTerms({
    required this.termId,
    required this.productNo,
    required this.termTitle,
    required this.termContent,
    required this.isRequired,
  });

  factory ProductTerms.fromJson(Map<String, dynamic> json) {
    return ProductTerms(
      termId: json['termId'] ?? 0,
      productNo: json['productNo'] ?? 0,
      termTitle: json['termTitle'] ?? '',
      termContent: json['termContent'] ?? '',
      isRequired: json['isRequired'] == 1 || json['isRequired'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'termsId': termId,
      'productNo': productNo,
      'termsTitle': termTitle,
      'termsContent': termContent,
      'isRequired': isRequired,
    };
  }
}