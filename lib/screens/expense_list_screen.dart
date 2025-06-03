import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:intl/intl.dart';


class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late DateTime _selectedDate;
  final ExpenseService _expenseService = ExpenseService();
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view expenses')),
      );
    }

    final firstDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      1,
      0,
      0,
      0,
    );
    final lastDay = DateTime(
      _selectedDate.year,
      _selectedDate.month + 1,
      0,
      23,
      59,
      59,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 8),
          _buildTotalExpenseCard(),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _expenseService.getExpensesByMonthStream(
                _userId!,
                firstDay,
                lastDay,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final expenses = snapshot.data ?? [];
                if (expenses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 32.0),
                    child: Text('No expenses recorded for this month'),
                  );
                }

                return ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _buildExpenseItem(expense);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _previousMonth,
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    // Define category icons
    final Map<String, IconData> categoryIcons = {
      'Food & Dining': Icons.restaurant,
      'Transport': Icons.directions_car,
      'Shopping': Icons.shopping_bag,
      'Bills & Utilities': Icons.receipt,
      'Entertainment': Icons.movie,
      'Health & Fitness': Icons.favorite,
      'Education': Icons.school,
      'Travel': Icons.flight,
      'Groceries': Icons.shopping_cart,
      'Housing': Icons.home,
      'Transportation': Icons.directions_car,
      'Personal': Icons.person,
      'Insurance': Icons.security,
      'Investments': Icons.trending_up,
      'Gifts': Icons.card_giftcard,
      'Other': Icons.category,
    };

    // Get icon for the category, default to 'category' icon if not found
    final icon = categoryIcons[expense.category] ?? Icons.category;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('MMM d, y').format(expense.date)} • ${expense.category}',
        ),
        trailing: Text(
          '₹${expense.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        onTap: () => _navigateToEditExpense(context, expense),
      ),
    );
  }

  Widget _buildTotalExpenseCard() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    return StreamBuilder<List<Expense>>(
      stream: _expenseService.getExpensesByMonthStream(
        _userId!,
        firstDay,
        lastDay,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final expenses = snapshot.data ?? [];
        final totalAmount = expenses.fold<double>(
          0,
          (sum, expense) => sum + expense.amount,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Total Expenses',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month);
      });
    }
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
  }

  void _previousMonth() {
    final newDate = _selectedDate.month == 1
        ? DateTime(_selectedDate.year - 1, 12, 1)
        : DateTime(_selectedDate.year, _selectedDate.month - 1, 1);

    if (mounted) {
      setState(() => _selectedDate = newDate);
    }
  }

  void _navigateToEditExpense(BuildContext context, Expense expense) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated successfully')),
      );
    }
  }

  void _navigateToAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
  }
}
