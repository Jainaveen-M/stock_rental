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
import 'package:stock_rental/order/retail_bill_preview.dart';

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
    double totalRevenue = orders
        .where((o) => o.status == OrderStatus.active)
        .fold(0, (sum, order) => sum + order.orderTotal);

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterSection(),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(
                          'Active Orders',
                          orders
                              .where((o) => o.status == OrderStatus.active)
                              .length
                              .toString(),
                          Icons.pending_actions,
                          Colors.blue,
                        ),
                        SizedBox(width: 16),
                        _buildStatCard(
                          'Completed',
                          orders
                              .where((o) => o.status == OrderStatus.closed)
                              .length
                              .toString(),
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildStatCard(
                      'Total Revenue',
                      '₹${totalRevenue.toStringAsFixed(2)}',
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildOrdersTable(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewOrder,
        label: Text('New Order'),
        icon: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
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

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          height: 100,
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTable() {
    return Card(
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 4,
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        columns: [
          DataColumn2(label: Text('Order ID'), size: ColumnSize.S),
          DataColumn2(label: Text('Customer'), size: ColumnSize.M),
          DataColumn2(label: Text('Start Date'), size: ColumnSize.M),
          DataColumn2(label: Text('End Date'), size: ColumnSize.M),
          DataColumn2(label: Text('Status'), size: ColumnSize.S),
          DataColumn2(label: Text('Actions'), size: ColumnSize.L),
        ],
        rows: _getFilteredOrders().map((order) {
          bool isExpired = order.endDate != null &&
              order.endDate!.isBefore(DateTime.now()) &&
              order.status != OrderStatus.closed;

          return DataRow2(
            color: isExpired
                ? MaterialStateProperty.all(Colors.red.shade50)
                : null,
            cells: [
              DataCell(Text(
                '#${order.orderId.toString()}',
                style: TextStyle(fontWeight: FontWeight.bold),
              )),
              DataCell(Text(order.customerName)),
              DataCell(
                  Text(dateFormat.format(order.startDate ?? order.orderDate))),
              DataCell(Text(order.endDate != null
                  ? dateFormat.format(order.endDate!)
                  : 'Not set')),
              DataCell(_buildStatusChip(order.status.name)),
              DataCell(_buildActionButtons(order)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Active':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'Closed':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
      default:
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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
          tooltip: 'View Bill',
          onPressed: () => _showBillPreview(order),
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

  void _showBillPreview(Order order) {
    showDialog(
      context: context,
      builder: (context) => RetailBillPreview(
        order: order,
        rentalDays: order.endDate != null && order.startDate != null
            ? order.endDate!.difference(order.startDate!).inDays + 1
            : 1,
      ),
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
          Text('Contact: ${customer.phoneNumber}'),
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
