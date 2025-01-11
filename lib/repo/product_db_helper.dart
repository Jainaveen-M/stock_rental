import 'dart:developer';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:stock_rental/model/product.dart';

class ProductDatabase {
  static final ProductDatabase _singleton = ProductDatabase._internal();
  static Database? _database;

  final _store = intMapStoreFactory.store('products');

  ProductDatabase._internal();

  factory ProductDatabase() {
    return _singleton;
  }

  Future<Database> get database async {
    if (_database == null) {
      final dir = await getApplicationDocumentsDirectory();
      log("Path stores the product - ${dir.path}");
      final dbPath = '${dir.path}/products.db';
      _database = await databaseFactoryIo.openDatabase(dbPath);
    }
    return _database!;
  }

  Future<void> addProduct(Map<String, dynamic> product) async {
    final db = await database;
    await _store.add(db, product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    final records = await _store.find(db);
    return records
        .map((snapshot) => snapshot.value as Map<String, dynamic>)
        .toList();
  }

  Future<void> updateProduct(int key, Map<String, dynamic> product) async {
    final db = await database;
    await _store.record(key).update(db, product);
  }

  Future<void> updateProductRental(int productId, int rentedQuantity) async {
    final product = await getProduct(productId);
    if (product != null) {
      final updatedProduct = product.copyWith(
        rented: (product.rented ?? 0) + rentedQuantity,
      );
      await updateProduct(updatedProduct.dbKey!, updatedProduct.toMap());
    }
  }

  Future<Product?> getProduct(int productId) async {
    final records = await _store.find(
      await database,
      finder: Finder(
        filter: Filter.equals('id', productId),
      ),
    );
    if (records.isEmpty) return null;
    return Product.fromMap(records.first.value)
        .copyWithDbKey(records.first.key);
  }
}
