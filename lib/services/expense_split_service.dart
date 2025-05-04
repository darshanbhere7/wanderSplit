import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_split_model.dart';

class ExpenseSplitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'expense_splits';

  // Create a new expense split
  Future<ExpenseSplit> createExpenseSplit(ExpenseSplit split) async {
    try {
      final docRef = await _firestore.collection(_collection).add(split.toMap());
      return split;
    } catch (e) {
      print('Error creating expense split: $e');
      rethrow;
    }
  }

  // Get all splits for a specific trip
  Stream<List<ExpenseSplit>> getSplitsForTrip(String tripId) {
    return _firestore
        .collection(_collection)
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ExpenseSplit.fromMap(doc.data());
          }).toList();
        });
  }

  // Get splits for a specific expense
  Future<ExpenseSplit?> getSplitForExpense(String expenseId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('expenseId', isEqualTo: expenseId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return ExpenseSplit.fromMap(querySnapshot.docs.first.data());
      }
      
      return null;
    } catch (e) {
      print('Error getting expense split: $e');
      rethrow;
    }
  }

  // Update an expense split
  Future<void> updateExpenseSplit(ExpenseSplit split) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('expenseId', isEqualTo: split.expenseId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update(split.toMap());
      }
    } catch (e) {
      print('Error updating expense split: $e');
      rethrow;
    }
  }

  // Get the balance for a specific user in a trip
  Future<double> getUserBalance(String tripId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tripId', isEqualTo: tripId)
          .get();
      
      double balance = 0.0;
      
      for (var doc in querySnapshot.docs) {
        final split = ExpenseSplit.fromMap(doc.data());
        balance += split.getNetAmountForUser(userId);
      }
      
      return balance;
    } catch (e) {
      print('Error getting user balance: $e');
      rethrow;
    }
  }

  // Get all balances for a trip
  Future<Map<String, double>> getAllBalances(String tripId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('tripId', isEqualTo: tripId)
          .get();
      
      final Map<String, double> balances = {};
      
      for (var doc in querySnapshot.docs) {
        final split = ExpenseSplit.fromMap(doc.data());
        
        split.splits.forEach((userId, amount) {
          balances[userId] = (balances[userId] ?? 0.0) + amount;
        });
      }
      
      return balances;
    } catch (e) {
      print('Error getting all balances: $e');
      rethrow;
    }
  }

  // Mark a split as settled for a specific user
  Future<void> markSplitAsSettled(String expenseId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('expenseId', isEqualTo: expenseId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final split = ExpenseSplit.fromMap(querySnapshot.docs.first.data());
        final updatedSplit = split.markSplitAsSettled(userId);
        await querySnapshot.docs.first.reference.update(updatedSplit.toMap());
      }
    } catch (e) {
      print('Error marking split as settled: $e');
      rethrow;
    }
  }
} 