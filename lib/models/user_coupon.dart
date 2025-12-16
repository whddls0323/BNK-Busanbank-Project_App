class UserCoupon {
  final int ucNo;  // ✅ 이게 있어야!
  final int userNo;
  final int couponId;
  final String couponName;
  final double bonusRate;
  final String status;
  final String? receivedAt;
  final String? usedAt;
  final String? expiryDate;

  UserCoupon({
    required this.ucNo,  // ✅ 필수!
    required this.userNo,
    required this.couponId,
    required this.couponName,
    required this.bonusRate,
    required this.status,
    this.receivedAt,
    this.usedAt,
    this.expiryDate,
  });

  factory UserCoupon.fromJson(Map<String, dynamic> json) {
    return UserCoupon(
      ucNo: json['ucNo'] ?? 0,  // ✅ Backend에서 ucNo로 받음!
      userNo: json['userNo'] ?? 0,
      couponId: json['couponId'] ?? 0,
      couponName: json['couponName'] ?? '',
      bonusRate: (json['bonusRate'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      receivedAt: json['receivedAt'],
      usedAt: json['usedAt'],
      expiryDate: json['expiryDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ucNo': ucNo,
      'userNo': userNo,
      'couponId': couponId,
      'couponName': couponName,
      'bonusRate': bonusRate,
      'status': status,
      'receivedAt': receivedAt,
      'usedAt': usedAt,
      'expiryDate': expiryDate,
    };
  }
}