import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width < 500 ? 360 : 420,
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          child: Card(
            elevation: 16,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.07),
                    theme.colorScheme.secondary.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create New Trip',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Trip Name',
                          prefixIcon: const Icon(Icons.card_travel),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a trip name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              style: const TextStyle(fontSize: 14),
                              controller: _budgetController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Budget',
                                prefixIcon: const Icon(Icons.attach_money),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a budget';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              style: const TextStyle(fontSize: 14),
                              value: _currency,
                              decoration: InputDecoration(
                                labelText: 'Currency',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                              items: ['INR', 'USD', 'EUR', 'GBP'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) => setState(() => _currency = val ?? 'INR'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        style: const TextStyle(fontSize: 14),
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(context, true),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Start Date',
                                    prefixIcon: const Icon(Icons.date_range),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                  controller: TextEditingController(text: _startDate.toString().split(' ')[0]),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectDate(context, false),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'End Date',
                                    prefixIcon: const Icon(Icons.date_range),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  ),
                                  controller: TextEditingController(text: _endDate != null ? _endDate.toString().split(' ')[0] : ''),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<TripCategory>(
                        style: const TextStyle(fontSize: 14),
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                      const SizedBox(height: 14),
                      const SizedBox(height: 8),
                      Text('Trip Members', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    style: const TextStyle(fontSize: 14),
                                    controller: _memberEmailController,
                                    decoration: InputDecoration(
                                      labelText: 'Add member by email',
                                      prefixIcon: const Icon(Icons.person_add),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    textStyle: const TextStyle(fontSize: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  onPressed: _isLoading ? null : _addMember,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _members.map((member) {
                                return Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: member.role == MemberRole.admin
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.secondary,
                                    child: Icon(
                                      member.role == MemberRole.admin ? Icons.star : Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  label: Text(
                                    member.name,
                                    style: TextStyle(
                                      fontWeight: member.role == MemberRole.admin ? FontWeight.bold : FontWeight.normal,
                                      color: member.role == MemberRole.admin
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: member.role == MemberRole.admin
                                      ? theme.colorScheme.primary.withOpacity(0.12)
                                      : theme.colorScheme.secondary.withOpacity(0.10),
                                  deleteIcon: member.role == MemberRole.admin
                                      ? null
                                      : const Icon(Icons.close, size: 14),
                                  onDeleted: member.role == MemberRole.admin
                                      ? null
                                      : () => _removeMember(member.userId),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text('Create Trip', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(fontSize: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 