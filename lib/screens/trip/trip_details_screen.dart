import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_expense_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot> get _tripStream =>
      _firestore.collection('trips').doc(widget.tripId).snapshots();

  Stream<QuerySnapshot> get _expensesStream =>
      _firestore
          .collection('trips')
          .doc(widget.tripId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots();

  Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: _tripStream,
        builder: (context, tripSnapshot) {
          if (tripSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!tripSnapshot.hasData || !tripSnapshot.data!.exists) {
            return const Center(child: Text('Trip not found'));
          }

          final tripData = tripSnapshot.data!.data() as Map<String, dynamic>;
          final startDate = (tripData['startDate'] as Timestamp).toDate();
          final endDate = (tripData['endDate'] as Timestamp).toDate();

          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(tripData['name'] as String),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tripData['description']?.isNotEmpty ?? false) ...[
                        Text(
                          tripData['description'] as String,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, y').format(endDate)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.2, end: 0),
                      const SizedBox(height: 24),
                      Text(
                        'Expenses',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms),
                    ],
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _expensesStream,
                builder: (context, expensesSnapshot) {
                  if (expensesSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!expensesSnapshot.hasData ||
                      expensesSnapshot.data!.docs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            )
                            .animate(onPlay: (controller) => controller.repeat())
                            .shimmer(duration: 2.seconds),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add an expense to start tracking',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = expensesSnapshot.data!.docs[index];
                        final expenseData = expense.data() as Map<String, dynamic>;
                        final date = (expenseData['date'] as Timestamp).toDate();

                        return FutureBuilder<Map<String, dynamic>>(
                          future: _getUserDetails(expenseData['paidBy'] as String),
                          builder: (context, userSnapshot) {
                            final userName = userSnapshot.data?['name'] ?? 'Loading...';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  expenseData['description'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 16),
                                        const SizedBox(width: 4),
                                        Text('Paid by $userName'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 16),
                                        const SizedBox(width: 4),
                                        Text(DateFormat('MMM d, y').format(date)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '\$${(expenseData['amount'] as num).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: (index * 100).ms)
                            .slideX(begin: 0.2, end: 0);
                          },
                        );
                      },
                      childCount: expensesSnapshot.data!.docs.length,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(tripId: widget.tripId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      )
      .animate()
      .scale(delay: 500.ms),
    );
  }
} 