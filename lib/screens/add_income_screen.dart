import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/income.dart';
import 'package:expense_tracker/services/income_service.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

class AddIncomeScreen extends StatefulWidget {
  final Income? income;

  const AddIncomeScreen({super.key, this.income});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _sourceController = TextEditingController();
  final _incomeService = IncomeService();

  DateTime _selectedDate = DateTime.now();
  DateTime? _endDate;
  bool _isRecurring = false;
  bool _isLoading = false;
  bool _isOffline = false;
  IncomeFrequency _selectedFrequency = IncomeFrequency.monthly;

  List<Category> _sources = [];
  final List<String> _defaultSources = [
    'Salary',
    'Freelancing',
    'Business',
    'Rental',
    'Gift',
    'Bonus',
    'Side Hustle',
  ];

  String? _selectedSource;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadSources();
    if (widget.income != null) {
      _loadIncomeData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() => _isOffline = connectivityResult == ConnectivityResult.none);

    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() => _isOffline = result == ConnectivityResult.none);
      }
    });
  }

  Future<void> _loadSources() async {
    try {
      final categories = await _incomeService.getCategories().first;
      setState(() {
        _sources = categories;
        if (_sources.isEmpty) {
          _sources = _defaultSources
              .map((name) => Category(
                    id: name.toLowerCase(),
                    name: name,
                    type: 'income',
                    userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  ))
              .toList();
        }
        if (widget.income == null && _sources.isNotEmpty) {
          _sourceController.text = _sources.first.name;
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load income sources')),
        );
      }
    }
  }

  void _loadIncomeData() {
    final income = widget.income!;
    _titleController.text = income.title;
    _amountController.text = income.amount.toString();
    _notesController.text = income.notes ?? '';
    _selectedDate = income.date;
    _sourceController.text = income.source;
    _isRecurring = income.isRecurring;
    _selectedFrequency = income.frequency;
    _endDate = income.endDate;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _selectedDate.add(const Duration(days: 30)),
      firstDate: _selectedDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate && mounted) {
      setState(() => _endDate = picked);
    }
  }

  String _formatFrequency(IncomeFrequency frequency) {
    switch (frequency) {
      case IncomeFrequency.daily:
        return 'Daily';
      case IncomeFrequency.weekly:
        return 'Weekly';
      case IncomeFrequency.biWeekly:
        return 'Bi-weekly';
      case IncomeFrequency.monthly:
        return 'Monthly';
      case IncomeFrequency.quarterly:
        return 'Quarterly';
      case IncomeFrequency.yearly:
        return 'Yearly';
      case IncomeFrequency.oneTime:
        return 'One-time';
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final sourceName = _sourceController.text.trim();

      final isOffline = (await Connectivity().checkConnectivity()) == ConnectivityResult.none;

      if (isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saving income offline. It will sync when back online.')),
        );
      }

      final amount = double.parse(_amountController.text.trim());

      final income = Income(
        id: widget.income?.id ?? const Uuid().v4(),
        userId: userId,
        title: _titleController.text.trim(),
        amount: amount,
        date: _selectedDate,
        source: sourceName,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        isRecurring: _isRecurring,
        frequency: _selectedFrequency,
        endDate: _isRecurring ? _endDate : null,
      );

      if (widget.income == null) {
        await _incomeService.addIncome(income);
      } else {
        await _incomeService.updateIncome(income);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isOffline ? 'Saved offline' : 'Income saved!')),
        );
      }

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save income: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteIncome() async {
    if (widget.income == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text('Are you sure you want to delete this income?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _incomeService.deleteIncome(widget.income!.id);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete income')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_upward, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.income == null ? 'Add Income' : 'Edit Income',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.income != null)
            IconButton(
              icon: Icon(Icons.delete, color: theme.colorScheme.error),
              onPressed: _isLoading ? null : _deleteIncome,
            ),
          IconButton(
            icon: Icon(Icons.save, color: theme.colorScheme.primary),
            onPressed: _isLoading ? null : _saveIncome,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.green,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Please enter title' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: const Icon(Icons.attach_money),
                            prefixText: '₹',
                            prefixStyle: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            hintText: 'Enter amount',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: _selectedSource,
                    decoration: InputDecoration(
                      labelText: 'Source',
                      labelStyle: const TextStyle(
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.green,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Icons.source),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select a common source')),
                      ..._defaultSources.map((source) => DropdownMenuItem(
                            value: source,
                            child: Text(source),
                          )),
                      const DropdownMenuItem(
                        value: 'custom',
                        child: Row(
                          children: [Icon(Icons.add, size: 16), SizedBox(width: 8), Text('Custom')],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val == 'custom') {
                          _selectedSource = null;
                          _sourceController.clear();
                        } else {
                          _selectedSource = val;
                          _sourceController.text = val ?? '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sourceController,
                    decoration: InputDecoration(
                      labelText: 'Custom Source',
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Please enter a source' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectDate,
                  ),
                  SwitchListTile(
                    title: const Text('Recurring'),
                    value: _isRecurring,
                    onChanged: (val) => setState(() {
                      _isRecurring = val;
                      if (!val && mounted) {
                        setState(() => _endDate = null);
                      }
                    }),
                  ),
                  if (_isRecurring) ...[
                    DropdownButtonFormField<IncomeFrequency>(
                      value: _selectedFrequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        prefixIcon: const Icon(Icons.repeat),
                      ),
                      items: IncomeFrequency.values
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(_formatFrequency(f)),
                              ))
                          .toList(),
                      onChanged: (f) => setState(() => _selectedFrequency = f!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(_endDate == null
                          ? 'No end date'
                          : DateFormat('MMM dd, yyyy').format(_endDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _selectEndDate,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveIncome,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Income',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orange,
                child: const Text(
                  'You are offline. Changes will sync when online.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
