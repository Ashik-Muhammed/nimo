import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/screens/dashboard_screen.dart';
import 'package:expense_tracker/screens/expense_list_screen.dart';
import 'package:expense_tracker/screens/income_list_screen.dart';
import 'package:expense_tracker/screens/debts_list_screen.dart';
import 'package:expense_tracker/screens/add_debt_screen.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/screens/add_income_screen.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Placeholder widgets/services to prevent errors (replace with real implementations)
class MonthSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthSelector({
    super.key,
    required this.selectedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: Icon(Icons.arrow_left), onPressed: onPreviousMonth),
        Text('${selectedDate.month}/${selectedDate.year}'),
        IconButton(icon: Icon(Icons.arrow_right), onPressed: onNextMonth),
      ],
    );
  }
}

class TotalExpenseCard extends StatelessWidget {
  final int month;
  final int year;

  const TotalExpenseCard({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context, listen: false);
    
    return StreamBuilder<double>(
      stream: expenseService.getTotalForMonthStream(month, year),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading total for $month/$year'),
            ),
          );
        }
        
        final total = snapshot.data ?? 0.0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Total for $month/$year: ₹${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController = TextEditingController();
    _loadUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() {
    });
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildFloatingActionButton() {
    if (_tabController.index == 0) return Container(); // No FAB on dashboard
    
    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 1) {
          // Expenses tab - Add new expense
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        } else if (_tabController.index == 2) {
          // Income tab - Add new income
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddIncomeScreen()),
          );
        } else if (_tabController.index == 3) {
          // Debts tab - Add new debt
          final debtService = Provider.of<DebtService>(context, listen: false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDebtScreen(debtService: debtService),
            ),
          );
        }
      },
      child: Icon(
        _tabController.index == 1 
          ? Icons.add 
          : _tabController.index == 2 
            ? Icons.attach_money 
            : Icons.credit_card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    body: SafeArea(
      child: Column(
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Centered title with right-aligned actions
                Row(
                  children: [
                    // Centered title
                    Expanded(
                      child: Center(
                        child: Text(
                          "NIMO",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.1,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    // Right-aligned actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _signOut(
                          
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Greeting
              
              ],
            ),
          ),

          // Tabs
          Material(
            color: theme.scaffoldBackgroundColor,
            elevation: 2,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.hintColor,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                Tab(icon: Icon(Icons.money_off), text: 'Expenses'),
                Tab(icon: Icon(Icons.attach_money), text: 'Income'),
                Tab(icon: Icon(Icons.credit_card), text: 'Debts'),
                Tab(icon: Icon(Icons.bar_chart_sharp), text: 'Analytics'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DashboardScreen(key: _dashboardKey),
                const ExpenseListScreen(),
                const IncomeListScreen(),
                const DebtsListScreen(),
                const AnalyticsScreen(),
              ],
            ),
          ),
        ],
      ),
    ),
    floatingActionButton: _buildFloatingActionButton(),
  );
}


}


