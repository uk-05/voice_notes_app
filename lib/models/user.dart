class AppUser {
  final int? id;
  final String name;
  final String email;
  final String passwordHash;
  final bool isVerified;
  final DateTime createdAt;

  AppUser({
    this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.isVerified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'isVerified': isVerified ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['passwordHash'] as String,
      isVerified: (map['isVerified'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? passwordHash,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
