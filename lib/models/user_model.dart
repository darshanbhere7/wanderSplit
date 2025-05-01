class UserModel {
  final String? id;
  final String email;
  final String displayName;

  UserModel({
    this.id,
    required this.email,
    required this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
    );
  }
} 