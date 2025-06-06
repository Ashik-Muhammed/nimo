import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/services/debt_service.dart';
import 'package:expense_tracker/models/debt.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key, required this.debtService});
  
  final DebtService debtService;
  
  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _lenderController = TextEditingController();
  final _notesController = TextEditingController();
  final _interestRateController = TextEditingController();
  late DateTime _dueDate;
  DebtType _debtType = DebtType.borrowed;
  bool _isLoading = false;
  bool _isOffline = false;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _dueDate = DateTime.now().add(const Duration(days: 30));
    _checkConnectivity();
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
  
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (mounted) {
        setState(() {
          _isOffline = connectivityResult == ConnectivityResult.none;
        });
      }
      
      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen((result) {
        if (mounted) {
          setState(() {
            _isOffline = result == ConnectivityResult.none;
          });
        }
      });
    } on PlatformException catch (e) {
      debugPrint('Could not check connectivity status: $e');
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dueDate && mounted) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final debt = Debt(
        id: '', // Will be generated by the service
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text),
        lender: _lenderController.text.trim(),
        dueDate: _dueDate,
        type: _debtType,
        isPaid: false,
        userId: userId,
        createdAt: DateTime.now(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        interestRate: _interestRateController.text.trim().isNotEmpty 
            ? double.tryParse(_interestRateController.text.trim())
            : null,
      );

      await widget.debtService.addDebt(debt);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save debt: $e')),
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
        title: const Text('Add Debt'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.orange,
              child: const Text(
                'Offline Mode - Changes will sync when back online',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a title';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Amount
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(),
                              prefixText: '\$',
                            ),
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

                          // Lender
                          TextFormField(
                            controller: _lenderController,
                            decoration: const InputDecoration(
                              labelText: 'Lender/Borrower',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Debt Type
                          DropdownButtonFormField<DebtType>(
                            value: _debtType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: DebtType.borrowed,
                                child: Text('Borrowed (You owe)'),
                              ),
                              DropdownMenuItem(
                                value: DebtType.lent,
                                child: Text('Lent (You are owed)'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _debtType = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Due Date
                          ListTile(
                            title: const Text('Due Date'),
                            subtitle: Text(
                              '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _selectDueDate,
                          ),
                          const SizedBox(height: 16),

                          // Interest Rate (Optional)
                          TextFormField(
                            controller: _interestRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Interest Rate % (Optional)',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Notes
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Save Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveDebt,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Save Debt', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
