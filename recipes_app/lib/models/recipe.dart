class Recipe {
  final String id;
  final String folderId;
  final String title;
  final String content;
  final bool isFavour;
  final String imagePath;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.folderId,
    required this.title,
    required this.content,
    required this.isFavour,
    required this.imagePath,
    required this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      folderId: json['folder_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      isFavour: json['is_favour'] ?? false,
      imagePath: json['image_path'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folder_id': folderId,
      'title': title,
      'content': content,
      'is_favour': isFavour,
      'image_path': imagePath,
    };
  }

  Recipe copyWith({
    String? id,
    String? folderId,
    String? title,
    String? content,
    bool? isFavour,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      isFavour: isFavour ?? this.isFavour,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
