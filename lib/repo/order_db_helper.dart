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
    final snapshot = await _orderStore.find(_db);
    return snapshot.map((record) => Order.fromMap(record.value)).toList();
  }

  // Update an order
  Future<void> updateOrder(Order order) async {
    var record = await _orderStore.findFirst(_db,
        finder: Finder(filter: Filter.byKey(order.orderId)));
    if (record != null) {
      await _orderStore.record(order.orderId as int).put(_db, order.toMap());
    }
  }

  // Close the database
  Future<void> close() async {
    await _db.close();
  }
}
