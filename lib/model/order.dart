import 'package:stock_rental/model/product.dart';

class Order {
  String orderId;
  String customerName;
  DateTime orderDate;
  List<Product> products;
  String status;

  Order({
    required this.orderId,
    required this.customerName,
    required this.orderDate,
    required this.products,
    this.status = 'Active',
  });

  // Convert Order to Map for Sembast storage
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerName': customerName,
      'orderDate': orderDate.toIso8601String(),
      'products': products.map((product) => product.toMap()).toList(),
      'status': status,
    };
  }

  // Convert Map to Order
  static Order fromMap(Map<String, dynamic> map) {
    var productsData = List<Map<String, dynamic>>.from(map['products']);
    var products = productsData.map((p) => Product.fromMap2(p)).toList();
    return Order(
      orderId: map['orderId'],
      customerName: map['customerName'],
      orderDate: DateTime.parse(map['orderDate']),
      products: products,
      status: map['status'],
    );
  }
}