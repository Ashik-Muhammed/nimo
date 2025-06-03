import 'package:flutter/material.dart';
import 'package:expense_tracker/models/debt.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:intl/intl.dart';

class DebtManagementScreen extends StatefulWidget {
  final Debt? debt;

  const DebtManagementScreen({super.key, this.debt});

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _lenderController = TextEditingController();
  final _notesController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _debtService = DebtService();
  
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  DebtType _debtType = DebtType.borrowed;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _titleController.text = widget.debt!.title;
      _amountController.text = widget.debt!.amount.toStringAsFixed(2);
      _lenderController.text = widget.debt!.lender ?? '';
      _notesController.text = widget.debt!.notes ?? '';
      _interestRateController.text = widget.debt!.interestRate?.toString() ?? '';
      _dueDate = widget.debt!.dueDate;
      _debtType = widget.debt!.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _lenderController.dispose();
    _notesController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final debt = Debt(
        id: widget.debt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        dueDate: _dueDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        userId: '', // Will be set in the service
        type: _debtType,
        interestRate: _interestRateController.text.trim().isNotEmpty 
            ? double.tryParse(_interestRateController.text.trim())
            : null,
        lender: _lenderController.text.trim().isNotEmpty ? _lenderController.text.trim() : null,
        isPaid: false,
      );

      if (widget.debt == null) {
        await _debtService.addDebt(debt);
      } else {
        await _debtService.updateDebt(debt);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving debt: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debt == null ? 'Add New Debt' : 'Edit Debt'),
        actions: [
          if (widget.debt != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Debt'),
                    content: const Text('Are you sure you want to delete this debt?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  try {
                    await _debtService.deleteDebt(widget.debt!.id);
                    if (mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting debt: $e')),
                      );
                    }
                  }
                }
              },
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Debt Type
                    DropdownButtonFormField<DebtType>(
                      value: _debtType,
                      decoration: const InputDecoration(
                        labelText: 'Debt Type',
                        border: OutlineInputBorder(),
                      ),
                      items: DebtType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _debtType = value);
                        }
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a debt type';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Lender
                    TextFormField(
                      controller: _lenderController,
                      decoration: const InputDecoration(
                        labelText: 'Lender (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interest Rate
                    TextFormField(
                      controller: _interestRateController,
                      decoration: const InputDecoration(
                        labelText: 'Interest Rate % (optional)',
                        suffixText: '%',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final rate = double.tryParse(value);
                          if (rate == null || rate < 0) {
                            return 'Please enter a valid interest rate';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Due Date
                    ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(DateFormat('MMM d, y').format(_dueDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveDebt,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Save Debt'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
