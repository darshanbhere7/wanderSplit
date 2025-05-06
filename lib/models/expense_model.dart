import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory {
  food,
  transport,
  accommodation,
  activities,
  shopping,
  other
}

class ExpenseSplit {
  final String userId;
  final double amount;

  ExpenseSplit({
    required this.userId,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}

class ExpenseModel {
  final String id;
  final String tripId;
  final String title;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final String paidBy;
  final DateTime date;
  final bool isRecurring;
  final String? recurringFrequency;
  final List<String> tags;
  final List<String> receiptUrls;
  final List<ExpenseSplit> splits;
  final String currency;

  ExpenseModel({
    required this.id,
    required this.tripId,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.date,
    required this.isRecurring,
    this.recurringFrequency,
    required this.tags,
    required this.receiptUrls,
    required this.splits,
    required this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category.toString(),
      'paidBy': paidBy,
      'date': Timestamp.fromDate(date),
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'tags': tags,
      'receiptUrls': receiptUrls,
      'splits': splits.map((split) => split.toMap()).toList(),
      'currency': currency,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      tripId: map['tripId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      paidBy: map['paidBy'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      isRecurring: map['isRecurring'] ?? false,
      recurringFrequency: map['recurringFrequency'],
      tags: List<String>.from(map['tags'] ?? []),
      receiptUrls: List<String>.from(map['receiptUrls'] ?? []),
      splits: List<ExpenseSplit>.from(
        (map['splits'] ?? []).map((x) => ExpenseSplit.fromMap(x)),
      ),
      currency: map['currency'] ?? 'INR',
    );
  }
} 