import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/screens/add_debt_screen.dart';
import 'package:expense_tracker/screens/debts_list_screen.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/budget_service.dart';
import 'package:expense_tracker/services/income_service.dart';
import 'package:expense_tracker/services/balance_service.dart';
import 'package:expense_tracker/models/expense.dart' as expense_model;
import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/screens/debt_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

// Make the state class public so it can be accessed from HomeScreen
abstract class DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = false;
  
  // Abstract methods that must be implemented by concrete classes
  Future<void> _loadBudget();
  Future<void> _loadExpenses(BuildContext context);
  Future<void> _loadDebts();
  
  // State variables for financial data
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  
  // Make loadUserData accessible to HomeScreen
  double get balance => _totalIncome - _totalExpenses;
  
  Future<void> loadUserData(BuildContext context) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      await Future.wait([
        _loadBudget(),
        _loadExpenses(context),
        _loadDebts(),
      ]);
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load data. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
   void navigateToAddDebt() {
    // Default implementation does nothing
  }
}

class _DashboardScreenState extends DashboardScreenState {
  // Services
  final ExpenseService _expenseService = ExpenseService();
  final BudgetService _budgetService = BudgetService();
  final IncomeService _incomeService = IncomeService();
  final DebtService _debtService = DebtService();
  
  // Controllers
  final TextEditingController _budgetController = TextEditingController();
  
  // State variables
  late DateTime _selectedDate;
  double _totalExpenses = 0.0;
  double _totalIncome = 0.0;
  double _monthlyBudget = 0.0;
  bool _isEditingBudget = false;
  List<expense_model.Expense> _recentExpenses = [];
  List<expense_model.Expense> _expenses = [];
  List<Debt> _activeDebts = [];

  // Formatters
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _monthYearFormat = DateFormat('MMMM yyyy');

