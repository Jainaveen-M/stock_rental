import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/model/customer.dart';
import 'package:stock_rental/model/product_filed.dart';
import 'package:stock_rental/repo/product_db_helper.dart';
import 'package:stock_rental/order/retail_bill_preview.dart';

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
  final _formKey = GlobalKey<FormState>();

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
    double orderTotal = productFields.fold(
      0,
      (sum, product) =>
          sum + (product.quantity * (product.price ?? 0) * _getRentalDays()),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Order'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.preview),
            label: Text('Preview Bill'),
            onPressed: _showBillPreview,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Customer>(
                          value: selectedCustomer,
                          decoration: InputDecoration(
                            labelText: 'Customer',
                            border: OutlineInputBorder(),
                          ),
                          items: widget.customers
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => selectedCustomer = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          label: 'Start Date',
                          value: startDate,
                          onChanged: (date) => setState(() => startDate = date),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker(
                          label: 'End Date',
                          value: endDate,
                          onChanged: (date) => setState(() => endDate = date),
                          minDate: startDate,
                        ),
                      ),
                    ],
                  ),
                  if (startDate != null && endDate != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Rental Period: ${_getRentalDays()} days',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            color: Theme.of(context).primaryColor,
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 4,
                                    child: Text('Product',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 1,
                                    child: Text('Qty',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text('Price/Day',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text('Total',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))),
                                SizedBox(width: 48), // For delete button
                              ],
                            ),
                          ),
                          if (productFields.isEmpty)
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No products added',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ...productFields
                              .map((field) => _buildProductRow(field)),
                          Divider(height: 1),
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Order Total:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(
                                  '₹${orderTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: startDate != null && endDate != null
          ? FloatingActionButton.extended(
              onPressed: _addProduct,
              label: Text('Add Product'),
              icon: Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProductRow(ProductField field) {
    double total = (field.price ?? 0) * field.quantity * _getRentalDays();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<Product>(
              value: widget.availableProducts
                  .firstWhere((p) => p.id == field.productId),
              items: widget.availableProducts
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name),
                      ))
                  .toList(),
              onChanged: (Product? value) {
                if (value != null) {
                  setState(() {
                    field.productId = value.id;
                    field.productName = value.name;
                    field.price = value.price;
                  });
                }
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: field.quantity.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  field.quantity = int.tryParse(value) ?? 1;
                });
              },
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text('₹${(field.price ?? 0).toStringAsFixed(2)}'),
          ),
          Expanded(
            flex: 2,
            child: Text('₹${total.toStringAsFixed(2)}'),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => setState(() => productFields.remove(field)),
          ),
        ],
      ),
    );
  }

  int _getRentalDays() {
    if (startDate == null || endDate == null) return 1;
    return endDate!.difference(startDate!).inDays + 1;
  }

  void _showBillPreview() {
    // Show retail-style bill preview
    showDialog(
      context: context,
      builder: (context) => RetailBillPreview(
        order: Order(
          orderId: DateTime.now().millisecondsSinceEpoch,
          customerName: selectedCustomer?.name ?? '',
          customerId: int.parse(selectedCustomer?.id ?? '0'),
          orderDate: DateTime.now(),
          startDate: startDate,
          endDate: endDate,
          products: productFields,
          status: OrderStatus.active,
        ),
        rentalDays: _getRentalDays(),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
    DateTime? minDate,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: minDate ?? DateTime.now(),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        child: Text(
          value != null
              ? DateFormat('yyyy-MM-dd').format(value)
              : 'Select Date',
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
