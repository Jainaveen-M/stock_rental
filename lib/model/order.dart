import 'package:stock_rental/model/product_filed.dart';
import 'package:flutter/material.dart';

enum OrderStatus { active, closed, expired, pending }

class Order {
  final int orderId;
  final String customerName;
  final int customerId;
  final DateTime orderDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ProductField> products;
  OrderStatus status;
  final double? totalAmount;

  Order({
    required this.orderId,
    required this.customerName,
    required this.customerId,
    required this.orderDate,
    this.startDate,
    this.endDate,
    required this.products,
    this.status = OrderStatus.pending,
    this.totalAmount,
  });

  bool get isActive => status == OrderStatus.active;
  bool get isClosed => status == OrderStatus.closed;

  String get statusDisplay {
    switch (status) {
      case OrderStatus.active:
        return 'Active';
      case OrderStatus.closed:
        return 'Closed';
      case OrderStatus.expired:
        return 'Expired';
      case OrderStatus.pending:
        return 'Pending';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case OrderStatus.active:
        return Colors.green;
      case OrderStatus.closed:
        return Colors.grey;
      case OrderStatus.expired:
        return Colors.red;
      case OrderStatus.pending:
        return Colors.orange;
    }
  }

  void updateStatus() {
    if (status == OrderStatus.closed) return;

    products.updateAllStatuses();

    if (products.every((product) => product.status == RentalStatus.closed)) {
      status = OrderStatus.closed;
    } else if (products.hasExpiredProducts) {
      status = OrderStatus.expired;
    } else if (products.any((product) => product.isActive)) {
      status = OrderStatus.active;
    } else {
      status = OrderStatus.pending;
    }
  }

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'customerName': customerName,
        'customerId': customerId,
        'orderDate': orderDate.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'products': products.map((product) => product.toMap()).toList(),
        'status': status.toString(),
        'totalAmount': totalAmount ?? products.totalAmount,
      };

  factory Order.fromMap(Map<String, dynamic> map) {
    var productsData = List<Map<String, dynamic>>.from(map['products']);
    var products = productsData.map((p) => ProductField.fromMap(p)).toList();

    return Order(
      orderId: map['orderId'] as int,
      customerName: map['customerName'],
      customerId: map['customerId'] as int,
      orderDate: DateTime.parse(map['orderDate']),
      startDate:
          map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      products: products,
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      totalAmount: map['totalAmount']?.toDouble(),
    );
  }

  double get orderTotal => products.fold(
        0,
        (sum, product) => sum + (product.quantity * (product.price ?? 0)),
      );

  bool get needsAttention {
    return products.any((product) => product.needsAttention);
  }

  int get activeProductsCount => products.activeProductsCount;

  List<ProductField> get expiredProducts => products.expiredProducts;
}
