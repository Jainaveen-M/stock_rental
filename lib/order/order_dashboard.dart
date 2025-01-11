import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_rental/add_product.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/repo/order_db_helper.dart';
import 'package:intl/intl.dart';

class OrdersDashboard extends StatefulWidget {
  @override
  _OrdersDashboardState createState() => _OrdersDashboardState();
}

class _OrdersDashboardState extends State<OrdersDashboard> {
  final _orderDatabase = OrderDatabase();
  final searchController = TextEditingController();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    _orderDatabase.init().then((_) {
      _loadOrders();
    });
  }

  // Load orders from the database
  void _loadOrders() async {
    final allOrders = await _orderDatabase.getAllOrders();
    setState(() {
      orders = allOrders;
    });
  }

  // Filter orders by search query
  List<Order> _getFilteredOrders() {
    String query = searchController.text.toLowerCase();
    return orders.where((order) {
      return order.orderId.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query);
    }).toList();
  }

  // Create a new order
  void _createNewOrder() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: NewOrderDialog(
            onCreate: (newOrder) {
              _orderDatabase.saveOrder(newOrder);
              _loadOrders();
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  // Edit an order
  void _editOrder(Order order) {
    showDialog(
      context: context,
      builder: (context) {
        return EditOrderDialog(
          order: order,
          onUpdate: (updatedOrder) {
            _orderDatabase.updateOrder(updatedOrder);
            _loadOrders();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  // Mark order as closed
  void _closeOrder(Order order) async {
    order.status = 'Closed';
    await _orderDatabase.updateOrder(order);
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Orders"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createNewOrder,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Orders',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getFilteredOrders().length,
              itemBuilder: (context, index) {
                Order order = _getFilteredOrders()[index];
                return Card(
                  child: ListTile(
                    title: Text('Order ID: ${order.orderId}'),
                    subtitle: Text(
                        'Customer: ${order.customerName}\nStatus: ${order.status}'),
                    onTap: () => _editOrder(order),
                    trailing: order.status == 'Active'
                        ? IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => _closeOrder(order),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NewOrderDialog extends StatelessWidget {
  final Function(Order) onCreate;

  NewOrderDialog({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Create New Order"),
      content: CreateOrderForm(onCreate: onCreate),
    );
  }
}

class EditOrderDialog extends StatelessWidget {
  final Order order;
  final Function(Order) onUpdate;

  EditOrderDialog({required this.order, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Order"),
      content: CreateOrderForm(
        onCreate: onUpdate,
        initialOrder: order,
      ),
    );
  }
}

class CreateOrderForm extends StatefulWidget {
  final Function(Order) onCreate;
  final Order? initialOrder;

  CreateOrderForm({required this.onCreate, this.initialOrder});

  @override
  _CreateOrderFormState createState() => _CreateOrderFormState();
}

class _CreateOrderFormState extends State<CreateOrderForm> {
  final _customerNameController = TextEditingController();
  final _productsController = TextEditingController();
  final _orderIdController = TextEditingController();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _orderIdController.text = widget.initialOrder!.orderId;
      _customerNameController.text = widget.initialOrder!.customerName;
      products = widget.initialOrder!.products;
    }
  }

  void _saveOrder() {
    final order = Order(
      orderId: _orderIdController.text,
      customerName: _customerNameController.text,
      orderDate: DateTime.now(),
      products: products,
    );
    widget.onCreate(order);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _orderIdController,
          decoration: InputDecoration(labelText: 'Order ID'),
        ),
        TextField(
          controller: _customerNameController,
          decoration: InputDecoration(labelText: 'Customer Name'),
        ),
        // Add product creation/editing here
        ElevatedButton(
          onPressed: _saveOrder,
          child: Text('Save Order'),
        ),
        AddProductFieldsWidget()
      ],
    );
  }
}
