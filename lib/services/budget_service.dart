import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_budgets';

  // Get the current user's budget
  Future<double?> getMonthlyBudget(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return (doc.data()?['monthlyBudget'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Set the current user's budget
  Future<void> setMonthlyBudget(String userId, double amount) async {
    try {
      await _firestore.collection(_collection).doc(userId).set(
        {
          'monthlyBudget': amount,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Stream the current user's budget
  Stream<double?> streamMonthlyBudget(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) => (doc.data()?['monthlyBudget'] as num?)?.toDouble());
  }
}
