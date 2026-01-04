// 2025/12/29 - 계좌 모델 클래스 - 작성자: 진원
// 2026/01/04 - 상품명 필드 추가 - 작성자: 진원
class Account {
  final String accountNo;
  final int userId;
  final int balance;
  final String? accountType;
  final String? createdAt;
  final String? productName; // 상품명

  Account({
    required this.accountNo,
    required this.userId,
    required this.balance,
    this.accountType,
    this.createdAt,
    this.productName,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountNo: json['accountNo'] ?? '',
      userId: json['userId'] ?? 0,
      balance: json['balance'] ?? 0,
      accountType: json['accountType'],
      createdAt: json['createdAt'],
      productName: json['productName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountNo': accountNo,
      'userId': userId,
      'balance': balance,
      'accountType': accountType,
      'createdAt': createdAt,
      'productName': productName,
    };
  }
}
