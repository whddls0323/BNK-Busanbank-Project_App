// 2025/12/22 - ESG 낚시 게임 쓰레기 모델 - 작성자: 진원

class Trash {
  final String id;
  final String name;
  final String type;
  final int points;
  final String emoji;
  final String description;

  Trash({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    required this.emoji,
    required this.description,
  });

  // JSON에서 Trash 객체 생성
  factory Trash.fromJson(Map<String, dynamic> json) {
    return Trash(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      points: json['points'] as int? ?? 0,
      emoji: json['emoji']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  // Trash 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'points': points,
      'emoji': emoji,
      'description': description,
    };
  }
}
