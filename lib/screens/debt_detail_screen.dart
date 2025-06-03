import 'package:flutter/material.dart';
// Provider is used via Provider.of in the code
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../services/debt_service.dart';

class DebtDetailScreen extends StatefulWidget {
  final Debt debt;
  final DebtService debtService;

  const DebtDetailScreen({
    super.key,
    required this.debt,
    required this.debtService,
  });

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late final TextEditingController _lenderController;
  late DateTime _dueDate;
  late Debt _debt;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _currencyFormat = NumberFormat.currency(symbol: '₹', locale: 'en_IN');
  final _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _debt = widget.debt;
    _amountController = TextEditingController(text: _debt.amount.toString());
    _notesController = TextEditingController(text: _debt.notes ?? '');
    _lenderController = TextEditingController(text: _debt.lender ?? '');
    _dueDate = _debt.dueDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _lenderController.dispose();
    super.dispose();
  }

  Future<void> _updateDebt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedDebt = _debt.copyWith(
        amount: double.tryParse(_amountController.text) ?? 0,
        notes: _notesController.text,
        lender: _lenderController.text,
        dueDate: _dueDate,
      );

      await widget.debtService.updateDebt(updatedDebt);
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating debt: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteDebt() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Debt'),
        content: const Text('Are you sure you want to delete this debt? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await widget.debtService.deleteDebt(_debt.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting debt: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLent = _debt.type == DebtType.lent;
    final remainingAmount = _debt.amount - _debt.paidAmount;
    final progress = _debt.amount > 0 ? _debt.paidAmount / _debt.amount : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${isLent ? 'Money Owed to You' : 'Money You Owe'}' 's Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateDebt,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _debt.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: progress.toDouble(),
                              backgroundColor: Colors.grey[200],
                              color: isLent ? Colors.green : Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid: ${_currencyFormat.format(_debt.paidAmount)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'Remaining: ${_currencyFormat.format(remainingAmount)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lender/Recipient Field
                    TextFormField(
                      controller: _lenderController,
                      decoration: InputDecoration(
                        labelText: isLent ? 'Borrower' : 'Lender',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Due Date Picker
                    InkWell(
                      onTap: _showDatePicker,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateFormat.format(_dueDate)),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Delete Button
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Delete Debt',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: _isLoading ? null : _deleteDebt,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
