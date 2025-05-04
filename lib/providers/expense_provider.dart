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
  bool _isInitialized = false;
  
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, double> get categorySummary => _categorySummary;
  double get totalExpenses => _totalExpenses;
  bool get isInitialized => _isInitialized;

  // Initialize the expenses listener for a user
  void initExpenses(String userId) {
    _isLoading = true;
    notifyListeners();
    
    print('Initializing expenses for user: $userId');
    
    // Manually fetch expenses first to ensure we have data
    _expenseService.getExpenses(userId).first.then((initialExpenses) {
      print('Initial expenses fetched: ${initialExpenses.length}');
      _expenses = initialExpenses;
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      
      // Update summary data
      _updateSummaryData(userId);
    }).catchError((error) {
      print('Error fetching initial expenses: $error');
      _isLoading = false;
      _errorMessage = error.toString();
      notifyListeners();
    });
    
    // Set up the stream for real-time updates
    _expenseService.getExpenses(userId).listen((expensesList) {
      print('Expenses stream update received: ${expensesList.length}');
      _expenses = expensesList;
      _isInitialized = true;
      notifyListeners();
      
      // Update summary data when expenses change
      _updateSummaryData(userId);
    }, onError: (error) {
      print('Error in expenses stream: $error');
      _errorMessage = error.toString();
      notifyListeners();
    });
  }
  
  // Update summary data
  Future<void> _updateSummaryData(String userId) async {
    try {
      _categorySummary = await _expenseService.getExpenseSummaryByCategory(userId);
      _totalExpenses = await _expenseService.getTotalExpenses(userId);
      print('Summary updated - Categories: ${_categorySummary.length}, Total: $_totalExpenses');
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
      print('Creating expense: $title, $amount, $category');
      final expense = Expense(
        title: title,
        amount: amount,
        category: category,
        description: description,
        date: date,
        userId: userId,
      );
      
      final createdExpense = await _expenseService.createExpense(expense);
      print('Expense created with ID: ${createdExpense.id}');
      
      // Add the expense to local list to ensure UI updates immediately
      _expenses = [createdExpense, ..._expenses];
      
      _isLoading = false;
      notifyListeners();
      
      // Refresh summary data
      _updateSummaryData(userId);
      
      return createdExpense;
    } catch (e) {
      print('Error creating expense: $e');
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
      // First check if it's in our local list
      final localExpense = _expenses.firstWhere(
        (expense) => expense.id == expenseId,
        orElse: () => Expense(
          id: null,
          title: '',
          amount: 0,
          category: 'Other',
          date: DateTime.now(),
          userId: '',
        ),
      );
      
      if (localExpense.id != null) {
        _isLoading = false;
        notifyListeners();
        return localExpense;
      }
      
      // If not found locally, fetch from Firestore
      final expense = await _expenseService.getExpenseById(expenseId);
      _isLoading = false;
      notifyListeners();
      return expense;
    } catch (e) {
      print('Error getting expense by ID: $e');
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
      print('Updating expense with ID: $id');
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
        
        // Update in local list to ensure UI updates immediately
        final index = _expenses.indexWhere((expense) => expense.id == id);
        if (index >= 0) {
          _expenses[index] = updatedExpense;
        }
        
        _isLoading = false;
        notifyListeners();
        
        // Refresh summary data
        _updateSummaryData(existingExpense.userId);
        
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Expense not found';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error updating expense: $e');
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
      print('Deleting expense with ID: $expenseId');
      
      // Find the expense to get userId before deletion
      final expenseToDelete = _expenses.firstWhere(
        (expense) => expense.id == expenseId,
        orElse: () => Expense(
          id: null,
          title: '',
          amount: 0,
          category: 'Other',
          date: DateTime.now(),
          userId: '',
        ),
      );
      
      final userId = expenseToDelete.userId;
      
      await _expenseService.deleteExpense(expenseId);
      
      // Remove from local list to ensure UI updates immediately
      _expenses.removeWhere((expense) => expense.id == expenseId);
      
      _isLoading = false;
      notifyListeners();
      
      // Refresh summary data if we have a userId
      if (userId.isNotEmpty) {
        _updateSummaryData(userId);
      }
      
      return true;
    } catch (e) {
      print('Error deleting expense: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Refresh expenses
  Future<void> refreshExpenses(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('Manually refreshing expenses for user: $userId');
      final refreshedExpenses = await _expenseService.getExpenses(userId).first;
      _expenses = refreshedExpenses;
      _isLoading = false;
      notifyListeners();
      
      // Update summary
      _updateSummaryData(userId);
    } catch (e) {
      print('Error refreshing expenses: $e');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
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
      print('Error getting expenses for period: $e');
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
      print('Error getting total for period: $e');
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