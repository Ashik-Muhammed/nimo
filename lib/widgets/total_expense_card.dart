import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/models/expense.dart';

class TotalExpenseCard extends StatelessWidget {
  final int month;
  final int year;
  final ExpenseService _expenseService;

 TotalExpenseCard({
    super.key,
    required this.month,
    required this.year,
  }) : _expenseService = ExpenseService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountFormat = NumberFormat.currency(symbol: '₹');
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      return const SizedBox.shrink();
    }
    
    // Calculate the first and last millisecond of the month
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    
    return StreamBuilder<List<Expense>>(
      stream: _expenseService.getExpensesByDateRangeStream(
        userId, 
        startDate.millisecondsSinceEpoch, 
        endDate.millisecondsSinceEpoch,
      ),
      builder: (context, snapshot) {
        double totalExpenses = 0;
        
        if (snapshot.hasData) {
          totalExpenses = snapshot.data!.fold(
            0,
            (sum, expense) => sum + expense.amount,
          );
        }
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expenses',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.titleMedium?.color?.withValues(alpha: .7), // Keep using withOpacity for now
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      amountFormat.format(totalExpenses),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.attach_money_rounded,
                      size: 40,
                      color: theme.colorScheme.primary.withValues(alpha: .7), 
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
