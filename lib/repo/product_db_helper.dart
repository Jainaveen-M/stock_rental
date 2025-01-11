import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

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
}
