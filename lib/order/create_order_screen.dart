import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/model/customer.dart';
import 'package:stock_rental/model/product_filed.dart';
import 'package:stock_rental/repo/product_db_helper.dart';

class CreateOrderScreen extends StatefulWidget {
  final List<Customer> customers;
  final List<Product> availableProducts;
  final Function(Order) onCreate;
  final ProductDatabase productDatabase;

  const CreateOrderScreen({
    Key? key,
    required this.customers,
    required this.availableProducts,
    required this.onCreate,
    required this.productDatabase,
  }) : super(key: key);

  @override
  _CreateOrderScreenState createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  late Customer? selectedCustomer;
  List<ProductField> productFields = [];
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    selectedCustomer =
        widget.customers.isNotEmpty ? widget.customers.first : null;
  }

  void _addProduct() {
    setState(() {
      productFields.add(ProductField(
        productId: widget.availableProducts.first.id,
        productName: widget.availableProducts.first.name,
      ));
    });
  }

  void _removeProduct(int index) {
    setState(() {
      productFields.removeAt(index);
    });
  }

  Future<void> _updateProductRentals(List<ProductField> products) async {
    for (var product in products) {
      await widget.productDatabase.updateProductRental(
        product.productId,
        product.quantity,
      );
    }
  }

  void _saveOrder() async {
    if (selectedCustomer == null ||
        productFields.isEmpty ||
        startDate == null ||
        endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Check if enough stock is available
    for (var product in productFields) {
      final availableProduct = widget.availableProducts.firstWhere(
        (p) => p.id == product.productId,
      );
      int available = availableProduct.stock - (availableProduct.rented ?? 0);
      if (product.quantity > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough stock for ${availableProduct.name}. Available: $available',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final newOrder = Order(
      orderId: DateTime.now().millisecondsSinceEpoch,
      customerName: selectedCustomer!.name,
      customerId: int.parse(selectedCustomer!.id),
      orderDate: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      products: productFields,
      status: OrderStatus.active,
    );

    await _updateProductRentals(productFields);
    widget.onCreate(newOrder);
  }

  void _previewOrder() async {
    if (selectedCustomer == null || productFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final previewOrder = Order(
      orderId: DateTime.now().millisecondsSinceEpoch,
      customerName: selectedCustomer!.name,
      customerId: int.parse(selectedCustomer!.id),
      orderDate: DateTime.now(),
      products: productFields,
      status: OrderStatus.active,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => OrderPreviewDialog(order: previewOrder),
    );

    if (confirmed == true) {
      widget.onCreate(previewOrder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Order'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.preview,
                color: Theme.of(context).colorScheme.secondary),
            label: Text(
              'Preview',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            onPressed: _previewOrder,
          ),
          TextButton.icon(
            icon:
                Icon(Icons.save, color: Theme.of(context).colorScheme.primary),
            label: Text(
              'Save',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            onPressed: _saveOrder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Customer>(
              value: selectedCustomer,
              items: widget.customers.map((customer) {
                return DropdownMenuItem(
                  value: customer,
                  child: Text(customer.name),
                );
              }).toList(),
              onChanged: (Customer? value) {
                setState(() => selectedCustomer = value);
              },
              decoration: InputDecoration(
                labelText: 'Select Customer',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                labelStyle:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Products',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: _addProduct,
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: productFields.length,
              itemBuilder: (context, index) {
                return ProductFieldWidget(
                  products: widget.availableProducts,
                  productField: productFields[index],
                  onRemove: () => _removeProduct(index),
                  startDate: startDate,
                  endDate: endDate,
                );
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => startDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        startDate != null
                            ? DateFormat('yyyy-MM-dd').format(startDate!)
                            : 'Select Start Date',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ??
                            (startDate?.add(Duration(days: 7)) ??
                                DateTime.now().add(Duration(days: 7))),
                        firstDate: startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => endDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        endDate != null
                            ? DateFormat('yyyy-MM-dd').format(endDate!)
                            : 'Select End Date',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductFieldWidget extends StatelessWidget {
  final List<Product> products;
  final ProductField productField;
  final VoidCallback onRemove;
  final DateTime? startDate;
  final DateTime? endDate;

  const ProductFieldWidget({
    Key? key,
    required this.products,
    required this.productField,
    required this.onRemove,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  int get rentalDays {
    if (startDate == null || endDate == null) return 1;
    return endDate!.difference(startDate!).inDays + 1;
  }

  double get totalPrice {
    final pricePerDay = productField.price ?? 0;
    return pricePerDay * productField.quantity * rentalDays;
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(child: Text('No products available'));
    }

    Product selectedProduct = products.firstWhere(
      (p) => p.id == productField.productId,
      orElse: () {
        if (products.isNotEmpty) {
          productField.productId = products.first.id;
          productField.productName = products.first.name;
          productField.price = products.first.price;
          return products.first;
        }
        throw StateError('Products list is empty');
      },
    );

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Product Selection - 40% width
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: products.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text('${product.name} (₹${product.price}/day)'),
                      );
                    }).toList(),
                    onChanged: (Product? value) {
                      if (value != null) {
                        productField.productId = value.id;
                        productField.productName = value.name;
                        productField.price = value.price;
                      }
                    },
                  ),
                ),
                SizedBox(width: 12),
                // Quantity Input - 20% width
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: productField.quantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (value) {
                      productField.quantity = int.tryParse(value) ?? 1;
                    },
                  ),
                ),
                SizedBox(width: 12),
                // Price Display - 30% width
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price: ₹${(productField.price ?? 0).toStringAsFixed(2)}/day',
                          style: TextStyle(fontSize: 12),
                        ),
                        if (startDate != null && endDate != null)
                          Text(
                            '$rentalDays days',
                            style: TextStyle(fontSize: 12),
                          ),
                        Text(
                          'Total: ₹${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Remove Button
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: onRemove,
                  color: Colors.red,
                  tooltip: 'Remove Product',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderPreviewDialog extends StatelessWidget {
  final Order order;

  const OrderPreviewDialog({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double orderTotal = order.products.fold(
      0,
      (sum, product) => sum + (product.quantity * (product.price ?? 0)),
    );

    return AlertDialog(
      title: Text('Order Preview'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Customer: ${order.customerName}',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (order.startDate != null)
              Text(
                  'Start Date: ${DateFormat('yyyy-MM-dd').format(order.startDate!)}'),
            if (order.endDate != null)
              Text(
                  'End Date: ${DateFormat('yyyy-MM-dd').format(order.endDate!)}'),
            Divider(),
            Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.products.map((product) => Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(product.productName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quantity: ${product.quantity}'),
                        Text(
                            'Price: ₹${(product.price ?? 0).toStringAsFixed(2)}'),
                        Text(
                            'Total: ₹${(product.quantity * (product.price ?? 0)).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                )),
            Divider(),
            Text(
              'Order Total: ₹${orderTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.check),
          label: Text('Confirm & Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}
