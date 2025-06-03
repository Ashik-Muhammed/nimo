import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';

class DebtsListScreen extends StatefulWidget {
  const DebtsListScreen({super.key});

  @override
  State<DebtsListScreen> createState() => _DebtsListScreenState();
}

class _DebtsListScreenState extends State<DebtsListScreen> {
  bool _isLoading = true;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', locale: 'en_IN');
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  
  List<Debt> _debtsOwed = [];
  List<Debt> _debtsBorrowed = [];
  double _totalOwed = 0;
  double _totalBorrowed = 0;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final debtService = Provider.of<DebtService>(context, listen: false);
      final debts = await debtService.getActiveDebts(userId).first;
      

      
      // Separate debts into money owed and money borrowed
      final owed = debts.where((d) => d.type == DebtType.loan).toList();
      final borrowed = debts.where((d) => d.type == DebtType.lent).toList();
      

      
      // Calculate totals
      final totalOwed = owed.fold(0.0, (sum, debt) => sum + (debt.amount - debt.paidAmount));
      final totalBorrowed = borrowed.fold(0.0, (sum, debt) => sum + (debt.amount - debt.paidAmount));


      if (mounted) {
        setState(() {
          _debtsOwed = owed;
          _debtsBorrowed = borrowed;
          _totalOwed = totalOwed;
          _totalBorrowed = totalBorrowed;
          _isLoading = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading debts: $e')),
        );
      }
    }
  }

  Future<void> _checkDatabase() async {
    try {
      final debtService = Provider.of<DebtService>(context, listen: false);
      await debtService.debugListDebts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebts,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'debug_button',
            mini: true,
            onPressed: _checkDatabase,
            tooltip: 'Debug Database',
            child: const Icon(Icons.bug_report),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDebtScreen(
                    debtService: Provider.of<DebtService>(context, listen: false),
                  ),
                ),
              ).then((_) => _loadDebts());
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _debtsOwed.isEmpty && _debtsBorrowed.isEmpty
              ? _buildEmptyState()
              : _buildDebtsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.money_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Debts Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a new debt to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDebtScreen(
                    debtService: Provider.of<DebtService>(context, listen: false),
                  ),
                ),
              ).then((_) => _loadDebts());
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Debt'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsList() {
    return RefreshIndicator(
      onRefresh: _loadDebts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Money Owed Section
            if (_debtsOwed.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                'Money You Owe',
                _totalOwed,
                Colors.red,
              ),
              ..._debtsOwed.map((debt) => _buildDebtItem(debt)),
              const Divider(height: 1),
            ],
            
            // Money Borrowed Section
            if (_debtsBorrowed.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                'Money Owed to You',
                _totalBorrowed,
                Colors.green,
              ),
              ..._debtsBorrowed.map((debt) => _buildDebtItem(debt)),
              const Divider(height: 1),
            ],
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDebtDetail(Debt debt) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DebtDetailScreen(
          debt: debt,
          debtService: Provider.of<DebtService>(context, listen: false),
        ),
      ),
    );

    if (result == true) {
      _loadDebts(); // Refresh the list if any changes were made
    }
  }

  Widget _buildDebtItem(Debt debt) {
    final isOverdue = debt.dueDate.isBefore(DateTime.now()) && !debt.isPaid;
    final remainingAmount = debt.amount - debt.paidAmount;
    final progress = debt.amount > 0 ? (debt.paidAmount / debt.amount) : 0;
    final isLent = debt.type == DebtType.lent;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToDebtDetail(debt),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isOverdue 
                    ? Colors.red.withValues(alpha: 0.2)
                    : (isLent 
                        ? Colors.green.withValues(alpha: 0.2) 
                        : Colors.blue.withValues(alpha: 0.2)),
                child: Icon(
                  isOverdue 
                    ? Icons.warning 
                    : (isLent ? Icons.account_balance_wallet : Icons.credit_card),
                  color: isOverdue 
                    ? Colors.red 
                    : (isLent ? Colors.green : Colors.blue),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Remaining: ${_currencyFormat.format(remainingAmount)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.toDouble(),
                      backgroundColor: Colors.grey[200],
                      color: progress < 0.3 ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% paid',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isLent ? '+' : ''}${_currencyFormat.format(debt.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isLent ? Colors.green : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOverdue 
                        ? 'Overdue' 
                        : 'Due ${_dateFormat.format(debt.dueDate)}',
                    style: TextStyle(
                      color: isOverdue 
                          ? Theme.of(context).colorScheme.error 
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
