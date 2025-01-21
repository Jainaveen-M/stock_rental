import 'package:stock_rental/model/customer.dart';
import 'package:stock_rental/model/product_filed.dart';

enum RentalAgreementStatus { active, closed, expired, pending }

class RentalAgreement {
  final int id;
  final int orderId;
  final Customer customer;
  final List<ProductField> products;
  RentalAgreementStatus status;
  final DateTime agreementDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalAmount;
  final double advanceAmount;

  RentalAgreement({
    required this.id,
    required this.orderId,
    required this.customer,
    required this.products,
    required this.agreementDate,
    this.startDate,
    this.endDate,
    this.status = RentalAgreementStatus.pending,
    this.totalAmount = 0.0,
    this.advanceAmount = 0.0,
  });

  bool get isActive => status == RentalAgreementStatus.active;
  bool get isClosed => status == RentalAgreementStatus.closed;

  String get statusDisplay {
    switch (status) {
      case RentalAgreementStatus.active:
        return 'Active';
      case RentalAgreementStatus.closed:
        return 'Closed';
      case RentalAgreementStatus.expired:
        return 'Expired';
      case RentalAgreementStatus.pending:
        return 'Pending';
    }
  }

  void updateStatus() {
    if (status == RentalAgreementStatus.closed) return;

    products.updateAllStatuses();

    if (products.every((product) => product.status == RentalStatus.closed)) {
      status = RentalAgreementStatus.closed;
    } else if (products.hasExpiredProducts) {
      status = RentalAgreementStatus.expired;
    } else if (products.any((product) => product.isActive)) {
      status = RentalAgreementStatus.active;
    } else {
      status = RentalAgreementStatus.pending;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'customer': customer.toMap(),
        'products': products.map((product) => product.toMap()).toList(),
        'agreementDate': agreementDate.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'status': status.toString(),
        'totalAmount': totalAmount,
        'advanceAmount': advanceAmount,
      };

  factory RentalAgreement.fromMap(Map<String, dynamic> map) {
    var productsData = List<Map<String, dynamic>>.from(map['products']);
    var products = productsData.map((p) => ProductField.fromMap(p)).toList();

    return RentalAgreement(
      id: map['id'] as int,
      orderId: map['orderId'],
      customer: Customer.fromMap(map['customer']),
      products: products,
      agreementDate: DateTime.parse(map['agreementDate']),
      startDate:
          map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      status: RentalAgreementStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => RentalAgreementStatus.pending,
      ),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      advanceAmount: (map['advanceAmount'] ?? 0.0).toDouble(),
    );
  }

  double get agreementTotal => products.fold(
        0,
        (sum, product) => sum + (product.quantity * (product.price ?? 0)),
      );

  bool get needsAttention {
    return products.any((product) => product.needsAttention);
  }

  int get activeProductsCount => products.activeProductsCount;

  List<ProductField> get expiredProducts => products.expiredProducts;
}
