import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';
import '../models/settlement_model.dart';

class TripProvider with ChangeNotifier {
  final String tripId;
  TripModel? _trip;
  List<ExpenseModel> _expenses = [];
  List<SettlementModel> _settlements = [];
  bool _isLoading = false;

  TripProvider(this.tripId) {
    _loadTripData();
  }

  TripModel? get trip => _trip;
  List<ExpenseModel> get expenses => _expenses;
  List<SettlementModel> get settlements => _settlements;
  bool get isLoading => _isLoading;

  Future<void> _loadTripData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load trip data
      final tripDoc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(tripId)
          .get();
      
      if (tripDoc.exists) {
        _trip = TripModel.fromMap(tripDoc.data()!);
      }

      // Load expenses
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('tripId', isEqualTo: tripId)
          .get();

      _expenses = expensesSnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data()))
          .toList();

      // Load settlements
      final settlementsSnapshot = await FirebaseFirestore.instance
          .collection('settlements')
          .where('tripId', isEqualTo: tripId)
          .get();

      _settlements = settlementsSnapshot.docs
          .map((doc) => SettlementModel.fromMap(doc.data()))
          .toList();

    } catch (e) {
      debugPrint('Error loading trip data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Expense calculations
  double get totalExpenses => _expenses.fold(0, (sum, expense) => sum + expense.amount);

  Map<ExpenseCategory, double> get categoryTotals {
    final Map<ExpenseCategory, double> totals = {};
    for (var expense in _expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }
    return totals;
  }

  Map<String, double> get memberTotals {
    final Map<String, double> totals = {};
    for (var expense in _expenses) {
      for (var split in expense.splits) {
        totals[split.userId] = (totals[split.userId] ?? 0) + split.amount;
      }
    }
    return totals;
  }

  List<Map<String, dynamic>> get expenseTrends {
    final Map<DateTime, double> dailyTotals = {};
    for (var expense in _expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      dailyTotals[date] = (dailyTotals[date] ?? 0) + expense.amount;
    }

    return dailyTotals.entries
        .map((entry) => {
              'date': entry.key,
              'amount': entry.value,
            })
        .toList()
      ..sort((a, b) => a['date'].compareTo(b['date']));
  }

  // Settlement calculations
  List<SettlementModel> calculateSettlements() {
    final Map<String, double> balances = {};
    
    // Calculate initial balances
    for (var expense in _expenses) {
      // Add amount to payer's balance
      balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) + expense.amount;
      
      // Subtract split amounts from each member's balance
      for (var split in expense.splits) {
        balances[split.userId] = (balances[split.userId] ?? 0) - split.amount;
      }
    }

    // Calculate settlements
    final List<SettlementModel> settlements = [];
    final debtors = balances.entries.where((e) => e.value < 0).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final creditors = balances.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var debtor in debtors) {
      double remainingDebt = -debtor.value;
      
      for (var creditor in creditors) {
        if (remainingDebt <= 0 || creditor.value <= 0) break;
        
        final settlementAmount = remainingDebt < creditor.value
            ? remainingDebt
            : creditor.value;
        
        settlements.add(
          SettlementModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            tripId: tripId,
            fromUserId: debtor.key,
            toUserId: creditor.key,
            fromUserName: _getMemberName(debtor.key),
            toUserName: _getMemberName(creditor.key),
            amount: settlementAmount,
            currency: _trip?.currency ?? 'USD',
            status: SettlementStatus.pending,
            dueDate: DateTime.now().add(const Duration(days: 7)),
          ),
        );
        
        remainingDebt -= settlementAmount;
        creditor.value -= settlementAmount;
      }
    }

    return settlements;
  }

  String _getMemberName(String userId) {
    return _trip?.members.firstWhere(
          (member) => member.userId == userId,
          orElse: () => TripMember(userId: userId, name: 'Unknown'),
        ).name ??
        'Unknown';
  }

  // CRUD operations
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());
      
      _expenses.add(expense);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expense.id)
          .update(expense.toMap());
      
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expenseId)
          .delete();
      
      _expenses.removeWhere((e) => e.id == expenseId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  Future<void> updateSettlement(SettlementModel settlement) async {
    try {
      await FirebaseFirestore.instance
          .collection('settlements')
          .doc(settlement.id)
          .update(settlement.toMap());
      
      final index = _settlements.indexWhere((s) => s.id == settlement.id);
      if (index != -1) {
        _settlements[index] = settlement;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating settlement: $e');
      rethrow;
    }
  }
} 