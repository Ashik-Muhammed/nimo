class Category {
  final String id;
  final String name;
  final String? icon; // Optional icon code or identifier
  final String type; // 'expense' or 'income'
  final String userId; // To separate categories by user
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.icon,
    required this.type,
    required this.userId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Category to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create Category from Firestore document
  factory Category.fromMap(Map<String, dynamic> map, String docId) {
    return Category(
      id: map['id'] ?? docId, // Use stored ID if available, fallback to document ID
      name: map['name'] ?? '',
      icon: map['icon'],
      type: map['type'] ?? 'expense',
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }

  // Create a copy of the category with some fields changed
  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? type,
    String? userId,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
