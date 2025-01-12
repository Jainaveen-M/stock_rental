import 'dart:developer';

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
    log("dbPath - ${dbPath}");
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  // Add a customer to the database
  Future<void> addCustomer(Customer customer) async {
    await _customerStore.add(_db, customer.toMap());
  }

  // Get all customers from the database
  Future<List<Customer>> getAllCustomers() async {
    final records = await _customerStore.find(_db);
    return records.map((record) => Customer.fromMap(record.value)).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    final snapshots = await _customerStore.find(
      _db,
      finder: Finder(
        filter: Filter.equals('id', id),
      ),
    );

    if (snapshots.isEmpty) return null;
    return Customer.fromMap(snapshots.first.value);
  }

  Future<void> deleteCustomer(String id) async {
    await _customerStore.delete(
      _db,
      finder: Finder(
        filter: Filter.equals('id', id),
      ),
    );
  }
}
