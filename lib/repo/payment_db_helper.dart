import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:stock_rental/model/payment.dart';

class PaymentDatabase {
  static final PaymentDatabase _singleton = PaymentDatabase._internal();

  factory PaymentDatabase() {
    return _singleton;
  }

  PaymentDatabase._internal();

  late Database _db;
  final _paymentStore = intMapStoreFactory.store('payments');

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = '${dir.path}/payments.db';
    _db = await databaseFactoryIo.openDatabase(dbPath);
  }

  Future<void> savePayment(Payment payment) async {
    await _paymentStore.add(_db, payment.toMap());
  }

  Future<List<Payment>> getPaymentsForOrder(int orderId) async {
    final finder = Finder(
      filter: Filter.equals('orderId', orderId),
      sortOrders: [SortOrder('paymentDate')],
    );

    final records = await _paymentStore.find(_db, finder: finder);
    return records.map((record) => Payment.fromMap(record.value)).toList();
  }

  Future<void> updatePayment(Payment payment) async {
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('orderId', payment.orderId),
        Filter.equals('paymentDate', payment.paymentDate.toIso8601String()),
      ]),
    );
    await _paymentStore.update(_db, payment.toMap(), finder: finder);
  }

  Future<List<Payment>> getAllPayments() async {
    final records = await _paymentStore.find(
      _db,
      finder: Finder(sortOrders: [SortOrder('paymentDate', false)]),
    );
    return records.map((record) => Payment.fromMap(record.value)).toList();
  }
}
