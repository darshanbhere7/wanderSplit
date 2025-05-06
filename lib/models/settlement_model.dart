import 'package:cloud_firestore/cloud_firestore.dart';

enum SettlementStatus {
  pending,
  paid,
  cancelled
}

enum PaymentMethod {
  cash,
  bankTransfer,
  paypal,
  venmo,
  other,
}

class SettlementModel {
  final String id;
  final String tripId;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String toUserName;
  final double amount;
  final String currency;
  final SettlementStatus status;
  final PaymentMethod? paymentMethod;
  final String? paymentReference;
  final String? notes;
  final DateTime dueDate;
  final DateTime? settledDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  SettlementModel({
    required this.id,
    required this.tripId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.toUserName,
    required this.amount,
    required this.currency,
    required this.status,
    this.paymentMethod,
    this.paymentReference,
    this.notes,
    required this.dueDate,
    this.settledDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'amount': amount,
      'currency': currency,
      'status': status.toString(),
      'paymentMethod': paymentMethod?.toString(),
      'paymentReference': paymentReference,
      'notes': notes,
      'dueDate': Timestamp.fromDate(dueDate),
      'settledDate': settledDate != null ? Timestamp.fromDate(settledDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SettlementModel.fromMap(Map<String, dynamic> map) {
    return SettlementModel(
      id: map['id'] ?? '',
      tripId: map['tripId'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      toUserId: map['toUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      toUserName: map['toUserName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? '',
      status: SettlementStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => SettlementStatus.pending,
      ),
      paymentMethod: map['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.toString() == map['paymentMethod'],
              orElse: () => PaymentMethod.other,
            )
          : null,
      paymentReference: map['paymentReference'],
      notes: map['notes'],
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      settledDate: map['settledDate'] != null
          ? (map['settledDate'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  SettlementModel copyWith({
    String? id,
    String? tripId,
    String? fromUserId,
    String? toUserId,
    double? amount,
    SettlementStatus? status,
    String? currency,
    PaymentMethod? paymentMethod,
    String? paymentReference,
    String? notes,
    DateTime? dueDate,
    DateTime? settledDate,
  }) {
    return SettlementModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName,
      toUserName: toUserName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      settledDate: settledDate ?? this.settledDate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 