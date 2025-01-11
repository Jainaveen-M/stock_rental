import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:stock_rental/model/order.dart';

class OrderDatabase {
  static final OrderDatabase _singleton = OrderDatabase._internal();

  // Factory constructor
  factory OrderDatabase() {
    return _singleton;
  }

  OrderDatabase._internal();

  // Database instance
  late Database _db;

  // Store for customers
  final _orderStore = intMapStoreFactory.store('order');

  // Initialize the database
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/order.db';
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  // Save order to the database
  Future<void> saveOrder(Order order) async {
    await _orderStore.add(_db, order.toMap());
  }

  // Fetch all orders
  Future<List<Order>> getAllOrders() async {
    final db = await _db;
    final records = await _orderStore.find(db);
    return records.map((record) {
      final orderMap = Map<String, dynamic>.from(record.value);
      return Order.fromMap(orderMap);
    }).toList();
  }

  // Update an order
  Future<void> updateOrder(Order order) async {
    final db = await _db;
    await _orderStore.update(
      db,
      order.toMap(),
      finder: Finder(
        filter: Filter.equals('orderId', order.orderId),
      ),
    );
  }

  // Close the database
  Future<void> close() async {
    await _db.close();
  }
}
