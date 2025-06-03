import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:expense_tracker/screens/add_debt_screen.dart';
import 'package:expense_tracker/screens/debt_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DebtsListScreen extends StatefulWidget {
  const DebtsListScreen({super.key});

  @override
  State<DebtsListScreen> createState() => _DebtsListScreenState();
}

class _DebtsListScreenState extends State<DebtsListScreen> {
  bool _isLoading = true;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', locale: 'en_IN');

  List<Debt> _debtsOwed = []; // Debts where user owes money
  List<Debt> _debtsBorrowed = []; // Debts where others owe user money
  double _totalOwed = 0;
  double _totalBorrowed = 0;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final debtService = Provider.of<DebtService>(context, listen: false);
      final debts = await debtService.getActiveDebts(userId).first;
      
      // Separate debts into money owed and money borrowed
      final List<Debt> owed = [];
      final List<Debt> borrowed = [];
      
      for (var debt in debts) {
        switch (debt.type) {
          // Money you owe to others
          case DebtType.borrowed:
          case DebtType.loan:
          case DebtType.creditCard:
            owed.add(debt);
            break;
            
          // Money others owe to you
          case DebtType.lent:
            borrowed.add(debt);
            break;
        }
      }
      
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
          const SnackBar(content: Text('Failed to load debts. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Debts', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDebts,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddDebtScreen(
                  debtService: Provider.of<DebtService>(context, listen: false),
                ),
              ),
            ).then((_) => _loadDebts()),
            tooltip: 'Add New Debt',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDebts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _debtsOwed.isEmpty && _debtsBorrowed.isEmpty
                ? _buildEmptyState()
                : _buildDebtsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  Theme.of(context).primaryColor.withAlpha(25), // ~10% opacity
                  Theme.of(context).cardColor,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Debts Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Track money you owe or are owed in one place',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddDebtScreen(
                    debtService: Provider.of<DebtService>(context, listen: false),
                  ),
                ),
              ).then((_) => _loadDebts()),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Debt'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadDebts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsList() {
    return CustomScrollView(
      slivers: [
        // Summary Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_debtsOwed.isNotEmpty) ...[
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'You Owe',
                      amount: _totalOwed,
                      icon: Icons.arrow_upward,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (_debtsBorrowed.isNotEmpty) ...[
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Owed to You',
                      amount: _totalBorrowed,
                      icon: Icons.arrow_downward,
                      color: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Money Owed by Me Section
        if (_debtsOwed.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Money You Owe',
            amount: _totalOwed,
            color: Colors.red,
            count: _debtsOwed.length,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildDebtItem(_debtsOwed[index], isOwed: true),
              childCount: _debtsOwed.length,
            ),
          ),
        ],
        
        // Money Owed to Me Section
        if (_debtsBorrowed.isNotEmpty) ...[
          _buildSectionHeader(
            title: 'Money Owed to You',
            amount: _totalBorrowed,
            color: Colors.green,
            count: _debtsBorrowed.length,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildDebtItem(_debtsBorrowed[index], isOwed: false),
              childCount: _debtsBorrowed.length,
            ),
          ),
        ],
        
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _currencyFormat.format(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required double amount,
    required Color color,
    required int count,
  }) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          border: Border(
            left: BorderSide(
              color: color,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? 'debt' : 'debts'}' ,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currencyFormat.format(amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, Debt debt, bool isOwed) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final remainingAmount = debt.amount - debt.paidAmount;
    final debtService = Provider.of<DebtService>(context, listen: false);
    
    // Set default amount to remaining amount
    amountController.text = remainingAmount.toStringAsFixed(2);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isOwed ? 'Make Payment' : 'Receive Payment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isOwed ? 'Amount to Pay' : 'Amount to Receive'}: ${NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(remainingAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isOwed ? 'Amount Paid' : 'Amount Received',
                      prefixText: '₹',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => amountController.clear(),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid number';
                      }
                      if (amount <= 0) {
                        return 'Amount must be greater than zero';
                      }
                      if (amount > remainingAmount) {
                        return 'Amount cannot exceed remaining balance';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  if (remainingAmount > 0) ...[
                    Wrap(
                      spacing: 8.0,
                      children: [
                        _buildQuickAmountButton(amountController, remainingAmount * 0.25, '25%'),
                        _buildQuickAmountButton(amountController, remainingAmount * 0.5, '50%'),
                        _buildQuickAmountButton(amountController, remainingAmount * 0.75, '75%'),
                        _buildQuickAmountButton(amountController, remainingAmount, '100%'),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final amount = double.parse(amountController.text);
                  final newPaidAmount = debt.paidAmount + amount;
                  final isFullyPaid = newPaidAmount >= debt.amount;
                  
                  final updatedDebt = debt.copyWith(
                    paidAmount: newPaidAmount,
                    isPaid: isFullyPaid,
                    paidDate: isFullyPaid ? DateTime.now() : debt.paidDate,
                  );
                  
                  try {
                    await debtService.updateDebt(updatedDebt);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isOwed 
                            ? 'Payment recorded successfully' 
                            : 'Payment received successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
                      _loadDebts();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isOwed ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(isOwed ? 'Pay Now' : 'Receive'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildQuickAmountButton(TextEditingController controller, double amount, String label) {
    return OutlinedButton(
      onPressed: () {
        controller.text = amount.toStringAsFixed(2);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      child: Text(
        '$label (${NumberFormat.currency(symbol: '₹', locale: 'en_IN').format(amount)})',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildDebtItem(Debt debt, {required bool isOwed}) {
    final primaryColor = isOwed ? Colors.red : Colors.green;
    final progress = debt.amount > 0 ? (debt.paidAmount / debt.amount) : 0;
    final isPaid = progress >= 1.0;
    
    // Calculate days until due
    final daysUntilDue = debt.dueDate.difference(DateTime.now()).inDays;
    
    // Format due date text
    final dueText = isPaid 
      ? 'Paid on ${DateFormat('MMM d, y').format(debt.dueDate)}'
      : daysUntilDue == 0 
        ? 'Due today'
        : daysUntilDue == 1 
          ? 'Due tomorrow' 
          : daysUntilDue < 0 
            ? '${daysUntilDue.abs()} days overdue' 
            : 'Due in $daysUntilDue days';
            
    final dueColor = isPaid 
      ? Colors.green
      : daysUntilDue <= 0 
        ? Colors.red 
        : daysUntilDue <= 7 
          ? Colors.orange 
          : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DebtDetailScreen(
                  debt: debt,
                  debtService: Provider.of<DebtService>(context, listen: false),
                ),
              ),
            ).then((_) => _loadDebts());
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        debt.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(debt.amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.toDouble().clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaid ? Colors.green : primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Status and due date row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid 
                            ? Colors.green[100]
                            : Color.alphaBlend(
                                primaryColor.withAlpha(25),
                                Theme.of(context).cardColor,
                              ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : '${(progress * 100).toInt()}% Paid',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPaid ? Colors.green[800] : primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    // Due date
                    Text(
                      dueText,
                      style: TextStyle(
                        fontSize: 12,
                        color: dueColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!isPaid) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showPaymentDialog(context, debt, isOwed),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isOwed ? 'Make Payment' : 'Receive Payment',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final debtService = Provider.of<DebtService>(context, listen: false);
                              final updatedDebt = debt.copyWith(
                                paidAmount: debt.amount,
                                isPaid: true,
                                paidDate: DateTime.now(),
                              );
                              
                              await debtService.updateDebt(updatedDebt);
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isOwed 
                                        ? 'Marked as Paid!'
                                        : 'Marked as Received!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadDebts();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to update debt status'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Full',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


}
