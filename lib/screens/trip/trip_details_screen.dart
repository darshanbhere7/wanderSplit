import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_expense_screen.dart';
import '../../models/expense_split_model.dart';
import '../../services/expense_split_service.dart';
import '../../services/expense_service.dart';

class TripDetailsScreen extends StatefulWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _expenseSplitService = ExpenseSplitService();
  final _expenseService = ExpenseService();

  Stream<DocumentSnapshot> get _tripStream =>
      _firestore.collection('trips').doc(widget.tripId).snapshots();

  Stream<QuerySnapshot> get _expensesStream =>
      _firestore
          .collection('trips')
          .doc(widget.tripId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots();

  Stream<List<ExpenseSplit>> get _splitsStream =>
      _expenseSplitService.getSplitsForTrip(widget.tripId);

  Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> _markSplitAsSettled(String expenseId, String userId) async {
    try {
      await _expenseSplitService.markSplitAsSettled(expenseId, userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking split as settled: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      await _expenseService.deleteExpense(widget.tripId, expenseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showDeleteExpenseDialog(String expenseId, String description) async {
    if (!mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "$description"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteExpense(expenseId);
    }
    return result;
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
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(tripData['name'] as String),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tripData['description']?.isNotEmpty ?? false) ...[
                            Text(
                              tripData['description'] as String,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d, y').format(endDate)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideX(begin: -0.2, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              StreamBuilder<List<ExpenseSplit>>(
                stream: _splitsStream,
                builder: (context, splitsSnapshot) {
                  if (splitsSnapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!splitsSnapshot.hasData || splitsSnapshot.data!.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No expense splits yet'),
                        ),
                      ),
                    );
                  }

                  final balances = <String, double>{};
                  for (final split in splitsSnapshot.data!) {
                    split.splits.forEach((userId, amount) {
                      balances[userId] = (balances[userId] ?? 0.0) + amount;
                    });
                  }

                  return SliverToBoxAdapter(
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balances',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...balances.entries.map((entry) {
                              return FutureBuilder<Map<String, dynamic>>(
                                future: _getUserDetails(entry.key),
                                builder: (context, userSnapshot) {
                                  final userName = userSnapshot.data?['name'] ?? 'Loading...';
                                  final amount = entry.value;
                                  final isPositive = amount > 0;
                                  
                                  return ListTile(
                                    title: Text(userName),
                                    trailing: Text(
                                      '\$${amount.abs().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isPositive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      isPositive ? 'Gets back' : 'Owes',
                                      style: TextStyle(
                                        color: isPositive ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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

                            return Dismissible(
                              key: Key(expense.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await _showDeleteExpenseDialog(
                                  expense.id,
                                  expenseData['description'] as String,
                                );
                              },
                              child: Card(
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
                                      const SizedBox(height: 8),
                                      StreamBuilder<ExpenseSplit?>(
                                        stream: _expenseSplitService.getSplitForExpense(expense.id).asStream(),
                                        builder: (context, splitSnapshot) {
                                          if (!splitSnapshot.hasData) {
                                            return const SizedBox.shrink();
                                          }

                                          final split = splitSnapshot.data!;
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Split Details:',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              ...split.splits.entries.map((entry) {
                                                return FutureBuilder<Map<String, dynamic>>(
                                                  future: _getUserDetails(entry.key),
                                                  builder: (context, userSnapshot) {
                                                    final participantName = userSnapshot.data?['name'] ?? 'Loading...';
                                                    final amount = entry.value;
                                                    final isPositive = amount > 0;
                                                    
                                                    return Padding(
                                                      padding: const EdgeInsets.only(left: 8.0),
                                                      child: Text(
                                                        '$participantName: ${isPositive ? 'gets' : 'owes'} \$${amount.abs().toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          color: isPositive ? Colors.green : Colors.red,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }).toList(),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${(expenseData['amount'] as num).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        expenseData['category'] as String,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
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