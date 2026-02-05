class EmailCounselItem {
  final int ecounselId;
  final String csCategory;
  final String? csCategoryName;
  final String title;
  final String content;
  final String status;
  final String? createdAt;
  final String? response;

  EmailCounselItem({
    required this.ecounselId,
    required this.csCategory,
    required this.title,
    required this.content,
    required this.status,
    this.csCategoryName,
    this.createdAt,
    this.response,
  });

  factory EmailCounselItem.fromJson(Map<String, dynamic> json) {
    return EmailCounselItem(
      ecounselId: (json['ecounselId'] as num?)?.toInt() ?? 0,
      csCategory: (json['csCategory'] ?? '').toString(),
      csCategoryName: json['csCategoryName']?.toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: json['createdAt']?.toString(),
      response: json['response']?.toString(),
    );
  }
}
