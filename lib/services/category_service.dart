import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'categories';

  // Get all categories for a specific type (expense/income) and user
  Stream<List<Category>> getCategories(String type) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('name')
        .snapshots()
        .map((QuerySnapshot snapshot) => snapshot.docs
            .map((QueryDocumentSnapshot doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Create category with name only
              return Category(
                id: data['id'] ?? doc.id,
                name: data['name'] ?? '',
                type: data['type'] ?? type,
                userId: data['userId'] ?? userId,
                createdAt: data['createdAt'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
                    : DateTime.now(),
              );
            })
            .toList());
  }

  // Add a new category
  Future<void> addCategory(Category category) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if category with same name and type already exists
    final existing = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('name', isEqualTo: category.name)
        .where('type', isEqualTo: category.type)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Category with this name already exists');
    }

    await _firestore.collection(_collection).add(category.toMap());
  }

  // Update an existing category
  Future<void> updateCategory(Category category) async {
    await _firestore
        .collection(_collection)
        .doc(category.id)
        .update(category.toMap());
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection(_collection).doc(categoryId).delete();
  }

  // Get default categories for a new user
  List<Category> getDefaultCategories(String userId) {
    final defaultExpenseCategories = [
      'Food',
      'Transport',
      'Shopping',
      'Bills',
      'Entertainment',
      'Health',
      'Education',
      'Other',
    ];

    final defaultIncomeCategories = [
      'Salary',
      'Bonus',
      'Freelance',
      'Investments',
      'Gifts',
      'Other',
    ];

    final timestamp = DateTime.now();
    final categories = <Category>[];

    for (var category in defaultExpenseCategories) {
      categories.add(
        Category(
          id: '${category.toLowerCase()}_${timestamp.millisecondsSinceEpoch}',
          name: category,
          type: 'expense',
          userId: userId,
          createdAt: timestamp,
        ),
      );
    }

    for (var category in defaultIncomeCategories) {
      categories.add(
        Category(
          id: '${category.toLowerCase()}_${timestamp.millisecondsSinceEpoch}_income',
          name: category,
          type: 'income',
          userId: userId,
          createdAt: timestamp,
        ),
      );
    }

    return categories;
  }

  // Initialize default categories for a new user
  Future<void> initializeDefaultCategories(String userId) async {
    final defaultCategories = getDefaultCategories(userId);
    final batch = _firestore.batch();
    final collection = _firestore.collection(_collection);

    for (var category in defaultCategories) {
      // Use the category's ID as the document ID
      batch.set(collection.doc(category.id), category.toMap());
    }

    await batch.commit();
  }
}
