import 'code_detail.dart';

class EmailCounselFormData {
  final String userName;
  final String hp;
  final String email;
  final List<CodeDetail> categories;

  EmailCounselFormData({
    required this.userName,
    required this.hp,
    required this.email,
    required this.categories,
  });

  factory EmailCounselFormData.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['categories'] as List?) ?? const [];
    final categories = rawCategories
        .whereType<Map>()
        .map((e) => CodeDetail.fromJson(e.cast<String, dynamic>()))
        .toList();

    return EmailCounselFormData(
      userName: (json['userName'] ?? '').toString(),
      hp: (json['hp'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      categories: categories,
    );
  }
}
