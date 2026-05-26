import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/credit_card.dart';

class CreditCardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'creditCards';

  // Add a new credit card
  Future<void> addCreditCard(CreditCard creditCard) async {
    await _firestore.collection(_collection).doc(creditCard.id).set(creditCard.toMap());
  }

  // Update an existing credit card
  Future<void> updateCreditCard(CreditCard creditCard) async {
    await _firestore.collection(_collection).doc(creditCard.id).update(creditCard.toMap());
  }

  // Delete a credit card
  Future<void> deleteCreditCard(String creditCardId) async {
    await _firestore.collection(_collection).doc(creditCardId).delete();
  }

  // Get all credit cards for a user
  Stream<List<CreditCard>> getCreditCards(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreditCard.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get a single credit card by ID
  Future<CreditCard?> getCreditCardById(String creditCardId) async {
    final doc = await _firestore.collection(_collection).doc(creditCardId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return CreditCard.fromMap(data, doc.id);
  }

  // Get credit cards with high utilization (>30%)
  Stream<List<CreditCard>> getHighUtilizationCards(String userId) {
    return getCreditCards(userId).map((cards) => cards.where((card) => card.isHighUtilization).toList());
  }

  // Get credit cards with critical utilization (>70%)
  Stream<List<CreditCard>> getCriticalUtilizationCards(String userId) {
    return getCreditCards(userId).map((cards) => cards.where((card) => card.isCriticalUtilization).toList());
  }

  // Get overdue credit cards
  Stream<List<CreditCard>> getOverdueCards(String userId) {
    return getCreditCards(userId).map((cards) => cards.where((card) => card.isOverdue).toList());
  }

  // Calculate total credit limit for a user
  Stream<double> getTotalCreditLimit(String userId) {
    return getCreditCards(userId).map((cards) => cards.fold(0.0, (total, card) => total + card.creditLimit));
  }

  // Calculate total current balance for a user
  Stream<double> getTotalCurrentBalance(String userId) {
    return getCreditCards(userId).map((cards) => cards.fold(0.0, (total, card) => total + card.currentBalance));
  }

  // Calculate average utilization rate for a user
  Stream<double> getAverageUtilizationRate(String userId) {
    return getCreditCards(userId).map((cards) {
      if (cards.isEmpty) return 0.0;
      final totalLimit = cards.fold(0.0, (total, card) => total + card.creditLimit);
      final totalBalance = cards.fold(0.0, (total, card) => total + card.currentBalance);
      if (totalLimit == 0) return 0.0;
      return (totalBalance / totalLimit) * 100;
    });
  }

  // Record a payment on a credit card
  Future<void> recordPayment(String creditCardId, double amount) async {
    final card = await getCreditCardById(creditCardId);
    if (card == null) return;

    final updatedCard = card.copyWith(
      currentBalance: card.currentBalance - amount,
    );

    await updateCreditCard(updatedCard);
  }

  // Add a transaction to a credit card statement
  Future<void> addTransaction(String creditCardId, CreditCardTransaction transaction) async {
    final card = await getCreditCardById(creditCardId);
    if (card == null) return;

    // Get the current statement or create a new one
    Statement currentStatement;
    if (card.statements.isNotEmpty) {
      currentStatement = card.statements.last;
      // Add transaction to current statement
      final updatedTransactions = [...currentStatement.transactions, transaction];
      currentStatement = Statement(
        statementDate: currentStatement.statementDate,
        dueDate: currentStatement.dueDate,
        totalAmount: currentStatement.totalAmount + transaction.amount,
        minimumDue: currentStatement.minimumDue,
        transactions: updatedTransactions,
      );
    } else {
      // Create new statement
      currentStatement = Statement(
        statementDate: card.statementDate,
        dueDate: card.dueDate,
        totalAmount: transaction.amount,
        minimumDue: transaction.amount * 0.05, // 5% minimum due
        transactions: [transaction],
      );
    }

    final updatedStatements = [...card.statements];
    if (updatedStatements.isNotEmpty) {
      updatedStatements[updatedStatements.length - 1] = currentStatement;
    } else {
      updatedStatements.add(currentStatement);
    }

    final updatedCard = card.copyWith(
      statements: updatedStatements,
      currentBalance: card.currentBalance + transaction.amount,
    );

    await updateCreditCard(updatedCard);
  }
}
