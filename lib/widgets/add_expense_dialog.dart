import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/expense_model.dart';
import '../models/trip_model.dart';

class AddExpenseDialog extends StatefulWidget {
  final TripModel trip;
  final Function(ExpenseModel) onExpenseAdded;

  const AddExpenseDialog({
    Key? key,
    required this.trip,
    required this.onExpenseAdded,
  }) : super(key: key);

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _tagController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  String _selectedPaidBy = '';
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String? _recurringFrequency;
  List<String> _tags = [];
  List<String> _receiptUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPaidBy = widget.trip.members.first.userId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Expense',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.2, end: 0),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .slideX(begin: -0.2, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideX(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixText: widget.trip.currency == 'INR' ? '₹' : '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 300.ms)
                .slideX(begin: -0.2, end: 0),
                const SizedBox(height: 16),
                DropdownButtonFormField<ExpenseCategory>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ExpenseCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 400.ms)
                .slideX(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPaidBy,
                  decoration: InputDecoration(
                    labelText: 'Paid By',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: widget.trip.members.map((member) {
                    return DropdownMenuItem(
                      value: member.userId,
                      child: Text(member.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPaidBy = value);
                    }
                  },
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 500.ms)
                .slideX(begin: -0.2, end: 0),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(
                      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: widget.trip.startDate,
                        lastDate: widget.trip.endDate ?? DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 600.ms)
                .slideX(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Recurring Expense'),
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() => _isRecurring = value);
                    },
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 700.ms)
                .slideX(begin: -0.2, end: 0),
                if (_isRecurring) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _recurringFrequency,
                    decoration: InputDecoration(
                      labelText: 'Frequency',
                      prefixIcon: const Icon(Icons.repeat),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (value) {
                      setState(() => _recurringFrequency = value);
                    },
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 800.ms)
                  .slideX(begin: 0.2, end: 0),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          labelText: 'Add Tags',
                          prefixIcon: const Icon(Icons.tag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _tags.add(value);
                              _tagController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (_tagController.text.isNotEmpty) {
                          setState(() {
                            _tags.add(_tagController.text);
                            _tagController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      color: theme.colorScheme.primary,
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 900.ms)
                .slideX(begin: -0.2, end: 0),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                      )
                      .animate()
                      .scale(duration: 300.ms);
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _uploadReceipt,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Receipt'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 1000.ms)
                .slideX(begin: 0.2, end: 0),
                if (_receiptUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _receiptUrls.map((url) {
                      return Chip(
                        label: const Text('Receipt'),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() => _receiptUrls.remove(url));
                        },
                      )
                      .animate()
                      .scale(duration: 300.ms);
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Expense'),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: 1100.ms)
                .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadReceipt() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('receipts')
            .child('${const Uuid().v4()}.jpg');

        await storageRef.putData(await image.readAsBytes());
        final url = await storageRef.getDownloadURL();

        setState(() {
          _receiptUrls.add(url);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isRecurring && _recurringFrequency == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a frequency')),
        );
        return;
      }

      final expense = ExpenseModel(
        id: const Uuid().v4(),
        tripId: widget.trip.id,
        title: _titleController.text,
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        paidBy: _selectedPaidBy,
        date: _selectedDate,
        isRecurring: _isRecurring,
        recurringFrequency: _recurringFrequency,
        tags: _tags,
        receiptUrls: _receiptUrls,
        splits: widget.trip.members.map((member) {
          return ExpenseSplit(
            userId: member.userId,
            amount: double.parse(_amountController.text) / widget.trip.members.length,
          );
        }).toList(),
        currency: widget.trip.currency,
      );

      widget.onExpenseAdded(expense);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _tagController.dispose();
    super.dispose();
  }
} 