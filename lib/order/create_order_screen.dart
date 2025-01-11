import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/model/customer.dart';
import 'package:stock_rental/model/product_filed.dart';

class CreateOrderScreen extends StatefulWidget {
  final List<Customer> customers;
  final List<Product> availableProducts;
  final Function(Order) onCreate;

  const CreateOrderScreen({
    Key? key,
    required this.customers,
    required this.availableProducts,
    required this.onCreate,
  }) : super(key: key);

  @override
  _CreateOrderScreenState createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  late Customer? selectedCustomer;
  List<ProductField> productFields = [];

  @override
  void initState() {
    super.initState();
    selectedCustomer =
        widget.customers.isNotEmpty ? widget.customers.first : null;
  }

  void _addProduct() {
    setState(() {
      productFields.add(ProductField());
    });
  }

  void _removeProduct(int index) {
    setState(() {
      productFields.removeAt(index);
    });
  }

  void _saveOrder() {
    if (selectedCustomer == null || productFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final newOrder = Order(
      orderId: Uuid().v4(),
      customerName: selectedCustomer!.name,
      customerId: selectedCustomer!.id,
      orderDate: DateTime.now(),
      products: productFields,
      status: OrderStatus.active,
    );

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
      orderId: Uuid().v4(),
      customerName: selectedCustomer!.name,
      customerId: selectedCustomer!.id,
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
                );
              },
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

  const ProductFieldWidget({
    Key? key,
    required this.products,
    required this.productField,
    required this.onRemove,
  }) : super(key: key);

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
          return products.first;
        }
        throw StateError('Products list is empty');
      },
    );

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    items: products.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text(product.name),
                      );
                    }).toList(),
                    onChanged: (Product? value) {
                      if (value != null) {
                        productField.productId = value.id;
                        productField.productName = value.name;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Select Product',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: onRemove,
                  color: Colors.red,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: productField.quantity.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      productField.quantity = int.tryParse(value) ?? 1;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: productField.startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        productField.startDate = date;
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        productField.startDate != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(productField.startDate!)
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
                        initialDate: productField.endDate ??
                            (productField.startDate?.add(Duration(days: 7)) ??
                                DateTime.now().add(Duration(days: 7))),
                        firstDate: productField.startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        productField.endDate = date;
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        productField.endDate != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(productField.endDate!)
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

class OrderPreviewDialog extends StatelessWidget {
  final Order order;

  const OrderPreviewDialog({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool hasAllDates =
        !order.products.any((p) => p.startDate == null || p.endDate == null);

    return AlertDialog(
      title: Text('Order Preview'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Customer: ${order.customerName}',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                        if (product.startDate != null)
                          Text(
                              'Start: ${DateFormat('yyyy-MM-dd').format(product.startDate!)}'),
                        if (product.endDate != null)
                          Text(
                              'End: ${DateFormat('yyyy-MM-dd').format(product.endDate!)}'),
                      ],
                    ),
                  ),
                )),
            if (order.products
                .any((p) => p.startDate == null || p.endDate == null))
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '⚠️ Some products are missing dates',
                  style: TextStyle(color: Colors.red),
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
        if (hasAllDates)
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
