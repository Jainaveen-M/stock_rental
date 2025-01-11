import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/model/customer.dart';
import 'package:stock_rental/model/product_filed.dart';
import 'package:stock_rental/repo/order_db_helper.dart';
import 'package:stock_rental/repo/customer_db_helper.dart';
import 'package:stock_rental/repo/product_db_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:stock_rental/order/create_order_screen.dart';

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.active:
        return 'Active';
      case OrderStatus.closed:
        return 'Closed';
      default:
        return 'Unknown';
    }
  }
}

class OrdersDashboard extends StatefulWidget {
  @override
  _OrdersDashboardState createState() => _OrdersDashboardState();
}

class _OrdersDashboardState extends State<OrdersDashboard> {
  final _orderDatabase = OrderDatabase();
  final _customerDatabase = CustomerDatabase();
  final _productDatabase = ProductDatabase();
  final searchController = TextEditingController();
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  List<Order> orders = [];
  String filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _initializeDatabases();
  }

  Future<void> _initializeDatabases() async {
    await _orderDatabase.init();
    await _customerDatabase.init();
    _loadOrders();
  }

  void _loadOrders() async {
    final allOrders = await _orderDatabase.getAllOrders();
    setState(() {
      orders = allOrders;
    });
  }

  List<Order> _getFilteredOrders() {
    String query = searchController.text.toLowerCase();
    return orders.where((order) {
      bool matchesSearch = order.orderId.toString().contains(query) ||
          order.customerName.toLowerCase().contains(query);

      if (filterStatus == 'All') return matchesSearch;
      return matchesSearch && order.status.name == filterStatus;
    }).toList();
  }

  void _createNewOrder() async {
    final customers = await _customerDatabase.getAllCustomers();
    final productMaps = await _productDatabase.getProducts();
    final products = productMaps.map((map) => Product.fromMap2(map)).toList();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateOrderScreen(
          customers: customers,
          availableProducts: products,
          productDatabase: _productDatabase,
          onCreate: (Order newOrder) async {
            await _orderDatabase.saveOrder(newOrder);
            _loadOrders();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createNewOrder,
            tooltip: 'Create New Order',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(child: _buildOrdersTable()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Orders',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SizedBox(width: 16),
          DropdownButton<String>(
            value: filterStatus,
            items: ['All', 'Active', 'Closed'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) => setState(() => filterStatus = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable() {
    return DataTable2(
      columns: [
        DataColumn2(label: Text('Order ID'), size: ColumnSize.S),
        DataColumn2(label: Text('Customer'), size: ColumnSize.M),
        DataColumn2(label: Text('Order Date'), size: ColumnSize.M),
        DataColumn2(label: Text('Status'), size: ColumnSize.S),
        DataColumn2(label: Text('Products'), size: ColumnSize.S),
        DataColumn2(label: Text('Actions'), size: ColumnSize.L),
      ],
      rows: _getFilteredOrders().map((order) {
        bool hasExpiredProducts = order.products.any((product) =>
            product.endDate!.isBefore(DateTime.now()) &&
            product.status != RentalStatus.closed);

        return DataRow2(
          color: hasExpiredProducts
              ? MaterialStateProperty.all(Colors.red.shade100)
              : null,
          cells: [
            DataCell(Text(order.orderId.toString())),
            DataCell(Text(order.customerName)),
            DataCell(Text(dateFormat.format(order.orderDate))),
            DataCell(_buildStatusChip(order.status.name)),
            DataCell(Text('${order.products.length} items')),
            DataCell(_buildActionButtons(order)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'Active' ? Colors.green[100] : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: status == 'Active' ? Colors.green[900] : Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.visibility),
          tooltip: 'View Details',
          onPressed: () => _showOrderDetails(order),
        ),
        if (order.status.name == 'Active')
          IconButton(
            icon: Icon(Icons.close),
            tooltip: 'Close Order',
            onPressed: () => _closeOrder(order),
          ),
      ],
    );
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(
        order: order,
        onClose: _closeOrder,
        onProductClose: _closeProduct,
        onCustomerView: _showCustomerDetails,
      ),
    );
  }

  Future<void> _closeOrder(Order order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Close Order'),
        content: Text(
            'Are you sure you want to close this order? This will return all rented items to stock.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('Close Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Update order status and all product statuses
      order.status = OrderStatus.closed;
      for (var product in order.products) {
        // Update product status in order
        product.status = RentalStatus.closed;

        // Update product stock in database
        final dbProduct = await _productDatabase.getProduct(product.productId);
        if (dbProduct != null) {
          final updatedProduct = dbProduct.copyWith(
            rented: (dbProduct.rented ?? 0) - product.quantity,
          );
          await _productDatabase.updateProduct(
            updatedProduct.dbKey!,
            updatedProduct.toMap(),
          );
        }
      }

      // Update order in database
      await _orderDatabase.updateOrder(order);
      setState(() {
        _loadOrders(); // Refresh the orders list
      });
    }
  }

  void _closeProduct(Order order, ProductField product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Close Product'),
        content: Text('Are you sure you want to close this product?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: Text('Close Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      product.status = RentalStatus.closed;
      await _orderDatabase.updateOrder(order);
      _loadOrders();
    }
  }

  void _showCustomerDetails(String customerId) async {
    final customer = await _customerDatabase.getCustomer(customerId);
    if (customer != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => CustomerDetailsDialog(customer: customer),
      );
    }
  }
}

class OrderDetailsDialog extends StatelessWidget {
  final Order order;
  final Function(Order) onClose;
  final Function(Order, ProductField) onProductClose;
  final Function(String) onCustomerView;

  const OrderDetailsDialog({
    Key? key,
    required this.order,
    required this.onClose,
    required this.onProductClose,
    required this.onCustomerView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Order Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order ID: ${order.orderId}'),
            Text('Customer: ${order.customerName}'),
            Text('Status: ${order.status.name}'),
            Text('Products:', style: Theme.of(context).textTheme.titleMedium),
            ...order.products.map((product) => ListTile(
                  title: Text(product.productName),
                  subtitle: Text('Quantity: ${product.quantity}'),
                  trailing: product.status != RentalStatus.closed
                      ? IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => onProductClose(order, product),
                        )
                      : null,
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => onCustomerView(order.customerId.toString()),
          child: Text('View Customer'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}

class CustomerDetailsDialog extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsDialog({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Customer Details'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Name: ${customer.name}'),
          Text('ID: ${customer.id}'),
          Text('Contact: ${customer.contact}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
