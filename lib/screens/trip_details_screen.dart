import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/trip_model.dart';
import '../models/expense_model.dart';
import '../models/settlement_model.dart';
import '../providers/main_provider.dart';
import '../widgets/add_expense_dialog.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripDetailsScreen extends StatefulWidget {
  final TripModel trip;
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const TripDetailsScreen({
    Key? key,
    required this.trip,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NumberFormat _currencyFormat;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currencyFormat = NumberFormat.currency(
      symbol: widget.trip.currency == 'INR' ? '₹' : 
              widget.trip.currency == 'USD' ? '\$' :
              widget.trip.currency == 'EUR' ? '€' : '£',
      decimalDigits: 2,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainProvider = context.watch<MainProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final isAdmin = widget.trip.createdBy == user?.uid || widget.trip.isAdmin(user?.uid ?? '');
    final expenses = mainProvider.getExpensesForTrip(widget.trip.id);
    final settlements = mainProvider.getSettlementsForTrip(widget.trip.id);
    final totalExpenses = mainProvider.getTotalExpensesForTrip(widget.trip.id);
    final categoryTotals = mainProvider.getCategoryTotalsForTrip(widget.trip.id);
    final expenseTrends = mainProvider.getExpenseTrendsForTrip(widget.trip.id);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.trip.name,
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Rename Trip',
              onPressed: () => _showRenameDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Trip',
              onPressed: () => _showDeleteDialog(context),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.10),
              theme.colorScheme.secondary.withOpacity(0.08),
              theme.colorScheme.background,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Expenses'),
                Tab(text: 'Settlements'),
                Tab(text: 'Members'),
              ],
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
              indicatorColor: theme.colorScheme.primary,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(totalExpenses, categoryTotals, expenseTrends),
                  _buildExpensesTab(expenses),
                  _buildSettlementsTab(settlements),
                  _buildMembersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      )
      .animate()
      .fadeIn(duration: 600.ms, delay: 900.ms)
      .slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildOverviewTab(
    double totalExpenses,
    Map<ExpenseCategory, double> categoryTotals,
    List<Map<String, dynamic>> expenseTrends,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(totalExpenses),
          const SizedBox(height: 16),
          _buildBudgetProgressCard(totalExpenses),
          const SizedBox(height: 16),
          _buildExpenseChart(expenseTrends),
          const SizedBox(height: 16),
          _buildCategoryBreakdown(categoryTotals),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(double totalExpenses) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildOverviewCard(
          'Total Expenses',
          _currencyFormat.format(totalExpenses),
          Icons.account_balance_wallet,
          Theme.of(context).colorScheme.primary,
        ),
        _buildOverviewCard(
          'Remaining Budget',
          _currencyFormat.format(widget.trip.budget - totalExpenses),
          Icons.savings,
          Colors.green,
        ),
        _buildOverviewCard(
          'Trip Duration',
          '${_calculateDuration()} days',
          Icons.calendar_today,
          Colors.orange,
        ),
        _buildOverviewCard(
          'Members',
          '${widget.trip.members.length}',
          Icons.people,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgressCard(double totalExpenses) {
    final progress = totalExpenses / widget.trip.budget;
    final color = progress > 0.9 ? Colors.red : progress > 0.7 ? Colors.orange : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${_currencyFormat.format(totalExpenses)}',
                  style: TextStyle(color: color),
                ),
                Text(
                  'Budget: ${_currencyFormat.format(widget.trip.budget)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(List<Map<String, dynamic>> expenseTrends) {
    if (expenseTrends.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No expense data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _currencyFormat.format(value),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = expenseTrends[value.toInt()]['date'] as DateTime;
                          return Text(
                            DateFormat('MM/dd').format(date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: expenseTrends.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['amount'] as double,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<ExpenseCategory, double> categoryTotals) {
    if (categoryTotals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No category data available'),
          ),
        ),
      );
    }

    final total = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: PieChart(
                      PieChartData(
                        sections: sortedCategories.map((entry) {
                          final percentage = entry.value / total;
                          return PieChartSectionData(
                            value: entry.value,
                            title: '${(percentage * 100).toStringAsFixed(1)}%',
                            color: _getCategoryColor(entry.key),
                            radius: 40,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedCategories.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(entry.key),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key.toString().split('.').last,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              _currencyFormat.format(entry.value),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesTab(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('No expenses added yet'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(expense.category),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: Colors.white,
              ),
            ),
            title: Text(expense.title),
            subtitle: Text(
              '${_currencyFormat.format(expense.amount)} • ${DateFormat('MMM d, y').format(expense.date)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showExpenseDetails(expense),
          ),
        );
      },
    );
  }

  Widget _buildSettlementsTab(List<SettlementModel> settlements) {
    if (settlements.isEmpty) {
      return const Center(
        child: Text('No settlements needed'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: settlements.length,
      itemBuilder: (context, index) {
        final settlement = settlements[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getSettlementStatusColor(settlement.status),
              child: Icon(
                _getSettlementStatusIcon(settlement.status),
                color: Colors.white,
              ),
            ),
            title: Text(
              '${settlement.fromUserName} → ${settlement.toUserName}',
            ),
            subtitle: Text(
              '${_currencyFormat.format(settlement.amount)} • ${DateFormat('MMM d, y').format(settlement.dueDate)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSettlementDetails(settlement),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.trip.members.length,
      itemBuilder: (context, index) {
        final member = widget.trip.members[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(member.name[0].toUpperCase()),
            ),
            title: Text(member.name),
            subtitle: Text(member.role.toString().split('.').last),
            trailing: member.role == MemberRole.admin
                ? const Icon(Icons.star, color: Colors.amber)
                : null,
          ),
        );
      },
    );
  }

  void _showExpenseDetails(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ${_currencyFormat.format(expense.amount)}'),
            Text('Category: ${expense.category.toString().split('.').last}'),
            Text('Date: ${DateFormat('MMM d, y').format(expense.date)}'),
            if (expense.description.isNotEmpty)
              Text('Description: ${expense.description}'),
            if (expense.isRecurring)
              Text('Recurring: ${expense.recurringFrequency}'),
            if (expense.tags.isNotEmpty)
              Text('Tags: ${expense.tags.join(", ")}'),
            if (expense.receiptUrls.isNotEmpty)
              Text('Receipts: ${expense.receiptUrls.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettlementDetails(SettlementModel settlement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settlement Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${settlement.fromUserName}'),
            Text('To: ${settlement.toUserName}'),
            Text('Amount: ${_currencyFormat.format(settlement.amount)}'),
            Text('Status: ${settlement.status.toString().split('.').last}'),
            Text('Due Date: ${DateFormat('MMM d, y').format(settlement.dueDate)}'),
            if (settlement.paymentMethod != null)
              Text('Payment Method: ${settlement.paymentMethod.toString().split('.').last}'),
            if (settlement.paymentReference != null)
              Text('Payment Reference: ${settlement.paymentReference}'),
            if (settlement.notes != null)
              Text('Notes: ${settlement.notes}'),
          ],
        ),
        actions: [
          if (settlement.status == SettlementStatus.pending)
            TextButton(
              onPressed: () {
                context.read<MainProvider>().updateSettlement(
                  settlement.copyWith(
                    status: SettlementStatus.paid,
                    settledDate: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Mark as Paid'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  int _calculateDuration() {
    final end = widget.trip.endDate ?? DateTime.now();
    return end.difference(widget.trip.startDate).inDays + 1;
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Theme.of(context).colorScheme.primary;
      case ExpenseCategory.accommodation:
        return Colors.purple;
      case ExpenseCategory.activities:
        return Colors.green;
      case ExpenseCategory.shopping:
        return Colors.pink;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.activities:
        return Icons.attractions;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getSettlementStatusColor(SettlementStatus status) {
    switch (status) {
      case SettlementStatus.pending:
        return Colors.orange;
      case SettlementStatus.paid:
        return Colors.green;
      case SettlementStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getSettlementStatusIcon(SettlementStatus status) {
    switch (status) {
      case SettlementStatus.pending:
        return Icons.pending;
      case SettlementStatus.paid:
        return Icons.check_circle;
      case SettlementStatus.cancelled:
        return Icons.cancel;
    }
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        trip: widget.trip,
        onExpenseAdded: (expense) {
          context.read<MainProvider>().addExpense(expense);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<MainProvider>().deleteTrip(widget.trip.id);
                if (mounted) {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting trip: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final _nameController = TextEditingController(text: widget.trip.name);
    final _descController = TextEditingController(text: widget.trip.description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Trip Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<MainProvider>().renameTrip(
                  widget.trip.id,
                  _nameController.text.trim(),
                  _descController.text.trim(),
                );
                if (mounted) Navigator.of(ctx).pop();
              } catch (e) {
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error renaming trip: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
} 