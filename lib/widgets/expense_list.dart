import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/expense.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final Function(String) onDeleteExpense;

  const ExpenseList({
    super.key,
    required this.expenses,
    required this.onDeleteExpense,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text('No expenses yet. Tap + to add your first expense!'),
      );
    }

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildExpenseTile(context, expense);
      },
    );
  }

  Widget _buildExpenseTile(BuildContext context, Expense expense) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final amountFormat = NumberFormat.currency(symbol: '₹');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onDeleteExpense(expense.id),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: _getCategoryIcon(expense.category),
            ),
            title: Text(
              expense.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              dateFormat.format(expense.date),
              style: theme.textTheme.bodySmall,
            ),
            trailing: Text(
              amountFormat.format(expense.amount),
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.red, // Changed to red
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Icon(Icons.restaurant, size: 20);
      case 'transportation':
        return const Icon(Icons.directions_car, size: 20);
      case 'shopping':
        return const Icon(Icons.shopping_bag, size: 20);
      case 'entertainment':
        return const Icon(Icons.movie, size: 20);
      case 'bills':
        return const Icon(Icons.receipt, size: 20);
      default:
        return const Icon(Icons.money, size: 20);
    }
  }
}
