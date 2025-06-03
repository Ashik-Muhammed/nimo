import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/income.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/services/category_service.dart';

class IncomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'incomes';
  
  final CategoryService _categoryService = CategoryService();

  // Get all available income category names
  Stream<List<String>> getCategoryNames() {
    return _categoryService.getCategories('income').map(
          (categories) => categories.map((c) => c.name).toList(),
        );
  }
  
  // Get all available income categories with full details
  Stream<List<Category>> getCategories() {
    return _categoryService.getCategories('income');
  }

  // Add a new income
  Future<void> addIncome(Income income) async {
    try {
      // Ensure the category exists
      try {
        final categories = await _categoryService
            .getCategories('income')
            .first;
            
        final categoryExists = categories.any((c) => c.name == income.source);
        
        if (!categoryExists && income.source.isNotEmpty) {
          // Add the category if it doesn't exist
          await _categoryService.addCategory(
            Category(
              id: '${income.source.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}_income',
              name: income.source,
              type: 'income',
              userId: income.userId,
            ),
          );
        }
      } catch (e) {
        log('Error managing category: $e');
        // Continue with the income creation even if category management fails
      }

      // Handle recurring incomes
      if (income.isRecurring && income.frequency != IncomeFrequency.oneTime) {
        await _createRecurringIncomes(income);
      } else {
        await _firestore
            .collection(_collection)
            .doc(income.id)
            .set(income.toMap());
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create recurring incomes
  Future<void> _createRecurringIncomes(Income income) async {
    if (income.endDate == null) return;

    DateTime currentDate = income.date;
    final endDate = income.endDate!;
    final batch = _firestore.batch();
    int count = 0;
    const maxBatchSize = 500; // Firestore batch limit

    while (currentDate.isBefore(endDate) && count < maxBatchSize) {
      final newIncome = income.copyWith(
        id: '${income.id}_${currentDate.millisecondsSinceEpoch}',
        date: currentDate,
      );
      
      final docRef = _firestore.collection(_collection).doc(newIncome.id);
      batch.set(docRef, newIncome.toMap());

      // Calculate next occurrence
      switch (income.frequency) {
        case IncomeFrequency.daily:
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case IncomeFrequency.weekly:
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case IncomeFrequency.biWeekly:
          currentDate = currentDate.add(const Duration(days: 14));
          break;
        case IncomeFrequency.monthly:
          currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
          break;
        case IncomeFrequency.quarterly:
          currentDate = DateTime(currentDate.year, currentDate.month + 3, currentDate.day);
          break;
        case IncomeFrequency.yearly:
          currentDate = DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
          break;
        case IncomeFrequency.oneTime:
          // Shouldn't happen for recurring incomes
          break;
      }
      
      count++;
    }

    await batch.commit();
  }

  // Update an existing income
  Future<void> updateIncome(Income income) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(income.id)
          .update(income.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete an income
  Future<void> deleteIncome(String incomeId) async {
    try {
      await _firestore.collection(_collection).doc(incomeId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get a stream of incomes for a specific user
  Stream<List<Income>> getIncomesStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Income.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get incomes for a specific month and year
  Stream<List<Income>> getIncomesByMonth(String userId, int year, int month) {
    final start = DateTime(year, month, 1);
    final end = month < 12
        ? DateTime(year, month + 1, 1)
        : DateTime(year + 1, 1, 1);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Income.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Default income sources
  final List<String> _defaultSources = [
    'Salary',
    'Freelancing',
    'Investments',
    'Business',
    'Rental',
    'Gift',
    'Other',
  ];

  // Get all income sources (for backward compatibility)
  Future<List<String>> getIncomeSources() async {
    try {
      final categories = await _categoryService.getCategories('income').first;
      return categories.map((c) => c.name).toList();
    } catch (e) {
      return _defaultSources;
    }
  }

  // Get incomes within a date range
  Stream<List<Income>> getIncomesByDateRange(
    String userId,
    int startTimestamp,
    int endTimestamp,
  ) {
    final startDate = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
    final endDate = DateTime.fromMillisecondsSinceEpoch(endTimestamp);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Income.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add a new source
  Future<void> addSource(String source) async {
    if (!_defaultSources.contains(source)) {
      _defaultSources.add(source);
    }
  }

  // Add a new income category
  Future<void> addCategory(Category category) async {
    await _categoryService.addCategory(category);
  }

  // Get total income by source for a specific period
  Future<Map<String, double>> getIncomeBySource(
      String userId, DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    final Map<String, double> sourceTotals = {};
    
    for (var doc in snapshot.docs) {
      final income = Income.fromMap(doc.data(), doc.id);
      sourceTotals.update(
        income.source.toString().split('.').last,
        (value) => value + income.amount,
        ifAbsent: () => income.amount,
      );
    }
    
    return sourceTotals;
  }
}
