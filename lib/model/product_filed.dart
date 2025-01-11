import 'dart:convert';
import 'package:flutter/material.dart';

enum RentalStatus { active, closed, expired, pending }

class ProductField {
  int productId;
  String productName;
  int quantity;
  RentalStatus status;
  double? price;

  ProductField({
    required this.productId,
    this.productName = '',
    this.quantity = 1,
    this.status = RentalStatus.active,
    this.price,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'status': status.toString(),
        'price': price,
      };

  factory ProductField.fromMap(Map<String, dynamic> map) => ProductField(
        productId: map['productId'] as int,
        productName: map['productName'] ?? '',
        quantity: map['quantity'] ?? 1,
        status: RentalStatus.values.firstWhere(
          (e) => e.toString() == map['status'],
          orElse: () => RentalStatus.active,
        ),
        price: map['price']?.toDouble(),
      );

  bool get isActive => status == RentalStatus.active;
  bool get isExpired => false;
  bool get needsAttention => false;
  double get totalPrice => quantity * (price ?? 0);

  void updateStatus() {
    if (status == RentalStatus.closed) return;

    if (isExpired) {
      status = RentalStatus.expired;
    } else {
      status = RentalStatus.active;
    }
  }
}

// Extension for list of ProductFields
extension ProductFieldListExtension on List<ProductField> {
  double get totalAmount {
    return fold(0, (sum, product) => sum + product.totalPrice);
  }

  bool get hasExpiredProducts {
    return any((product) => product.isExpired);
  }

  int get activeProductsCount {
    return where((product) => product.isActive).length;
  }

  List<ProductField> get expiredProducts {
    return where((product) => product.isExpired).toList();
  }

  void updateAllStatuses() {
    forEach((product) => product.updateStatus());
  }
}
