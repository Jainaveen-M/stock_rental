import 'dart:convert';
import 'package:flutter/material.dart';

enum RentalStatus { active, closed, expired, pending }

class ProductField {
  String productId;
  String productName;
  int quantity;
  DateTime? startDate;
  DateTime? endDate;
  RentalStatus status;
  double? price;

  ProductField({
    this.productId = '',
    this.productName = '',
    this.quantity = 1,
    this.startDate,
    this.endDate,
    this.status = RentalStatus.active,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'status': status.toString(),
      };

  factory ProductField.fromMap(Map<String, dynamic> map) => ProductField(
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        quantity: map['quantity'] ?? 1,
        startDate:
            map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
        endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
        status: RentalStatus.values.firstWhere(
          (e) => e.toString() == map['status'],
          orElse: () => RentalStatus.active,
        ),
      );

  bool get isActive => status == RentalStatus.active;
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get needsAttention => isExpired && status != RentalStatus.closed;
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
