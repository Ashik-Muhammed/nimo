import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:expense_tracker/services/loan_service.dart';
import 'package:expense_tracker/models/debt.dart';
import 'package:intl/intl.dart';

class AddLoanScreen extends StatefulWidget {
  final DebtService debtService;

  const AddLoanScreen({super.key, required this.debtService});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _tenureMonthsController = TextEditingController();
  final _lenderController = TextEditingController();
  final _notesController = TextEditingController();

  DebtType _selectedLoanType = DebtType.homeLoan;
  DateTime _startDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 365));

  double _calculatedEMI = 0;
  double _totalInterest = 0;
  double _totalPayable = 0;

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _tenureMonthsController.dispose();
    _lenderController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateLoanDetails() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final interestRate = double.tryParse(_interestRateController.text) ?? 0;
    final tenureMonths = int.tryParse(_tenureMonthsController.text) ?? 0;

    if (amount > 0 && interestRate > 0 && tenureMonths > 0) {
      setState(() {
        _calculatedEMI = LoanService.calculateEMI(
          principal: amount,
          annualInterestRate: interestRate,
          tenureMonths: tenureMonths,
        );
        _totalInterest = LoanService.calculateTotalInterest(
          principal: amount,
          annualInterestRate: interestRate,
          tenureMonths: tenureMonths,
        );
        _totalPayable = amount + _totalInterest;
      });
    }
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final amount = double.parse(_amountController.text);
    final interestRate = double.parse(_interestRateController.text);
    final tenureMonths = int.parse(_tenureMonthsController.text);

    // Calculate EMI and amortization schedule
    final emi = LoanService.calculateEMI(
      principal: amount,
      annualInterestRate: interestRate,
      tenureMonths: tenureMonths,
    );

    final schedule = LoanService.generateAmortizationSchedule(
      principal: amount,
      annualInterestRate: interestRate,
      tenureMonths: tenureMonths,
      startDate: _startDate,
    );

    final amortizationSchedule = LoanService.serializeSchedule(schedule);

    final loan = Debt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      amount: amount,
      dueDate: _dueDate,
      userId: userId,
      type: _selectedLoanType,
      interestRate: interestRate,
      lender: _lenderController.text.trim(),
      startDate: _startDate,
      tenureMonths: tenureMonths,
      emi: emi,
      amortizationSchedule: amortizationSchedule,
      notes: _notesController.text.trim(),
    );

    try {
      await widget.debtService.addDebt(loan);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loan added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add loan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Loan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan Type Selection
              const Text(
                'Loan Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<DebtType>(
                value: _selectedLoanType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: DebtType.values
                    .where((type) => type.isLoan)
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLoanType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Loan Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Loan Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Loan Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Loan Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid amount';
                  return null;
                },
                onChanged: (_) => _calculateLoanDetails(),
              ),
              const SizedBox(height: 16),

              // Interest Rate
              TextFormField(
                controller: _interestRateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Annual Interest Rate (%)',
                  suffixText: '%',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Invalid rate';
                  return null;
                },
                onChanged: (_) => _calculateLoanDetails(),
              ),
              const SizedBox(height: 16),

              // Tenure
              TextFormField(
                controller: _tenureMonthsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Loan Tenure (Months)',
                  suffixText: 'months',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Invalid tenure';
                  return null;
                },
                onChanged: (_) => _calculateLoanDetails(),
              ),
              const SizedBox(height: 16),

              // Lender
              TextFormField(
                controller: _lenderController,
                decoration: InputDecoration(
                  labelText: 'Lender/Bank Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Due Date
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_dueDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2050),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              // Loan Calculation Summary
              if (_calculatedEMI > 0) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Loan Summary',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Monthly EMI', _currencyFormat.format(_calculatedEMI)),
                        _buildSummaryRow('Total Interest', _currencyFormat.format(_totalInterest)),
                        _buildSummaryRow('Total Payable', _currencyFormat.format(_totalPayable)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveLoan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Add Loan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
