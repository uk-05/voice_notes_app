class Note {
  final int? id;
  final int userId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert a Note into a Map for sqflite. Keys must match column names.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Note copyWith({
    int? id,
    int? userId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
