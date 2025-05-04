class Expense {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final String userId;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    required this.userId,
  });

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'Other',
      description: map['description'],
      date: map['date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['date']) 
          : DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? userId,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      userId: userId ?? this.userId,
    );
  }
} 