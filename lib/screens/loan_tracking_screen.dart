import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:expense_tracker/services/loan_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LoanTrackingScreen extends StatefulWidget {
  const LoanTrackingScreen({super.key});

  @override
  State<LoanTrackingScreen> createState() => _LoanTrackingScreenState();
}

class _LoanTrackingScreenState extends State<LoanTrackingScreen> {
  bool _isLoading = true;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', locale: 'en_IN');

  List<Debt> _loans = [];
  double _totalLoanAmount = 0;
  double _totalEMI = 0;
  double _totalInterestPayable = 0;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final debtService = Provider.of<DebtService>(context, listen: false);
      final allDebts = await debtService.getActiveDebts(userId).first;
      
      // Filter only loans
      final loans = allDebts.where((debt) => debt.type.isLoan).toList();
      
      // Calculate totals
      double totalAmount = 0;
      double totalEMI = 0;
      double totalInterest = 0;
      
      for (var loan in loans) {
        totalAmount += loan.amount;
        if (loan.emi != null) {
          totalEMI += loan.emi!;
        }
        if (loan.interestRate != null && loan.tenureMonths != null) {
          totalInterest += LoanService.calculateTotalInterest(
            principal: loan.amount,
            annualInterestRate: loan.interestRate!,
            tenureMonths: loan.tenureMonths!,
          );
        }
      }

      if (mounted) {
        setState(() {
          _loans = loans;
          _totalLoanAmount = totalAmount;
          _totalEMI = totalEMI;
          _totalInterestPayable = totalInterest;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load loans. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Loan Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadLoans,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLoans,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loans.isEmpty
                ? _buildEmptyState()
                : _buildLoansList(),
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
                  Theme.of(context).primaryColor.withAlpha(25),
                  Theme.of(context).cardColor,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Loans Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Track your loans with amortization schedules and EMI calculations',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: _loadLoans,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansList() {
    return CustomScrollView(
      slivers: [
        // Summary Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSummaryCard(
                  'Total Loan Amount',
                  _totalLoanAmount,
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Monthly EMI',
                        _totalEMI,
                        Icons.calendar_month,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Interest',
                        _totalInterestPayable,
                        Icons.trending_up,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Loans List
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildLoanItem(_loans[index]),
            childCount: _loans.length,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(amount),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanItem(Debt loan) {
    final emi = loan.emi ?? 0;
    final progress = loan.amount > 0 ? (loan.paidAmount / loan.amount) : 0;
    final isPaid = progress >= 1.0;
    
    // Calculate days until due
    final daysUntilDue = loan.dueDate.difference(DateTime.now()).inDays;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLoanDetails(loan),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loan.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loan.type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _currencyFormat.format(loan.amount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // EMI and Tenure
                if (emi > 0) ...[
                  Row(
                    children: [
                      _buildInfoChip(
                        'EMI: ${_currencyFormat.format(emi)}',
                        Icons.calendar_month,
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      if (loan.tenureMonths != null)
                        _buildInfoChip(
                          '${loan.tenureMonths} months',
                          Icons.schedule,
                          Colors.blue,
                        ),
                      const SizedBox(width: 8),
                      if (loan.interestRate != null)
                        _buildInfoChip(
                          '${loan.interestRate}% p.a.',
                        Icons.percent,
                          Colors.green,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.toDouble().clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaid ? Colors.green : Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status and due date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid 
                            ? Colors.green[100]
                            : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : '${(progress * 100).toInt()}% Paid',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPaid ? Colors.green[800] : Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      daysUntilDue <= 0 
                          ? 'Overdue' 
                          : daysUntilDue == 1 
                              ? 'Due tomorrow' 
                              : 'Due in $daysUntilDue days',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysUntilDue <= 0 ? Colors.red : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showLoanDetails(Debt loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loan.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', loan.type.displayName),
              _buildDetailRow('Amount', _currencyFormat.format(loan.amount)),
              _buildDetailRow('Paid', _currencyFormat.format(loan.paidAmount)),
              _buildDetailRow('Remaining', _currencyFormat.format(loan.remainingAmount)),
              if (loan.emi != null)
                _buildDetailRow('EMI', _currencyFormat.format(loan.emi!)),
              if (loan.tenureMonths != null)
                _buildDetailRow('Tenure', '${loan.tenureMonths} months'),
              if (loan.interestRate != null)
                _buildDetailRow('Interest Rate', '${loan.interestRate}% p.a.'),
              if (loan.lender != null)
                _buildDetailRow('Lender', loan.lender!),
              _buildDetailRow('Due Date', DateFormat('MMM dd, yyyy').format(loan.dueDate)),
              if (loan.startDate != null)
                _buildDetailRow('Start Date', DateFormat('MMM dd, yyyy').format(loan.startDate!)),
              if (loan.notes != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(loan.notes!),
              ],
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
