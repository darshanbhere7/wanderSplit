import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddExpenseScreen extends StatefulWidget {
  final String tripId;

  const AddExpenseScreen({super.key, required this.tripId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Food & Drinks',
    'Transportation',
    'Accommodation',
    'Activities',
    'Shopping',
    'Other',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final tripRef = FirebaseFirestore.instance.collection('trips').doc(widget.tripId);
      final expenseRef = tripRef.collection('expenses').doc();

      // Get the trip data to update total expenses
      final tripDoc = await tripRef.get();
      if (!tripDoc.exists) throw Exception('Trip not found');

      final tripData = tripDoc.data()!;
      final currentTotal = (tripData['totalExpenses'] as num?) ?? 0;
      final amount = double.parse(_amountController.text);

      // Create the expense and update trip total in a transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(expenseRef, {
          'description': _descriptionController.text.trim(),
          'amount': amount,
          'category': _selectedCategory,
          'date': Timestamp.fromDate(_selectedDate),
          'paidBy': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(tripRef, {
          'totalExpenses': currentTotal + amount,
        });
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideX(begin: -0.2, end: 0),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideX(begin: 0.2, end: 0),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 400.ms)
            .slideX(begin: -0.2, end: 0),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('MMM d, y').format(_selectedDate)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 600.ms)
            .slideX(begin: 0.2, end: 0),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _addExpense,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Expense'),
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 800.ms)
            .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
} 