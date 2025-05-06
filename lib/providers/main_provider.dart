import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' show min;
import '../models/trip_model.dart';
import '../models/expense_model.dart';
import '../models/settlement_model.dart';

class MainProvider with ChangeNotifier {
  final String userId;
  List<TripModel> _trips = [];
  Map<String, List<ExpenseModel>> _tripExpenses = {};
  Map<String, List<SettlementModel>> _tripSettlements = {};
  bool _isLoading = false;
  String? _error;

  MainProvider(this.userId) {
    _loadUserData();
  }

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ExpenseModel> getExpensesForTrip(String tripId) => _tripExpenses[tripId] ?? [];
  List<SettlementModel> getSettlementsForTrip(String tripId) => _tripSettlements[tripId] ?? [];

  Future<void> _loadUserData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email ?? '';
      // Load trips where user is a member (by email)
      final tripsSnapshot = await FirebaseFirestore.instance
          .collection('trips')
          .where('memberIds', arrayContains: userEmail)
          .get();
      _trips = tripsSnapshot.docs
          .map((doc) => TripModel.fromMap(doc.data()))
          .where((trip) => trip.memberIds.contains(userEmail))
          .toList();
      // Load expenses and settlements for each trip
      for (var trip in _trips) {
        await _loadTripData(trip.id);
      }
    } catch (e) {
      _error = 'Error loading user data: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTripData(String tripId) async {
    try {
      // Load expenses
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('tripId', isEqualTo: tripId)
          .get();
      _tripExpenses[tripId] = expensesSnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data()))
          .toList();
      // Load settlements
      final settlementsSnapshot = await FirebaseFirestore.instance
          .collection('settlements')
          .where('tripId', isEqualTo: tripId)
          .get();
      _tripSettlements[tripId] = settlementsSnapshot.docs
          .map((doc) => SettlementModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading trip data: $e');
    }
  }

  Future<void> addTrip(TripModel trip) async {
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(trip.id)
          .set(trip.toMap());
      // Reload user data to ensure everything is up to date
      await _loadUserData();
    } catch (e) {
      _error = 'Error adding trip: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMemberToTrip(String tripId, String memberEmail) async {
    try {
      // Find user by email
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: memberEmail)
          .get();
      if (userQuery.docs.isEmpty) {
        throw Exception('User not found');
      }
      final userData = userQuery.docs.first.data();
      final member = TripMember(
        userId: userData['uid'] ?? memberEmail,
        name: userData['name'] ?? memberEmail,
        role: MemberRole.member,
        email: userData['email'] ?? memberEmail,
      );
      // Update trip in Firestore
      final tripRef = FirebaseFirestore.instance.collection('trips').doc(tripId);
      await tripRef.update({
        'members': FieldValue.arrayUnion([member.toMap()]),
        'memberIds': FieldValue.arrayUnion([member.userId]),
      });
      // Reload user data
      await _loadUserData();
    } catch (e) {
      _error = 'Error adding member: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());
      await _loadTripData(expense.tripId);
      notifyListeners();
      await _calculateSettlements(expense.tripId);
    } catch (e) {
      _error = 'Error adding expense: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expense.id)
          .update(expense.toMap());
      await _loadTripData(expense.tripId);
      notifyListeners();
      await _calculateSettlements(expense.tripId);
    } catch (e) {
      _error = 'Error updating expense: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(expenseId)
          .delete();
      await _loadTripData(tripId);
      notifyListeners();
      await _calculateSettlements(tripId);
    } catch (e) {
      _error = 'Error deleting expense: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSettlement(SettlementModel settlement) async {
    try {
      await FirebaseFirestore.instance
          .collection('settlements')
          .doc(settlement.id)
          .update(settlement.toMap());
      await _loadTripData(settlement.tripId);
      notifyListeners();
    } catch (e) {
      _error = 'Error updating settlement: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _calculateSettlements(String tripId) async {
    try {
      final expenses = _tripExpenses[tripId] ?? [];
      final trip = _trips.firstWhere((t) => t.id == tripId, orElse: () => TripModel.empty());
      if (trip.id.isEmpty) return;
      Map<String, double> memberTotals = {};
      for (var member in trip.members) {
        memberTotals[member.userId] = 0.0;
      }
      for (var expense in expenses) {
        memberTotals[expense.paidBy] = (memberTotals[expense.paidBy] ?? 0.0) + expense.amount;
        for (var split in expense.splits) {
          memberTotals[split.userId] = (memberTotals[split.userId] ?? 0.0) - split.amount;
        }
      }
      List<SettlementModel> settlements = [];
      var members = trip.members.toList();
      while (members.length > 1) {
        var maxPaid = members.reduce((a, b) => (memberTotals[a.userId] ?? 0.0) > (memberTotals[b.userId] ?? 0.0) ? a : b);
        var minPaid = members.reduce((a, b) => (memberTotals[a.userId] ?? 0.0) < (memberTotals[b.userId] ?? 0.0) ? a : b);
        if ((memberTotals[maxPaid.userId] ?? 0.0) <= 0 || (memberTotals[minPaid.userId] ?? 0.0) >= 0) {
          break;
        }
        double amount = min((memberTotals[maxPaid.userId] ?? 0.0).abs(), (memberTotals[minPaid.userId] ?? 0.0).abs());
        final settlement = SettlementModel(
          id: const Uuid().v4(),
          tripId: tripId,
          fromUserId: minPaid.userId,
          toUserId: maxPaid.userId,
          fromUserName: minPaid.name,
          toUserName: maxPaid.name,
          amount: amount,
          currency: trip.currency,
          status: SettlementStatus.pending,
          dueDate: DateTime.now().add(const Duration(days: 7)),
        );
        memberTotals[maxPaid.userId] = (memberTotals[maxPaid.userId] ?? 0.0) - amount;
        memberTotals[minPaid.userId] = (memberTotals[minPaid.userId] ?? 0.0) + amount;
        settlements.add(settlement);
        if ((memberTotals[maxPaid.userId] ?? 0.0).abs() < 0.01) {
          members.remove(maxPaid);
        }
        if ((memberTotals[minPaid.userId] ?? 0.0).abs() < 0.01) {
          members.remove(minPaid);
        }
      }
      final batch = FirebaseFirestore.instance.batch();
      for (var settlement in settlements) {
        final docRef = FirebaseFirestore.instance
            .collection('settlements')
            .doc(settlement.id);
        batch.set(docRef, settlement.toMap());
      }
      await batch.commit();
      _tripSettlements[tripId] = settlements;
      notifyListeners();
    } catch (e) {
      _error = 'Error calculating settlements: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  // Analytics methods
  double getTotalExpensesForTrip(String tripId) {
    final expenses = _tripExpenses[tripId] ?? [];
    return expenses.fold(0.0, (sum, expense) => sum + (expense.amount ?? 0.0));
  }

  Map<ExpenseCategory, double> getCategoryTotalsForTrip(String tripId) {
    final Map<ExpenseCategory, double> totals = {};
    for (var expense in _tripExpenses[tripId] ?? []) {
      totals[expense.category] = (totals[expense.category] ?? 0.0) + (expense.amount ?? 0.0);
    }
    return totals;
  }

  Map<String, double> getMemberTotalsForTrip(String tripId) {
    final Map<String, double> totals = {};
    for (var expense in _tripExpenses[tripId] ?? []) {
      for (var split in expense.splits) {
        totals[split.userId] = (totals[split.userId] ?? 0.0) + (split.amount ?? 0.0);
      }
    }
    return totals;
  }

  List<Map<String, dynamic>> getExpenseTrendsForTrip(String tripId) {
    final Map<DateTime, double> dailyTotals = {};
    for (var expense in _tripExpenses[tripId] ?? []) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      dailyTotals[date] = (dailyTotals[date] ?? 0.0) + (expense.amount ?? 0.0);
    }
    return dailyTotals.entries
        .map((entry) => {
              'date': entry.key,
              'amount': entry.value,
            })
        .toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }
} 