import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'expenses';

  // Create a new expense
  Future<Expense> createExpense(Expense expense) async {
    try {
      final docRef = await _firestore.collection(_collection).add(expense.toMap());
      return expense.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating expense: $e');
      rethrow;
    }
  }

  // Get all expenses for a specific user
  Stream<List<Expense>> getExpenses(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Expense.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get a specific expense by id
  Future<Expense?> getExpenseById(String expenseId) async {
    try {
      final docSnapshot = await _firestore.collection(_collection).doc(expenseId).get();
      
      if (docSnapshot.exists) {
        return Expense.fromMap(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
      }
      
      return null;
    } catch (e) {
      print('Error getting expense: $e');
      rethrow;
    }
  }

  // Update an expense
  Future<void> updateExpense(Expense expense) async {
    try {
      if (expense.id != null) {
        await _firestore.collection(_collection).doc(expense.id).update(expense.toMap());
      }
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection(_collection).doc(expenseId).delete();
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  // Get expense summary by category
  Future<Map<String, double>> getExpenseSummaryByCategory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();
      
      final Map<String, double> categorySummary = {};
      
      for (var doc in querySnapshot.docs) {
        final expense = Expense.fromMap(doc.data(), doc.id);
        final category = expense.category;
        final amount = expense.amount;
        
        if (categorySummary.containsKey(category)) {
          categorySummary[category] = categorySummary[category]! + amount;
        } else {
          categorySummary[category] = amount;
        }
      }
      
      return categorySummary;
    } catch (e) {
      print('Error getting expense summary: $e');
      rethrow;
    }
  }

  // Get total expenses for a time period
  Future<double> getTotalExpenses(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      Query query = _firestore.collection(_collection).where('userId', isEqualTo: userId);
      
      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: endDate.millisecondsSinceEpoch);
      }
      
      final querySnapshot = await query.get();
      
      double total = 0;
      for (var doc in querySnapshot.docs) {
        final expense = Expense.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        total += expense.amount;
      }
      
      return total;
    } catch (e) {
      print('Error calculating total expenses: $e');
      rethrow;
    }
  }
}