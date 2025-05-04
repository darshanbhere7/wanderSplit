import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String? id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants;
  final double totalExpenses;
  final String createdBy;
  final DateTime createdAt;
  final String currency;

  Trip({
    this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.participants,
    this.totalExpenses = 0.0,
    required this.createdBy,
    required this.createdAt,
    this.currency = 'INR',
  });

  factory Trip.fromMap(Map<String, dynamic> map, String id) {
    return Trip(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      participants: List<String>.from(map['participants'] ?? []),
      totalExpenses: (map['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      currency: map['currency'] ?? 'INR',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participants': participants,
      'totalExpenses': totalExpenses,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'currency': currency,
    };
  }

  Trip copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? participants,
    double? totalExpenses,
    String? createdBy,
    DateTime? createdAt,
    String? currency,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participants: participants ?? this.participants,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      currency: currency ?? this.currency,
    );
  }
} 