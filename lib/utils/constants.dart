import 'package:flutter/material.dart';

class AppConstants {
  // Expense categories with icons and colors
  static const Map<String, Map<String, dynamic>> expenseCategories = {
    'Food': {
      'icon': Icons.restaurant,
      'color': Colors.orange,
    },
    'Transport': {
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    'Housing': {
      'icon': Icons.home,
      'color': Colors.brown,
    },
    'Entertainment': {
      'icon': Icons.movie,
      'color': Colors.purple,
    },
    'Shopping': {
      'icon': Icons.shopping_bag,
      'color': Colors.pink,
    },
    'Utilities': {
      'icon': Icons.power,
      'color': Colors.yellow,
    },
    'Healthcare': {
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    'Education': {
      'icon': Icons.school,
      'color': Colors.green,
    },
    'Other': {
      'icon': Icons.category,
      'color': Colors.grey,
    },
  };
  
  // Get category icon
  static IconData getCategoryIcon(String category) {
    return expenseCategories[category]?['icon'] ?? Icons.category;
  }
  
  // Get category color
  static Color getCategoryColor(String category) {
    return expenseCategories[category]?['color'] ?? Colors.grey;
  }
  
  // Currency symbols
  static const String currencySymbol = '\$';
  
  // Format amount
  static String formatAmount(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }

  // Date formats
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 