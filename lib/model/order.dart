import 'package:stock_rental/model/product_filed.dart';
import 'package:flutter/material.dart';

enum OrderStatus { active, closed, expired, pending }

class Order {
  String orderId;
  String customerName;
  String customerId;
  DateTime orderDate;
  List<ProductField> products;
  OrderStatus status;
  double? totalAmount;

  Order({
    required this.orderId,
    required this.customerName,
    required this.customerId,
    required this.orderDate,
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

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerName': customerName,
      'customerId': customerId,
      'orderDate': orderDate.toIso8601String(),
      'products': products.map((product) => product.toMap()).toList(),
      'status': status.toString(),
      'totalAmount': totalAmount ?? products.totalAmount,
    };
  }

  static Order fromMap(Map<String, dynamic> map) {
    var productsData = List<Map<String, dynamic>>.from(map['products']);
    var products = productsData.map((p) => ProductField.fromMap(p)).toList();

    return Order(
      orderId: map['orderId'],
      customerName: map['customerName'],
      customerId: map['customerId'],
      orderDate: DateTime.parse(map['orderDate']),
      products: products,
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      totalAmount: map['totalAmount']?.toDouble(),
    );
  }

  double get orderTotal => totalAmount ?? products.totalAmount;

  bool get needsAttention {
    return products.any((product) => product.needsAttention);
  }

  int get activeProductsCount => products.activeProductsCount;

  List<ProductField> get expiredProducts => products.expiredProducts;
}
