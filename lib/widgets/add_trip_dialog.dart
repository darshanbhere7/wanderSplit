import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_model.dart';
import '../providers/main_provider.dart';

class AddTripDialog extends StatefulWidget {
  final Function(TripModel) onTripAdded;

  const AddTripDialog({
    super.key,
    required this.onTripAdded,
  });

  @override
  State<AddTripDialog> createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<AddTripDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _memberEmailController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  TripCategory _category = TripCategory.leisure;
  String _currency = 'INR';
  List<TripMember> _members = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add current user as admin
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String adminName = (currentUser.displayName?.isNotEmpty == true)
          ? currentUser.displayName!
          : (currentUser.email ?? 'Admin');
      _members.add(TripMember(
        userId: currentUser.uid,
        name: adminName,
        role: MemberRole.admin,
        email: currentUser.email ?? '',
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final email = _memberEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }
    if (_members.any((m) => m.email == email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member already added')),
      );
      return;
    }
    setState(() {
      _members.add(TripMember(
        userId: email,
        name: email,
        role: MemberRole.member,
        email: email,
      ));
      _memberEmailController.clear();
    });
  }

  void _removeMember(String userId) {
    // Don't allow removing the admin
    if (_members.firstWhere((m) => m.userId == userId).role == MemberRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove admin')),
      );
      return;
    }

    setState(() {
      _members.removeWhere((m) => m.userId == userId);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? _startDate),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final trip = TripModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        budget: double.parse(_budgetController.text),
        location: _locationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        currency: _currency,
        members: _members,
        memberIds: _members.map((m) => m.email).toList(),
        createdBy: FirebaseAuth.instance.currentUser!.uid,
      );

      await context.read<MainProvider>().addTrip(trip);
      if (mounted) {
        widget.onTripAdded(trip);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating trip: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
                'Create New Trip',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Trip Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a trip name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TripCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: TripCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'INR', child: Text('Indian Rupee (₹)')),
                        DropdownMenuItem(value: 'USD', child: Text('US Dollar (\$)')),
                        DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                        DropdownMenuItem(value: 'GBP', child: Text('British Pound (£)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currency = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      decoration: InputDecoration(
                        labelText: 'Budget',
                        border: const OutlineInputBorder(),
                        prefixText: _currency == 'INR' ? '₹' : 
                                  _currency == 'USD' ? '\$' :
                                  _currency == 'EUR' ? '€' : '£',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a budget';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'Start: ${_startDate.toString().split(' ')[0]}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'End: ${_endDate?.toString().split(' ')[0] ?? 'Not set'}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Trip Members',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _memberEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Member Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _addMember,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._members.map((member) => ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
                  ),
                ),
                title: Text(member.name),
                subtitle: Text(member.role.toString().split('.').last),
                trailing: member.role == MemberRole.admin
                    ? const Icon(Icons.star, color: Colors.amber)
                    : IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeMember(member.userId),
                      ),
              )),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 