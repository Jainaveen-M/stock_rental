import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/model/customer.dart';
import 'package:stock_rental/model/product_filed.dart';
import 'package:stock_rental/repo/product_db_helper.dart';
import 'package:stock_rental/order/retail_bill_preview.dart';
import 'package:stock_rental/model/payment.dart';
import 'package:stock_rental/repo/payment_db_helper.dart';

class SearchableDropdown extends StatelessWidget {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final Function(Customer?) onChanged;

  const SearchableDropdown({
    Key? key,
    required this.customers,
    required this.selectedCustomer,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Customer>(
      initialValue: selectedCustomer,
      onSelected: onChanged,
      constraints: BoxConstraints(maxHeight: 400),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedCustomer?.name ?? 'Select Customer',
                style: TextStyle(fontSize: 16),
              ),
            ),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      offset: Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) {
        return [
          PopupMenuItem<Customer>(
            enabled: false,
            child: SearchField(
              onChanged: (query) {
                // Rebuild the popup with filtered results
                Navigator.pop(context);
                Future.delayed(Duration(milliseconds: 50), () {
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(0, 40, 0, 0),
                    items: _buildItems(query),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                });
              },
            ),
          ),
          ...customers
              .map((customer) => PopupMenuItem<Customer>(
                    value: customer,
                    child: Text(customer.name),
                  ))
              .toList(),
        ];
      },
    );
  }

  List<PopupMenuEntry<Customer>> _buildItems(String? query) {
    var filteredCustomers = customers;
    if (query != null && query.isNotEmpty) {
      filteredCustomers = customers
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.phoneNumber.contains(query))
          .toList();
    }

    return [
      PopupMenuItem<Customer>(
        enabled: false,
        child: SearchField(onChanged: (q) => _buildItems(q)),
      ),
      ...filteredCustomers.map((customer) => PopupMenuItem<Customer>(
            value: customer,
            child: Text(customer.name),
          )),
    ];
  }
}

class SearchField extends StatelessWidget {
  final Function(String) onChanged;

  const SearchField({Key? key, required this.onChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search customer...',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onChanged: onChanged,
    );
  }
}

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
  final _advanceController = TextEditingController();
  String _selectedPaymentMode = 'cash';
  final _paymentDatabase = PaymentDatabase();

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

  double _calculateTotal() {
    if (startDate == null || endDate == null) return 0.0;

    int rentalDays = endDate!.difference(startDate!).inDays + 1;
    return productFields.fold<double>(
      0.0,
      (sum, product) =>
          sum + (product.quantity * (product.price ?? 0) * rentalDays),
    );
  }

  double _calculateBalance() {
    double total = _calculateTotal();
    double advance = double.tryParse(_advanceController.text) ?? 0.0;
    return total - advance;
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

    final totalAmount = _calculateTotal();
    final advanceAmount = double.tryParse(_advanceController.text) ?? 0.0;
    final balanceAmount = totalAmount - advanceAmount;

    final newOrder = Order(
      orderId: DateTime.now().millisecondsSinceEpoch,
      customerName: selectedCustomer!.name,
      customerId: int.parse(selectedCustomer!.id.toString()),
      orderDate: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      products: productFields,
      status: OrderStatus.active,
      advanceAmount: advanceAmount,
      totalAmount: totalAmount,
    );

    await _updateProductRentals(productFields);
    widget.onCreate(newOrder);

    // Save the payment record
    final payment = Payment(
      orderId: newOrder.orderId,
      totalAmount: totalAmount,
      advanceAmount: advanceAmount,
      balanceAmount: balanceAmount,
      paymentDate: DateTime.now(),
      paymentMode: _selectedPaymentMode,
      status: balanceAmount > 0 ? 'partial' : 'completed',
    );

    await _paymentDatabase.savePayment(payment);
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
      customerId: int.parse(selectedCustomer!.id.toString()),
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
            label: Text('Preview'),
            onPressed: _showBillPreview,
          ),
          TextButton.icon(
            icon: Icon(Icons.save),
            label: Text('Save Order'),
            onPressed: () {
              if (selectedCustomer == null ||
                  productFields.isEmpty ||
                  startDate == null ||
                  endDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please fill all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Order'),
                  content: Text('Are you sure you want to save this order?'),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    ElevatedButton(
                      child: Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _saveOrder();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: 16),
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
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SearchableDropdown(
                          customers: widget.customers,
                          selectedCustomer: selectedCustomer,
                          onChanged: (customer) {
                            setState(() {
                              selectedCustomer = customer;
                            });
                          },
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
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Card(
                        elevation: 4,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                                border: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 1,
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
                                      flex: 1,
                                      child: Text('Price/Day',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
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
                            Divider(
                              height: 1,
                            ),
                            Container(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 200,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Details',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Total Amount: ₹${_calculateTotal().toStringAsFixed(2)}',
                                          style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _advanceController,
                                    decoration: InputDecoration(
                                      labelText: 'Advance Amount',
                                      prefixText: '₹',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (value) {
                                      setState(
                                          () {}); // Trigger rebuild to update balance
                                    },
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        double? advance =
                                            double.tryParse(value);
                                        if (advance != null &&
                                            advance > _calculateTotal()) {
                                          return 'Advance cannot exceed total';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Balance: ₹${_calculateBalance().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedPaymentMode,
                              decoration: InputDecoration(
                                labelText: 'Payment Mode',
                                border: OutlineInputBorder(),
                              ),
                              items: ['cash', 'card', 'upi']
                                  .map((mode) => DropdownMenuItem(
                                        value: mode,
                                        child: Text(mode.toUpperCase()),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPaymentMode = value!;
                                });
                              },
                            ),
                          ],
                        ),
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
    int rentalDays = _getRentalDays();
    double total = (field.price ?? 0) * field.quantity * rentalDays;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 38,
              child: DropdownButtonFormField<Product>(
                isDense: true,
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
                    });
                  }
                },
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 38,
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
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 38,
              child: TextFormField(
                initialValue: (field.price ?? 0).toStringAsFixed(2),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  border: OutlineInputBorder(),
                  prefixText: '₹',
                ),
                onChanged: (value) {
                  setState(() {
                    field.price = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
            ),
          ),
          Expanded(
            flex: 1,
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
    if (selectedCustomer == null ||
        productFields.isEmpty ||
        startDate == null ||
        endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final previewOrder = Order(
      orderId: DateTime.now().millisecondsSinceEpoch,
      customerName: selectedCustomer!.name,
      customerId: int.parse(selectedCustomer!.id.toString()),
      orderDate: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      products: productFields,
      status: OrderStatus.active,
      advanceAmount: double.tryParse(_advanceController.text) ?? 0.0,
      totalAmount: _calculateTotal(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RetailBillPreview(
          order: previewOrder,
          rentalDays: endDate!.difference(startDate!).inDays + 1,
          advanceAmount: double.tryParse(_advanceController.text) ?? 0.0,
          balanceAmount: _calculateTotal() -
              (double.tryParse(_advanceController.text) ?? 0.0),
        ),
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
