import 'dart:async';
import 'dart:developer' as developer;

import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/services/category_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/category.dart' as expense_category;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/models/expense_frequency.dart';

class ExpenseService {
  final FirebaseFirestore _firestore;
  final String _collection = 'expenses';
  final CategoryService _categoryService;
  final FirebaseAuth _auth;

  // Log error messages
  void _logError(String message) {
    developer.log(message, name: 'ExpenseService');
  }
  
  ExpenseService({
    FirebaseFirestore? firestore,
    CategoryService? categoryService,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _categoryService = categoryService ?? CategoryService(),
        _auth = auth ?? FirebaseAuth.instance;
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
  


  // Get all available expense categories with full details
  Stream<List<expense_category.Category>> getCategories() {
    return _categoryService.getCategories('expense');
  }

  // Get all available expense category names
  Stream<List<String>> getCategoryNames() {
    return _categoryService.getCategories('expense').map(
      (categories) => categories.map((c) => c.name).toList(),
    );
  }
  
  // Delete an expense
  Future<void> deleteExpense(String expenseId, String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection(_collection).doc(expenseId).delete();
    } catch (e) {
      _logError('Error deleting expense: $e');
      rethrow;
    }
  }

  // Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    try {
      // Check if category exists, create if needed
      try {
        final categories = await _categoryService
            .getCategories('expense')
            .first;

        final categoryExists = categories.any((c) => c.name == expense.category);
        if (!categoryExists && expense.category.isNotEmpty) {
          await _categoryService.addCategory(
            expense_category.Category(
              id: '${expense.category.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
              name: expense.category,
              type: 'expense',
              userId: expense.userId,
              icon: 'receipt', // Default icon
            ),
          );
        }
      } catch (e) {
        _logError('Error managing category: $e');
      }

      // Update in Firestore
      await _firestore
          .collection(_collection)
          .doc(expense.id)
          .update(expense.toMap());

      // If it's a recurring expense, update all future occurrences
      if (expense.isRecurring && expense.endDate != null) {
        final snapshots = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: expense.userId)
            .where('originalId', isEqualTo: expense.id)
            .get();

        for (final doc in snapshots.docs) {
          final expenseDoc = doc.data();
          final updatedExpense = expense.copyWith(
            id: expenseDoc['id'],
            date: (expenseDoc['date'] as Timestamp).toDateTime(),
          );

          await _firestore
              .collection(_collection)
              .doc(updatedExpense.id)
              .update(updatedExpense.toMap());
        }
      }

    } catch (e) {
      _logError('Error updating expense: $e');
      rethrow;
    }
  }

  // Add a new expense
  Future<void> addExpense(Expense expense) async {
    try {
      // Generate a unique ID if not provided
      final expenseToSave = expense.id.isEmpty 
          ? expense.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString())
          : expense;

      // Check if category exists, create if needed
      try {
        final categories = await _categoryService
            .getCategories('expense')
            .first;

        final categoryExists = categories.any((c) => c.name == expenseToSave.category);
        if (!categoryExists && expenseToSave.category.isNotEmpty) {
          await _categoryService.addCategory(
            expense_category.Category(
              id: '${expenseToSave.category.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
              name: expenseToSave.category,
              type: 'expense',
              userId: expenseToSave.userId,
              icon: 'receipt', // Default icon
            ),
          );
        }
      } catch (e) {
        _logError('Error managing category: $e');
      }

      // Save directly to Firestore
      await _firestore
          .collection(_collection)
          .doc(expenseToSave.id)
          .set(expenseToSave.toMap());

      // If it's a recurring expense, create future occurrences
      if (expenseToSave.isRecurring && expenseToSave.endDate != null) {
        DateTime currentDate = expenseToSave.date;
        final endDate = expenseToSave.endDate!;
        
        while (currentDate.isBefore(endDate)) {
          final newExpense = expenseToSave.copyWith(
            id: '${expenseToSave.id}_${currentDate.millisecondsSinceEpoch}',
            date: currentDate,
          );

          await _firestore
              .collection(_collection)
              .doc(newExpense.id)
              .set(newExpense.toMap());

          // Calculate next occurrence based on frequency
          switch (expenseToSave.frequency) {
            case ExpenseFrequency.daily:
              currentDate = currentDate.add(const Duration(days: 1));
              break;
            case ExpenseFrequency.weekly:
              currentDate = currentDate.add(const Duration(days: 7));
              break;
            case ExpenseFrequency.monthly:
              currentDate = DateTime(
                currentDate.year,
                currentDate.month + 1,
                currentDate.day,
              );
              break;
            case ExpenseFrequency.yearly:
              currentDate = DateTime(
                currentDate.year + 1,
                currentDate.month,
                currentDate.day,
              );
              break;
            default:
              break;
          }
        }
      }

    } catch (e) {
      _logError('Error adding expense: $e');
      rethrow;
    }
  }

  // Get all expenses for a specific user
  Stream<List<Expense>> getExpenses(String userId) async* {
    try {
      await for (final snapshot in _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots()) {
        final expenses = snapshot.docs
            .map((doc) => Expense.fromMap(doc.data()))
            .toList();
        yield expenses;
      }
    } catch (e) {
      _logError('Error fetching expenses: $e');
      rethrow;
    }
  }

  // Get expenses within a date range (async version)
  Future<List<Expense>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      final expenses = snapshot.docs
          .map((doc) => Expense.fromMap({
            'id': doc.id,
            ...doc.data()
          }))
          .toList();

      return expenses;
    } catch (e) {
      _logError('Error fetching expenses: $e');
      rethrow;
    }
  }

  // Get expenses within a date range (stream version)
  Stream<List<Expense>> getExpensesByMonthStream(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap({
                  'id': doc.id,
                  ...doc.data() 
                }))
            .toList());
  }

  // Get expenses for a specific month (async version)
  Future<List<Expense>> getExpensesByMonth(String userId, DateTime month) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return getExpensesByDateRange(userId, firstDay, lastDay);
  }

  /// Gets a stream of total expenses for a specific month and year
  Stream<double> getTotalForMonthStream(int month, int year) async* {
    // Get current user ID, return if not authenticated
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Calculate date range for the specified month
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0, 23, 59, 59);

    try {
      // Subscribe to real-time updates
      await for (final expenses in getExpensesByDateRangeStream(
        userId, 
        firstDay.millisecondsSinceEpoch,
        lastDay.millisecondsSinceEpoch,
      )) {
        // Update total with new expenses and yield the new value
        final total = expenses.fold(0.0, (runningTotal, expense) => runningTotal + expense.amount);
        yield total;
      }
    } catch (e) {
      _logError('Error in getTotalForMonthStream: $e');
      rethrow;
    }
  }

  // Add a new category (async version)
  Future<void> addNewCategory(expense_category.Category category) async {
    try {
      await _categoryService.addCategory(category);
    } catch (e) {
      _logError('Error adding category: $e');
      rethrow;
    }
  }

  // Alias for addNewCategory for backward compatibility
  Future<void> addCategory(expense_category.Category category) async {
    return addNewCategory(category);
  }

  // Get expenses for a specific date range using timestamps (stream version)
  Stream<List<Expense>> getExpensesByDateRangeStream(
    String userId,
    int startTimestamp,
    int endTimestamp,
  ) {
    final startDate = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
    final endDate = DateTime.fromMillisecondsSinceEpoch(endTimestamp);
    
    _logError('getExpensesByDateRangeStream called for user $userId');
    _logError('Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    
    // Create a controller for the stream
    final controller = StreamController<List<Expense>>.broadcast();
    bool isDisposed = false;

    // Listen to Firestore changes
    try {
      _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .snapshots()
          .listen((snapshot) {
            if (isDisposed) return;

            try {
              final expenses = snapshot.docs
                  .map((doc) => Expense.fromMap(doc.data()))
                  .toList();

              controller.add(expenses);
            } catch (e) {
              _logError('Error in Firestore listener: $e');
            }
          });
    } catch (e) {
      _logError('Error setting up Firestore listener: $e');
      controller.addError(e);
    }

    // Add cleanup when the stream is cancelled
    controller.onCancel = () {
      isDisposed = true;
      controller.close();
    };

    return controller.stream;
  }

  // Get expenses shared with a specific user
  Future<List<Expense>> getSharedExpenses(String userId) async {
    try {
      // In the current implementation, we don't have a sharedWith field
      // So we'll return an empty list for now
      // In a real implementation, you would filter by the sharedWith field
      return [];
    } catch (e) {
      developer.log('Error getting shared expenses: $e', name: 'ExpenseService');
      rethrow;
    }
  }

  // Mark a split expense as paid
  Future<void> markSplitExpensePaid(String expenseId, String userId) async {
    try {
      // This is a no-op in the local implementation
      // In a real implementation, this would update the expense in Firestore
      // and handle offline syncing
      developer.log('markSplitExpensePaid is not implemented in local storage', name: 'ExpenseService');
    } catch (e) {
      developer.log('Error marking split expense as paid: $e', name: 'ExpenseService');
      rethrow;
    }
  }
}


