class CodeDetail {
  final String groupCode;
  final String code;
  final String codeName;

  CodeDetail({
    required this.groupCode,
    required this.code,
    required this.codeName,
  });

  factory CodeDetail.fromJson(Map<String, dynamic> json) {
    return CodeDetail(
      groupCode: (json['groupCode'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      codeName: (json['codeName'] ?? '').toString(),
    );
  }
}
