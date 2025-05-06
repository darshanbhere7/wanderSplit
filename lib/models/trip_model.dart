import 'package:cloud_firestore/cloud_firestore.dart';

enum TripCategory {
  business,
  leisure,
  family,
  other
}

enum MemberRole {
  admin,
  member
}

class TripMember {
  final String userId; // can be UID or email
  final String name; // can be email if no name
  final MemberRole role;
  final double spendingLimit;
  final String email;

  TripMember({
    required this.userId,
    required this.name,
    required this.role,
    this.spendingLimit = 0.0,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role.toString(),
      'spendingLimit': spendingLimit,
      'email': email,
    };
  }

  factory TripMember.fromMap(Map<String, dynamic> map) {
    return TripMember(
      userId: map['userId'] ?? '',
      name: map['name'] ?? (map['email'] ?? ''),
      role: MemberRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => MemberRole.member,
      ),
      spendingLimit: (map['spendingLimit'] ?? 0.0).toDouble(),
      email: map['email'] ?? '',
    );
  }

  TripMember copyWith({
    String? userId,
    String? name,
    MemberRole? role,
    double? spendingLimit,
    String? email,
  }) {
    return TripMember(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      role: role ?? this.role,
      spendingLimit: spendingLimit ?? this.spendingLimit,
      email: email ?? this.email,
    );
  }
}

class TripModel {
  final String id;
  final String name;
  final String description;
  final TripCategory category;
  final double budget;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final String currency;
  final List<TripMember> members;
  final List<String> memberIds;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.budget,
    this.location,
    required this.startDate,
    this.endDate,
    required this.currency,
    required this.members,
    required this.memberIds,
    required this.createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TripModel.empty() {
    return TripModel(
      id: '',
      name: '',
      description: '',
      category: TripCategory.other,
      budget: 0.0,
      location: '',
      startDate: DateTime.now(),
      endDate: null,
      currency: 'INR',
      members: [],
      memberIds: [],
      createdBy: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toString(),
      'budget': budget,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'currency': currency,
      'members': members.map((member) => member.toMap()).toList(),
      'memberIds': memberIds,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: TripCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => TripCategory.other,
      ),
      budget: (map['budget'] ?? 0.0).toDouble(),
      location: map['location'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      currency: map['currency'] ?? 'INR',
      members: List<TripMember>.from(
        (map['members'] ?? []).map((x) => TripMember.fromMap(x)),
      ),
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  TripModel copyWith({
    String? id,
    String? name,
    String? description,
    TripCategory? category,
    double? budget,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    List<TripMember>? members,
    List<String>? memberIds,
    String? createdBy,
  }) {
    return TripModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currency: currency ?? this.currency,
      members: members ?? this.members,
      memberIds: memberIds ?? this.memberIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool isMember(String userId) {
    return members.any((member) => member.userId == userId);
  }

  bool isAdmin(String userId) {
    return members.any((member) => 
      member.userId == userId && member.role == MemberRole.admin);
  }

  TripMember? getMember(String userId) {
    try {
      return members.firstWhere((member) => member.userId == userId);
    } catch (e) {
      return null;
    }
  }
} 