import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddTripScreen extends StatefulWidget {
  const AddTripScreen({super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _participantEmailController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;
  final List<String> _participantEmails = [];

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addParticipant() {
    final email = _participantEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_participantEmails.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This participant is already added'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _participantEmails.add(email);
      _participantEmailController.clear();
    });
  }

  void _removeParticipant(String email) {
    setState(() {
      _participantEmails.remove(email);
    });
  }

  Future<void> _createTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_participantEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one participant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get user IDs for participants
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', whereIn: [..._participantEmails, currentUser.email])
          .get();

      final participantIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
      participantIds.add(currentUser.uid); // Ensure current user is included

      // Create the trip
      await FirebaseFirestore.instance.collection('trips').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'participants': participantIds.toList(),
        'createdBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'totalExpenses': 0,
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
        title: const Text('Create New Trip'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.10),
              Theme.of(context).colorScheme.secondary.withOpacity(0.08),
              Theme.of(context).colorScheme.background,
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Trip Name',
                  prefixIcon: const Icon(Icons.card_travel),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a trip name';
                  }
                  return null;
                },
              )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideX(begin: -0.2, end: 0),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideX(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              Text(
                'Trip Dates',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 400.ms),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, true),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM d, y').format(_startDate)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(context, false),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM d, y').format(_endDate)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 600.ms),
              const SizedBox(height: 24),
              Text(
                'Participants',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 800.ms),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _participantEmailController,
                      decoration: InputDecoration(
                        labelText: 'Participant Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addParticipant,
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 1000.ms),
              const SizedBox(height: 16),
              ..._participantEmails.map((email) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(email),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    onPressed: () => _removeParticipant(email),
                  ),
                ),
              ).animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, end: 0)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createTrip,
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
                    : const Text('Create Trip'),
              )
              .animate()
              .fadeIn(duration: 500.ms, delay: 1200.ms)
              .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _participantEmailController.dispose();
    super.dispose();
  }
} 