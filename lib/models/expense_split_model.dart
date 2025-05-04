class ExpenseSplit {
  final String expenseId;
  final String tripId;
  final String paidBy;
  final double totalAmount;
  final Map<String, double> splits; // Map of userId to amount owed
  final bool isSettled;
  final DateTime? settledAt;

  ExpenseSplit({
    required this.expenseId,
    required this.tripId,
    required this.paidBy,
    required this.totalAmount,
    required this.splits,
    this.isSettled = false,
    this.settledAt,
  });

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      expenseId: map['expenseId'] ?? '',
      tripId: map['tripId'] ?? '',
      paidBy: map['paidBy'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      splits: Map<String, double>.from(map['splits'] ?? {}),
      isSettled: map['isSettled'] ?? false,
      settledAt: map['settledAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['settledAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'tripId': tripId,
      'paidBy': paidBy,
      'totalAmount': totalAmount,
      'splits': splits,
      'isSettled': isSettled,
      'settledAt': settledAt?.millisecondsSinceEpoch,
    };
  }

  // Calculate how much each person owes
  Map<String, double> calculateSplits(List<String> participants) {
    final double perPersonAmount = totalAmount / participants.length;
    final Map<String, double> newSplits = {};
    
    for (final participant in participants) {
      if (participant == paidBy) {
        // The person who paid gets credit for the full amount
        newSplits[participant] = totalAmount;
      } else {
        // Others owe their share
        newSplits[participant] = -perPersonAmount;
      }
    }
    
    return newSplits;
  }

  // Get the net amount for a specific user
  double getNetAmountForUser(String userId) {
    return splits[userId] ?? 0.0;
  }

  // Check if the expense is fully settled
  bool isFullySettled() {
    return isSettled && splits.values.every((amount) => amount == 0);
  }

  // Mark a specific split as settled
  ExpenseSplit markSplitAsSettled(String userId) {
    final updatedSplits = Map<String, double>.from(splits);
    updatedSplits[userId] = 0.0;
    
    return ExpenseSplit(
      expenseId: expenseId,
      tripId: tripId,
      paidBy: paidBy,
      totalAmount: totalAmount,
      splits: updatedSplits,
      isSettled: updatedSplits.values.every((amount) => amount == 0),
      settledAt: updatedSplits.values.every((amount) => amount == 0) 
          ? DateTime.now() 
          : settledAt,
    );
  }
} 