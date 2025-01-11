class Product {
  final int? dbKey;
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final int stock;

  Product({
    this.dbKey,
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.stock = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'stock': stock,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? '',
        price: (map['price'] ?? 0.0).toDouble(),
        description: map['description'] ?? '',
        stock: map['stock'] ?? 0,
      );

  factory Product.fromMap2(Map<String, dynamic> map) => Product(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? '',
        price: (map['price'] ?? 0.0).toDouble(),
        description: map['description'] ?? '',
        stock: map['stock'] ?? 0,
      );

  Product copyWith({
    int? dbKey,
    String? name,
    String? category,
    double? price,
    String? description,
    int? stock,
  }) =>
      Product(
        dbKey: dbKey ?? this.dbKey,
        id: this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        price: price ?? this.price,
        description: description ?? this.description,
        stock: stock ?? this.stock,
      );
}
