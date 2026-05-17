import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/account.dart';

class AccountService {
  final CollectionReference<Map<String, dynamic>> _accounts = 
      FirebaseFirestore.instance.collection('accounts').withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) => snapshot.data()!,
        toFirestore: (value, _) => value,
      );
  
  // Add a new account
  Future<void> addAccount(Account account) async {
    try {
      final accountData = account.toMap();
      log('Adding account with data: $accountData');
      
      if (account.userId.isEmpty) {
        throw Exception('User ID is required');
      }
      if (account.name.isEmpty) {
        throw Exception('Account name is required');
      }
      
      final docRef = await _accounts.add(accountData);
      log('Successfully added account with ID: ${docRef.id}');
    } catch (e, stackTrace) {
      log('Error adding account: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Update an existing account
  Future<void> updateAccount(Account account) async {
    try {
      await _accounts.doc(account.id).update(account.toMap());
    } catch (e) {
      log('Error updating account: $e');
      rethrow;
    }
  }

  // Delete an account
  Future<void> deleteAccount(String accountId) async {
    try {
      await _accounts.doc(accountId).delete();
    } catch (e) {
      log('Error deleting account: $e');
      rethrow;
    }
  }

  // Get all accounts for a user
  Stream<List<Account>> getUserAccounts(String userId) {
    return _accounts
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .toList());
  }

  // Get active accounts for a user
  Stream<List<Account>> getActiveAccounts(String userId) {
    return _accounts
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .toList());
  }

  // Get accounts by type
  Stream<List<Account>> getAccountsByType(String userId, AccountType type) {
    return _accounts
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .toList());
  }

  // Get asset accounts
  Stream<List<Account>> getAssetAccounts(String userId) {
    return _accounts
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .where((account) => account.type.isAsset)
            .toList());
  }

  // Get liability accounts
  Stream<List<Account>> getLiabilityAccounts(String userId) {
    return _accounts
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .where((account) => account.type.isLiability)
            .toList());
  }

  // Get banking accounts
  Stream<List<Account>> getBankingAccounts(String userId) {
    return _accounts
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .where((account) => account.type.isBanking)
            .toList());
  }

  // Get total assets for a user
  Future<double> getTotalAssets(String userId) async {
    try {
      final snapshot = await _accounts
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final account = Account.fromMap(doc.data()..['id'] = doc.id, doc.id);
        if (account.type.isAsset) {
          total += account.balance;
        }
      }
      return total;
    } catch (e) {
      log('Error getting total assets: $e');
      rethrow;
    }
  }

  // Get total liabilities for a user
  Future<double> getTotalLiabilities(String userId) async {
    try {
      final snapshot = await _accounts
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final account = Account.fromMap(doc.data()..['id'] = doc.id, doc.id);
        if (account.type.isLiability) {
          total += account.balance.abs();
        }
      }
      return total;
    } catch (e) {
      log('Error getting total liabilities: $e');
      rethrow;
    }
  }

  // Get net worth (assets - liabilities)
  Future<double> getNetWorth(String userId) async {
    try {
      final assets = await getTotalAssets(userId);
      final liabilities = await getTotalLiabilities(userId);
      return assets - liabilities;
    } catch (e) {
      log('Error calculating net worth: $e');
      rethrow;
    }
  }

  // Get a single account by ID
  Future<Account?> getAccount(String accountId) async {
    try {
      final doc = await _accounts.doc(accountId).get();
      if (!doc.exists) return null;
      return Account.fromMap(doc.data()!..['id'] = doc.id, doc.id);
    } catch (e) {
      log('Error getting account: $e');
      rethrow;
    }
  }

  // Update account balance
  Future<void> updateBalance(String accountId, double newBalance) async {
    try {
      await _accounts.doc(accountId).update({
        'balance': newBalance,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      log('Error updating balance: $e');
      rethrow;
    }
  }

  // Get overdue liability accounts
  Stream<List<Account>> getOverdueLiabilities(String userId) {
    final now = DateTime.now();
    return _accounts
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Account.fromMap(doc.data()..['id'] = doc.id, doc.id))
            .where((account) => 
              account.type.isLiability && 
              account.dueDate != null && 
              now.isAfter(account.dueDate!)
            )
            .toList());
  }
}
