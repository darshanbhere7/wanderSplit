import 'package:flutter/material.dart';
import '../services/expense_service.dart';
import '../models/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();
  
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, double> _categorySummary = {};
  double _totalExpenses = 0;
  
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, double> get categorySummary => _categorySummary;
  double get totalExpenses => _totalExpenses;

  // Initialize the expenses listener for a user
  void initExpenses(String userId) {
    _expenseService.getExpenses(userId).listen((expensesList) {
      _expenses = expensesList;
      notifyListeners();
      
      // Update summary data when expenses change
      _updateSummaryData(userId);
    });
  }
  
  // Update summary data
  Future<void> _updateSummaryData(String userId) async {
    try {
      _categorySummary = await _expenseService.getExpenseSummaryByCategory(userId);
      _totalExpenses = await _expenseService.getTotalExpenses(userId);
      notifyListeners();
    } catch (e) {
      print('Error updating summary data: $e');
    }
  }
  
  // Create a new expense
  Future<Expense?> createExpense({
    required String title,
    required double amount,
    required String category,
    String? description,
    required DateTime date,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final expense = Expense(
        title: title,
        amount: amount,
        category: category,
        description: description,
        date: date,
        userId: userId,
      );
      
      final createdExpense = await _expenseService.createExpense(expense);
      _isLoading = false;
      notifyListeners();
      return createdExpense;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // Get an expense by ID
  Future<Expense?> getExpenseById(String expenseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final expense = await _expenseService.getExpenseById(expenseId);
      _isLoading = false;
      notifyListeners();
      return expense;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // Update an expense
  Future<bool> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String category,
    String? description,
    required DateTime date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final existingExpense = await _expenseService.getExpenseById(id);
      
      if (existingExpense != null) {
        final updatedExpense = existingExpense.copyWith(
          title: title,
          amount: amount,
          category: category,
          description: description,
          date: date,
        );
        
        await _expenseService.updateExpense(updatedExpense);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Expense not found';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Delete an expense
  Future<bool> deleteExpense(String expenseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _expenseService.deleteExpense(expenseId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Get expenses for a specific time period
  Future<List<Expense>> getExpensesForPeriod(String userId, DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final allExpenses = await _expenseService.getExpenses(userId).first;
      final filteredExpenses = allExpenses.where((expense) {
        return expense.date.isAfter(startDate) && expense.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      _isLoading = false;
      notifyListeners();
      return filteredExpenses;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }
  
  // Get total expenses for a specific time period
  Future<double> getTotalForPeriod(String userId, DateTime startDate, DateTime endDate) async {
    try {
      return await _expenseService.getTotalExpenses(
        userId, 
        startDate: startDate, 
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return 0;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 