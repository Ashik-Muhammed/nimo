import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/models/expense.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final DateTime _selectedDate = DateTime.now();
  String _selectedPeriod = 'monthly';
  bool _showLineChart = true; 
  DateTimeRange? _customDateRange;
  bool _isLoading = true;
  Map<String, double> _categoryTotals = {};
  List<Expense> _expenses = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);

    DateTime startDate;
    DateTime endDate;

    if (_selectedPeriod == 'custom' && _customDateRange != null) {
      startDate = _customDateRange!.start;
      endDate = _customDateRange!.end;
    } else if (_selectedPeriod == 'weekly') {
      startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      endDate = startDate.add(const Duration(days: 6));
    } else { // monthly
      startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59, 999);
    }

    try {
      final expenses = await _expenseService.getExpensesByDateRange(
        _userId!,
        startDate,
        endDate,
      );

      _expenses = expenses;
      _calculateCategoryTotals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateCategoryTotals() {
    final categoryMap = <String, double>{};
    
    for (var expense in _expenses) {
      categoryMap.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    setState(() {
      _categoryTotals = Map.fromEntries(
        categoryMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      );
    });
  }

  Future<void> _selectDateRange() async {
    // Current timestamp for date calculations
    final initialDateRange = DateTimeRange(
      start: _selectedDate.subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ?? initialDateRange,
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'custom';
      });
      _loadExpenses();
    }
  }

  List<PieChartSectionData> _getPieChartSections() {
    final total = _categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    
    return _categoryTotals.entries.map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      
      return PieChartSectionData(
        color: _getColorForCategory(entry.key),
        value: entry.value,
        title: '${entry.key}\n$percentage%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getColorForCategory(String category) {
    // Generate a consistent color based on the category name
    final index = category.codeUnits.fold(0, (sum, code) => sum + code) % Colors.primaries.length;
    return Colors.primaries[index];
  }

  late List<BarChartGroupData> _cachedBarData;
  DateTime? _lastBarUpdateTime;
  
  List<BarChartGroupData> _getBarChartData() {
    final now = DateTime.now();
    // Only recalculate if data has changed or it's the first time
    if (_lastBarUpdateTime != null && _lastBarUpdateTime!.isAtSameMomentAs(now)) {
      return _cachedBarData;
    }
    
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyTotals = List.filled(daysInMonth, 0.0);
    double maxDailyAmount = 0;

    // Process expenses
    for (var expense in _expenses) {
      final date = expense.date;
      if (date.month == now.month && date.year == now.year) {
        final day = date.day - 1;
        if (day >= 0 && day < daysInMonth) {
          dailyTotals[day] += expense.amount;
          if (dailyTotals[day] > maxDailyAmount) {
            maxDailyAmount = dailyTotals[day];
          }
        }
      }
    }

    final barGroups = List<BarChartGroupData>.generate(daysInMonth, (index) {
      final isToday = index + 1 == now.day;
      final color = isToday 
          ? Colors.orange 
          : Theme.of(context).primaryColor.withValues(alpha: 0.8);
          
      return BarChartGroupData(
        x: index + 1, // Start from day 1 instead of 0
        barRods: [
          BarChartRodData(
            toY: dailyTotals[index],
            color: color,
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
    
    _cachedBarData = barGroups;
    _lastBarUpdateTime = now;
    return barGroups;
  }
  
  double _getMaxDailyAmount() {
    if (_expenses.isEmpty) return 100;
    // Find the maximum daily amount and add 20% padding
    final now = DateTime.now();
    final dailyTotals = <int, double>{};
    // Process expenses
    for (var expense in _expenses) {
      final date = expense.date; // Update this line
      if (date.month == now.month && date.year == now.year) {
        final day = date.day;
        dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
      }
    }
    
    return (dailyTotals.values.fold(0.0, (max, amount) => amount > max ? amount : max) * 1.2).roundToDouble();
  }

  late List<FlSpot> _cachedLineSpots;
  DateTime? _lastUpdateTime;
  
  List<FlSpot> _getLineChartData() {
    final now = DateTime.now();
    // Only recalculate if data has changed or it's the first time
    if (_lastUpdateTime != null && _lastUpdateTime!.isAtSameMomentAs(now)) {
      return _cachedLineSpots;
    }
    
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyTotals = List.filled(daysInMonth, 0.0);
    double maxAmount = 0;

    // Process expenses
    for (var expense in _expenses) {
      final date = expense.date;
      if (date.month == now.month && date.year == now.year) {
        final day = date.day - 1;
        if (day >= 0 && day < daysInMonth) {
          dailyTotals[day] += expense.amount;
          if (dailyTotals[day] > maxAmount) {
            maxAmount = dailyTotals[day];
          }
        }
      }
    }

    // Generate smoothed data points
    double runningTotal = 0;
    final spots = <FlSpot>[];
    
    // Add initial point
    spots.add(const FlSpot(1, 0));
    
    // Generate cumulative data points
    for (int i = 0; i < daysInMonth; i++) {
      runningTotal += dailyTotals[i];
      spots.add(FlSpot(
        (i + 1).toDouble(),
        runningTotal,
      ));
    }
    
    _cachedLineSpots = spots;
    _lastUpdateTime = now;
    return spots;
  }
  
  double _getMaxYValue() {
    if (_expenses.isEmpty) return 100;
    // Add 20% padding to the max value for better visualization
    return _expenses.fold(0.0, (sum, e) => sum + e.amount) * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Period Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPeriodButton('Weekly', Icons.calendar_view_week),
                      _buildPeriodButton('Monthly', Icons.calendar_today),
                      _buildPeriodButton('Custom', Icons.date_range),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  _buildSummaryCards(),
                  const SizedBox(height: 24),

                  // Toggle between charts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Spending Overview',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          _buildChartToggleButton('Pie', !_showLineChart),
                          const SizedBox(width: 8),
                          _buildChartToggleButton('Line', _showLineChart),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Chart Container
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showLineChart
                        ? _buildLineChart()
                        : _buildPieChart(),
                  ),
                  const SizedBox(height: 24),


                  // Bar Chart - Daily Spending
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Daily Spending',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: _getMaxDailyAmount() / 4,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey[200]!,
                                    strokeWidth: 1,
                                  ),
                                ),
                                alignment: BarChartAlignment.spaceBetween,
                                maxY: _getMaxDailyAmount(),
                                minY: 0,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipBgColor: Colors.blueGrey[800]!,
                                    tooltipRoundedRadius: 8,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        'Day ${group.x.toInt()}\n${rod.toY > 0 ? '₹${rod.toY.toStringAsFixed(0)}' : 'No data'}\n${rod.toY > 0 ? '(${((rod.toY / _expenses.fold(0.0, (sum, e) => sum + e.amount)) * 100).toStringAsFixed(1)}% of total)' : ''}',
                                        const TextStyle(color: Colors.white, height: 1.5),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 24,
                                      interval: DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day > 20 ? 5 : 2,
                                      getTitlesWidget: (value, meta) {
                                        return value % 5 == 1 || value == 1 || value.toInt() == DateTime.now().day
                                            ? Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  '${value.toInt()}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: value.toInt() == DateTime.now().day 
                                                        ? Theme.of(context).primaryColor 
                                                        : Colors.grey,
                                                    fontWeight: value.toInt() == DateTime.now().day 
                                                        ? FontWeight.bold 
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 50,
                                      interval: _getMaxDailyAmount() / 4,
                                      getTitlesWidget: (value, meta) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: Text(
                                            '₹${value.toInt()}',
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            textAlign: TextAlign.right,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                barGroups: _getBarChartData(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category List
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryList(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodButton(String period, IconData icon) {
    final isSelected = _selectedPeriod == period.toLowerCase();
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => _selectedPeriod = period.toLowerCase());
        _loadExpenses();
      },
      icon: Icon(icon, color: isSelected ? Colors.white : null),
      label: Text(period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : null,
      ),
    );
  }

  Widget _buildSummaryCards() {
    final total = _expenses.fold(0.0, (sum, e) => sum + e.amount);
    final avg = _expenses.isEmpty ? 0 : total / _expenses.length;
    final maxCategory = _categoryTotals.entries.firstOrNull;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildSummaryCard('Total', '₹${total.toStringAsFixed(2)}', Icons.currency_rupee),
          const SizedBox(width: 12),
          _buildSummaryCard('Avg/Expense', '₹${avg.toStringAsFixed(2)}', Icons.assessment),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Top Category',
            maxCategory?.key ?? 'N/A',
            Icons.category,
            subtitle: maxCategory != null ? '₹${maxCategory.value.toStringAsFixed(2)}' : null,
          ),
          const SizedBox(width: 4), // Add a small padding at the end
        ],
      ),
    );
  }

  Widget _buildChartToggleButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showLineChart = (label == 'Line');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final lineData = _getLineChartData();
    final maxY = _getMaxYValue();
    final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Cumulative Spending',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.7,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: daysInMonth > 20 ? 5 : 2,
                        getTitlesWidget: (value, meta) {
                          return value % 5 == 0 || value == 1 || value == daysInMonth
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: maxY > 0 ? (maxY / 4) : 1000,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '₹${value.toInt()}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  minX: 0,
                  maxX: daysInMonth.toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey[800]!,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            'Day ${spot.x.toInt()}\n₹${spot.y.toStringAsFixed(2)}',
                            const TextStyle(color: Colors.white, height: 1.5),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    touchCallback: (event, response) {},
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: lineData,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
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

  Widget _buildPieChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Category Breakdown',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: _categoryTotals.isEmpty
                  ? const Center(child: Text('No category data available'))
                  : PieChart(
                      PieChartData(
                        sections: _getPieChartSections(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        centerSpaceColor: Colors.grey[100],
                        startDegreeOffset: 270,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, {String? subtitle}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 160),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_categoryTotals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No categories found')),
        ),
      );
    }

    final total = _categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categoryTotals.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = _categoryTotals.entries.elementAt(index);
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          
          return ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getColorForCategory(entry.key).withValues(red: 255, green: 255, blue: 255, alpha: 0.2 * 255),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getColorForCategory(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            title: Text(entry.key),
            trailing: Text(
              '\₹${entry.value.toStringAsFixed(2)} ($percentage%)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}
