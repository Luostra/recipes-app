class Folder {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String emoji;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.emoji,
    required this.createdAt,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      emoji: json['emoji'] ?? '📁',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'emoji': emoji,
    };
  }

  Folder copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? emoji,
    DateTime? createdAt,
  }) {
    return Folder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
