import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/income.dart';
import 'package:expense_tracker/services/income_service.dart';
import 'package:expense_tracker/screens/add_income_screen.dart';
import 'package:intl/intl.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  final IncomeService _incomeService = IncomeService();
  DateTime _selectedDate = DateTime.now();
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddIncome(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_userId == null) {
      return const Center(child: Text('Please sign in to view income'));
    }

    return StreamBuilder<List<Income>>(
      stream: _incomeService.getIncomesByMonth(
        _userId!,
        _selectedDate.year,
        _selectedDate.month,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final incomes = snapshot.data ?? [];
        final totalAmount = incomes.fold<double>(
          0,
          (sum, income) => sum + income.amount,
        );

        return Column(
          children: [
            _buildMonthSelector(),
            const SizedBox(height: 8),
            _buildTotalIncomeCard(totalAmount),
            const SizedBox(height: 16),
            if (incomes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32.0),
                child: Text('No income recorded for this month'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: incomes.length,
                  itemBuilder: (context, index) {
                    final income = incomes[index];
                    return _buildIncomeItem(income);
                  },
                ),
              ),
          ],
        );
      },
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

  Widget _buildTotalIncomeCard(double amount) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Total Income',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeItem(Income income) {
    // Define source icons
    final Map<String, IconData> sourceIcons = {
      'salary': Icons.account_balance_wallet,
      'freelance': Icons.computer,
      'business': Icons.business_center,
      'investment': Icons.trending_up,
      'rental': Icons.home_work,
      'gift': Icons.card_giftcard,
      'other': Icons.payments,
    };

    // Get icon for the source, default to 'payments' icon if not found
    final sourceName = income.source.toString().split('.').last.toLowerCase();
    final icon = sourceIcons[sourceName] ?? Icons.payments;
    
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
          income.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('MMM d, y').format(income.date)} • ${sourceName[0].toUpperCase()}${sourceName.substring(1)}',
        ),
        trailing: Text(
          '₹${income.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        onTap: () => _navigateToEditIncome(context, income),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
  }

  void _navigateToAddIncome(BuildContext context) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    
    final result = await navigator.push(
      MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
    );

    if (result == true && mounted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income added successfully')),
        );
      }
    }
  }

  void _navigateToEditIncome(BuildContext context, Income income) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddIncomeScreen(income: income)),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income updated successfully')),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
