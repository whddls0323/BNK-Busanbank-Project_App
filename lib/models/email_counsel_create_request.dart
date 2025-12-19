class EmailCounselCreateRequest {
  final String csCategory;
  final String title;
  final String content;
  final String contactEmail;

  EmailCounselCreateRequest({
    required this.csCategory,
    required this.title,
    required this.content,
    required this.contactEmail,
  });

  Map<String, dynamic> toJson() => {
    "csCategory": csCategory,
    "title": title,
    "content": content,
    "contactEmail": contactEmail,
  };
}

