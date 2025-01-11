import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:stock_rental/model/customer.dart';

class CustomerDatabase {
  // Singleton instance
  static final CustomerDatabase _singleton = CustomerDatabase._internal();

  // Factory constructor
  factory CustomerDatabase() {
    return _singleton;
  }

  CustomerDatabase._internal();

  // Database instance
  late Database _db;

  // Store for customers
  final _customerStore = intMapStoreFactory.store('customers');

  // Initialize the database
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/customer_database.db';
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  // Add a customer to the database
  Future<void> addCustomer(Customer customer) async {
    await _customerStore.add(_db, customer.toMap());
  }

  // Get all customers from the database
  Future<List<Customer>> getAllCustomers() async {
    final records = await _customerStore.find(_db);
    return records.map((snapshot) {
      return Customer.fromMap(snapshot.value);
    }).toList();
  }
}
