import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
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
    return Dialog(
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
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: const OutlineInputBorder(),
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
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ExpenseCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
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
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaidBy,
                decoration: const InputDecoration(
                  labelText: 'Paid By',
                  border: OutlineInputBorder(),
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
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
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
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Recurring Expense'),
                value: _isRecurring,
                onChanged: (value) {
                  setState(() => _isRecurring = value);
                },
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _recurringFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) {
                    setState(() => _recurringFrequency = value);
                  },
                  validator: (value) =>
                      value == null ? 'Please select a frequency' : null,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add Tags',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final tag = _tagController.text.trim();
                      if (tag.isNotEmpty && !_tags.contains(tag)) {
                        setState(() {
                          _tags.add(tag);
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      onDeleted: () {
                        setState(() => _tags.remove(tag));
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadReceipt,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Receipt'),
              ),
              if (_receiptUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _receiptUrls.map((url) {
                    return Chip(
                      label: const Text('Receipt'),
                      onDeleted: () {
                        setState(() => _receiptUrls.remove(url));
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
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
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Add Expense'),
                  ),
                ],
              ),
            ],
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