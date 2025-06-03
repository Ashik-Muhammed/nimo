import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/debt.dart';

class DebtService {
  final CollectionReference<Map<String, dynamic>> _debts = 
      FirebaseFirestore.instance.collection('debts').withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) => snapshot.data()!,
        toFirestore: (value, _) => value,
      );
  
  // Add a new debt
  Future<void> addDebt(Debt debt) async {
    try {
      // Log the debt data being saved
      final debtData = debt.toMap();
      log('Adding debt with data: $debtData');
      
      // Validate required fields
      if (debt.userId.isEmpty) {
        throw Exception('User ID is required');
      }
      if (debt.title.isEmpty) {
        throw Exception('Title is required');
      }
      if (debt.amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }
      
      // Add to Firestore
      final docRef = await _debts.add(debtData);
      log('Successfully added debt with ID: ${docRef.id}');
    } catch (e, stackTrace) {
      log('Error adding debt: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Update an existing debt
  Future<void> updateDebt(Debt debt) async {
    try {
      await _debts.doc(debt.id).update(debt.toMap());
    } catch (e) {
      log('Error updating debt: $e');
      rethrow;
    }
  }

  // Delete a debt
  Future<void> deleteDebt(String debtId) async {
    try {
      await _debts.doc(debtId).delete();
    } catch (e) {
      log('Error deleting debt: $e');
      rethrow;
    }
  }

  // Get all debts for a user
  Stream<List<Debt>> getUserDebts(String userId) {
    return _debts
        .where('userId', isEqualTo: userId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Debt.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .toList());
  }

  // Get active (unpaid) debts for a user
  Stream<List<Debt>> getActiveDebts(String userId) {
    return _debts
        .where('userId', isEqualTo: userId)
        .where('isPaid', isEqualTo: false)
        .orderBy('dueDate', descending: false) // Show soonest due first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Debt.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .toList());
  }

  // Get overdue debts for a user
  Stream<List<Debt>> getOverdueDebts(String userId) {
    final now = DateTime.now();
    return _debts
        .where('userId', isEqualTo: userId)
        .where('isPaid', isEqualTo: false)
        .where('dueDate', isLessThan: DateTime(now.year, now.month, now.day).millisecondsSinceEpoch)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Debt.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .toList());
  }

  // Record a payment for a debt
  Future<void> recordPayment({
    required String debtId,
    required double amount,
    DateTime? paymentDate,
  }) async {
    try {
      final doc = await _debts.doc(debtId).get();
      if (!doc.exists) {
        throw Exception('Debt not found');
      }

      final data = doc.data();
      if (data == null) {
        throw Exception('Failed to load debt data');
      }

      final debt = Debt.fromMap(data, doc.id);
      final newPaidAmount = debt.paidAmount + amount;
      final isPaid = newPaidAmount >= debt.amount;

      await _debts.doc(debtId).update({
        'paidAmount': newPaidAmount,
        'isPaid': isPaid,
        'paidDate': isPaid ? (paymentDate ?? DateTime.now()) : null,
      });
    } catch (e) {
      log('Error recording payment: $e');
      rethrow;
    }
  }

  // Get total debt amount for a user
  Future<double> getTotalDebt(String userId) async {
    try {
      final snapshot = await _debts
          .where('userId', isEqualTo: userId)
          .where('isPaid', isEqualTo: false)
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final debt = Debt.fromMap(data, doc.id);
        total += debt.amount - debt.paidAmount;
      }
      return total;
    } catch (e) {
      log('Error getting total debt: $e');
      rethrow;
    }
  }

  // Get a single debt by ID
  Future<Debt?> getDebt(String debtId) async {
    try {
      final doc = await _debts.doc(debtId).get();
      if (!doc.exists) return null;
      return Debt.fromMap(doc.data()!..['id'] = doc.id, doc.id);
    } catch (e) {
      log('Error getting debt: $e');
      rethrow;
    }
  }

  // Debug method to list all documents in the debts collection
  Future<void> debugListDebts() async {
    try {
      final snapshot = await _debts.limit(10).get();
      
      if (snapshot.docs.isEmpty) {
        return;
      }
      
      for (var doc in snapshot.docs) {
        print('- ID: ${doc.id}');
        print('  Data: ${doc.data()}');
      }
    } catch (e) {
      print('Error listing debt documents: $e');
    }
  }
}
