class Product {
  final int? dbKey;
  final int id;
  final String name;
  final String category;
  final String description;
  final int stock;
  final int? rented;

  Product({
    this.dbKey,
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    this.stock = 0,
    this.rented = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'stock': stock,
        'rented': rented,
      };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as int,
        name: map['name'] ?? '',
        category: map['category'] ?? '',
        description: map['description'] ?? '',
        stock: map['stock'] ?? 0,
        rented: map['rented'] ?? 0,
      );

  factory Product.fromMap2(Map<String, dynamic> map) => Product(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        category: map['category'] ?? '',
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
    int? rented,
  }) =>
      Product(
        dbKey: dbKey ?? this.dbKey,
        id: this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        description: description ?? this.description,
        stock: stock ?? this.stock,
        rented: rented ?? this.rented,
      );

  Product copyWithDbKey(int? dbKey) {
    return Product(
      dbKey: dbKey,
      id: this.id,
      name: this.name,
      category: this.category,
      description: this.description,
      stock: this.stock,
      rented: this.rented,
    );
  }
}
