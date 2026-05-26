import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/credit_card.dart';
import 'package:expense_tracker/services/credit_card_service.dart';
import 'package:intl/intl.dart';

class AddCreditCardScreen extends StatefulWidget {
  const AddCreditCardScreen({super.key});

  @override
  State<AddCreditCardScreen> createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _lastFourDigitsController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _currentBalanceController = TextEditingController();
  final _minimumDueController = TextEditingController();
  final _interestRateController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  DateTime _statementDate = DateTime.now();

  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

  double get utilizationRate {
    final limit = double.tryParse(_creditLimitController.text) ?? 0;
    final balance = double.tryParse(_currentBalanceController.text) ?? 0;
    if (limit == 0) return 0;
    return (balance / limit) * 100;
  }

  double get availableCredit {
    final limit = double.tryParse(_creditLimitController.text) ?? 0;
    final balance = double.tryParse(_currentBalanceController.text) ?? 0;
    return limit - balance;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _cardNameController.dispose();
    _lastFourDigitsController.dispose();
    _creditLimitController.dispose();
    _currentBalanceController.dispose();
    _minimumDueController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  Future<void> _saveCreditCard() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final creditCardService = CreditCardService();
    final creditCard = CreditCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      bankName: _bankNameController.text,
      cardName: _cardNameController.text,
      lastFourDigits: _lastFourDigitsController.text,
      creditLimit: double.parse(_creditLimitController.text),
      currentBalance: double.parse(_currentBalanceController.text),
      minimumDue: double.parse(_minimumDueController.text),
      dueDate: _dueDate,
      interestRate: double.parse(_interestRateController.text),
      statementDate: _statementDate,
    );

    try {
      await creditCardService.addCreditCard(creditCard);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credit card added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add credit card: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Credit Card', style: TextStyle(fontWeight: FontWeight.bold)),
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
              // Bank Name
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Card Name
              TextFormField(
                controller: _cardNameController,
                decoration: InputDecoration(
                  labelText: 'Card Name (e.g., Platinum, Gold)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Last Four Digits
              TextFormField(
                controller: _lastFourDigitsController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Last 4 Digits',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  counterText: '',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (value!.length != 4) return 'Must be 4 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Credit Limit
              TextFormField(
                controller: _creditLimitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Credit Limit',
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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Current Balance
              TextFormField(
                controller: _currentBalanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Current Balance',
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
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Minimum Due
              TextFormField(
                controller: _minimumDueController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minimum Due',
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
              ),
              const SizedBox(height: 16),

              // Statement Date
              ListTile(
                title: const Text('Statement Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_statementDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _statementDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _statementDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Due Date
              ListTile(
                title: const Text('Payment Due Date'),
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
              const SizedBox(height: 24),

              // Credit Utilization Summary
              if (_creditLimitController.text.isNotEmpty && _currentBalanceController.text.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: utilizationRate > 70
                      ? Colors.red.withValues(alpha: 0.1)
                      : utilizationRate > 30
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Credit Utilization',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Available Credit', _currencyFormat.format(availableCredit)),
                        _buildSummaryRow('Utilization Rate', '${utilizationRate.toStringAsFixed(1)}%'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: utilizationRate / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            utilizationRate > 70
                                ? Colors.red
                                : utilizationRate > 30
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          utilizationRate > 70
                              ? 'Critical: High utilization affects credit score'
                              : utilizationRate > 30
                                  ? 'Warning: Keep utilization below 30%'
                                  : 'Good: Healthy credit utilization',
                          style: TextStyle(
                            fontSize: 12,
                            color: utilizationRate > 70
                                ? Colors.red
                                : utilizationRate > 30
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
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
                  onPressed: _saveCreditCard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Add Credit Card',
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
