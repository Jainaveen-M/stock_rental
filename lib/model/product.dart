class Product {
  int? dbKey; // Key used in the database for updates.
  String id;
  String name;
  String category;
  double price;

  Product({
    this.dbKey,
    required this.id,
    required this.name,
    required this.category,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
    };
  }

  static Product fromMap(int dbKey, Map<String, dynamic> map) {
    return Product(
      dbKey: dbKey,
      id: map['id'],
      name: map['name'],
      category: map['category'],
      price: map['price'],
    );
  }
}