  // We'll get BalanceService in build method instead of storing it as a field

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadUserData(context);
      }
    });
  }

  Future<void> _saveBudget() async {
    if (!mounted) return;
    
    final newBudget = double.tryParse(_budgetController.text) ?? 0.0;
    if (newBudget <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid budget amount')),
        );
      }
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _budgetService.setMonthlyBudget(userId, newBudget);
      if (mounted) {
        setState(() {
          _monthlyBudget = newBudget;
          _isEditingBudget = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error saving budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update budget: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Future<void> _loadBudget() async {
    if (!mounted) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final budget = await _budgetService.getMonthlyBudget(userId) ?? 0.0;
      if (mounted) {
        setState(() {
          _monthlyBudget = budget;
          _budgetController.text = budget.toStringAsFixed(2);
        });
      }
    } catch (e) {
      debugPrint('Error loading budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load budget.')),
        );
      }
    }
  }

  @override
  Future<void> _loadExpenses(BuildContext context) async {
    if (!mounted) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      if (mounted) {
        setState(() => isLoading = true);
      }
      
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate = _selectedDate.month < 12 
          ? DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59)
          : DateTime(_selectedDate.year + 1, 1, 0, 23, 59, 59);

      // Load expenses and incomes in parallel
      final expenseFuture = _expenseService.getExpensesByDateRange(
        userId,
        startDate,
        endDate,
      );

      // Convert DateTime to millisecondsSinceEpoch for the income service
      final incomeFuture = _incomeService.getIncomesByDateRange(
        userId,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ).first;

      // Wait for both futures to complete
      final results = await Future.wait([expenseFuture, incomeFuture]);
      
      if (!mounted) return;
      
      final expenses = results[0] as List<expense_model.Expense>;
      final incomes = results[1] as List<dynamic>;
      
      // Process expenses and calculate totals
      final totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final totalIncome = incomes.fold(0.0, (sum, income) => sum + (income.amount as num).toDouble());
      final newBalance = totalIncome - totalExpenses;
      
      if (mounted) {
        // Update the balance service first
        final balanceService = Provider.of<BalanceService>(context, listen: false);
        balanceService.updateBalance(newBalance);
        
        // Then update the local state
        setState(() {
          _expenses = List<expense_model.Expense>.from(expenses)
            ..sort((a, b) => b.date.compareTo(a.date));
          _recentExpenses = _expenses.take(5).toList();
          _totalExpenses = totalExpenses;
          _totalIncome = totalIncome;
        });
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load expenses. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Even if there's an error, ensure loading is false
      if (mounted) {
        setState(() => isLoading = false);
      }
      rethrow; // Re-throw to allow error handling up the chain
    }
  }

  double _moneyOwed = 0.0;  // Money you owe to others
  double _moneyBorrowed = 0.0; // Money others owe you
  // Money owed to others minus money borrowed from others

  Future<void> _loadDebts() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final debts = await _debtService.getActiveDebts(userId).first;
      
      // Calculate money owed and money borrowed
      double owed = 0.0;
      double borrowed = 0.0;
      
      for (var debt in debts) {
        final remaining = debt.amount - debt.paidAmount;
        
        switch (debt.type) {
          // Money you owe to others
          case DebtType.borrowed:
          case DebtType.loan:
          case DebtType.creditCard:
            owed += remaining;
            break;
            
          // Money others owe to you
          case DebtType.lent:
            borrowed += remaining;
            break;
        }
      }
      
      if (mounted) {
        setState(() {
          _moneyOwed = owed;
          _moneyBorrowed = borrowed;
          _activeDebts = debts.take(3).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading debts: $e');
      rethrow;
    }
  }

  void _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && pickedDate != _selectedDate && mounted) {
      setState(() => _selectedDate = pickedDate);
      await loadUserData(context);
    }
  }

  void _previousMonth() {
    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    });
    loadUserData(context);
  }

  void _nextMonth() {
    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    });
    loadUserData(context);
  }

  // Method to navigate to add debt screen
  @override
  void navigateToAddDebt() async {
    if (!mounted) return;
    final debtService = Provider.of<DebtService>(context, listen: false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDebtScreen(debtService: debtService),
      ),
    );
    // Refresh all data when returning from adding a debt
    if (mounted) {
      await loadUserData(context);
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _previousMonth,
          ),
          TextButton(
            onPressed: _showDatePicker,
            child: Text(
              _monthYearFormat.format(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard() {
    final theme = Theme.of(context);
    final budgetUsed = _monthlyBudget > 0 ? _totalExpenses / _monthlyBudget : 0;
    final isOverBudget = budgetUsed > 1.0;
    final primaryColor = theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A148C),  // Deep purple
            Color(0xFF6A1B9A),  // Slightly lighter purple
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple[900]!.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Budget',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!_isEditingBudget)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onPressed: () {
                        _budgetController.text = _monthlyBudget.toStringAsFixed(2);
                        setState(() => _isEditingBudget = true);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditingBudget)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹',
                        prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.check, color: Colors.green, size: 20),
                      onPressed: _saveBudget,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _isEditingBudget = false),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              )
            else
              Text(
                _currencyFormat.format(_monthlyBudget),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  letterSpacing: 0.5,
                ),
              ),
            const SizedBox(height: 20),
            Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.white.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: (isOverBudget ? 1.0 : budgetUsed).toDouble(),
                  backgroundColor: Colors.transparent,
                  color: isOverBudget ? errorColor : Colors.white,
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${_currencyFormat.format(_totalExpenses)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isOverBudget ? errorColor : primaryColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(budgetUsed * 100).toStringAsFixed(0)}% ${isOverBudget ? 'Over' : 'Used'}' ,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isOverBudget ? errorColor : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    final theme = Theme.of(context);
    final netBalance = _totalIncome - _totalExpenses;
    final isPositiveBalance = netBalance >= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.03),
              theme.colorScheme.primary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPositiveBalance ? Icons.trending_up : Icons.trending_down,
                      color: isPositiveBalance ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Net Balance Highlight
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPositiveBalance 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Balance',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _currencyFormat.format(netBalance.abs()),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositiveBalance ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isPositiveBalance ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isPositiveBalance ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Income vs Expenses
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      'Income',
                      _totalIncome,
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.green,
                      iconBgColor: Colors.green.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFinancialCard(
                      'Expenses',
                      _totalExpenses,
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.red,
                      iconBgColor: Colors.red.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Debts Section
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      'You Owe',
                      _moneyOwed,
                      icon: Icons.arrow_upward_rounded,
                      color: Colors.orange[700]!,
                      showCurrency: _moneyOwed > 0,
                      iconBgColor: Colors.orange.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFinancialCard(
                      'Owed to You',
                      _moneyBorrowed,
                      icon: Icons.arrow_downward_rounded,
                      color: Colors.green[700]!,
                      showCurrency: _moneyBorrowed > 0,
                      iconBgColor: Colors.green.withValues(alpha: 0.1),
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

  Widget _buildFinancialCard(
    String title,
    double amount, {
    required IconData icon,
    required Color color,
    String prefix = '',
    bool showCurrency = true,
    Color? iconBgColor,
  }) {
    final bgColor = iconBgColor ?? color.withValues(alpha: 0.1);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$prefix${showCurrency ? _currencyFormat.format(amount) : '-'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSection() {
    if (_activeDebts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Debts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DebtsListScreen(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: _activeDebts.length,
            itemBuilder: (context, index) => _buildDebtItem(_activeDebts[index]),
          ),
        ),
      ],
    );
  }

  Future<void> _showPaymentDialog(BuildContext context, Debt debt) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final remainingAmount = debt.amount - debt.paidAmount;
    final debtService = Provider.of<DebtService>(context, listen: false);
    final isLent = debt.type == DebtType.lent;
    
    // Set default amount to remaining amount
    amountController.text = remainingAmount.toStringAsFixed(2);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isLent ? 'Receive Payment' : 'Make Payment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isLent ? 'Amount to Receive' : 'Amount to Pay'}: ${_currencyFormat.format(remainingAmount)}',
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
                      labelText: isLent ? 'Amount Received' : 'Amount Paid',
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
                          content: Text(isLent 
                            ? 'Payment received successfully' 
                            : 'Payment recorded successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pop();
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
                backgroundColor: isLent ? Colors.green : Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(isLent ? 'Receive' : 'Pay Now'),
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
        '$label (${_currencyFormat.format(amount)})',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildDebtItem(Debt debt) {
    final isOverdue = debt.dueDate.isBefore(DateTime.now()) && !debt.isPaid;
    final remainingAmount = debt.amount - debt.paidAmount;
    final progress = debt.amount > 0 ? (debt.paidAmount / debt.amount).clamp(0.0, 1.0) : 0.0;
    final daysUntilDue = debt.dueDate.difference(DateTime.now()).inDays;
    
    // Calculate status text
    String statusText;
    if (debt.isPaid) {
      statusText = 'Paid';
    } else if (isOverdue) {
      statusText = 'Overdue';
    } else if (daysUntilDue == 0) {
      statusText = 'Due today';
    } else if (daysUntilDue == 1) {
      statusText = 'Due tomorrow';
    } else if (daysUntilDue < 0) {
      statusText = '${daysUntilDue.abs()} days overdue';
    } else {
      statusText = 'Due in $daysUntilDue days';
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12, bottom: 8, top: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7E57C2),  // Deep purple
            Color(0xFFB39DDB),  // Light purple
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        debt.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white,
                          backgroundColor: statusText.startsWith('Due in') ? null : Colors.black.withValues(alpha: 0.2),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Amount and due date
                Text(
                  _currencyFormat.format(remainingAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'of ${_currencyFormat.format(debt.amount)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 5,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Progress text and Pay button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% paid',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _dateFormat.format(debt.dueDate),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        if (!debt.isPaid) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showPaymentDialog(context, debt),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                debt.type == DebtType.lent ? 'Receive' : 'Pay',
                                style: TextStyle(
                                  color: debt.type == DebtType.lent ? Colors.green : Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildRecentTransactions() {
    if (_recentExpenses.isEmpty) {
      return const Center(
        child: Text('No recent transactions'),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
            const Color(0xFF7E57C2), 
           const Color(0xFFB39DDB),
          ],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator();
    }

    return RefreshIndicator(
      onRefresh: () => loadUserData(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 16),
                  _buildBudgetCard(),
                  const SizedBox(height: 16),
                  _buildFinancialOverview(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildDebtSection(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildRecentTransactions(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}
