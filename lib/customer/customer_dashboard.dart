import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:stock_rental/model/customer.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/repo/customer_db_helper.dart';
import 'package:stock_rental/repo/order_db_helper.dart';
import 'package:stock_rental/repo/payment_db_helper.dart';
import 'package:stock_rental/customer/customer_details_dialog.dart';
import 'package:stock_rental/customer/add_customer_dialog.dart';

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final _customerDatabase = CustomerDatabase();
  final _orderDatabase = OrderDatabase();
  final _paymentDatabase = PaymentDatabase();
  final _searchController = TextEditingController();
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final customers = await _customerDatabase.getAllCustomers();
    setState(() {
      _customers = customers;
    });
  }

  Future<CustomerStats> _loadCustomerStats(String customerId) async {
    final orders = await _orderDatabase.getAllOrders();
    final customerOrders =
        orders.where((o) => o.customerId.toString() == customerId).toList();

    final activeOrders =
        customerOrders.where((o) => o.status == OrderStatus.active).length;
    final closedOrders =
        customerOrders.where((o) => o.status == OrderStatus.closed).length;

    double totalRevenue = 0;
    for (var order in customerOrders) {
      totalRevenue += order.totalAmount ?? 0;
    }

    return CustomerStats(
      activeOrders: activeOrders,
      closedOrders: closedOrders,
      totalRevenue: totalRevenue,
    );
  }

  Future<void> _exportCustomersToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Customers'];

      // Add headers
      sheet.appendRow([
        'Customer ID',
        'Name',
        'Phone Number',
        'Address',
        'Active Orders',
        'Closed Orders',
        'Total Revenue'
      ]);

      // Add data
      for (var customer in _customers) {
        final stats = await _loadCustomerStats(customer.id);
        sheet.appendRow([
          customer.id,
          customer.name,
          customer.phoneNumber,
          customer.address,
          stats.activeOrders.toString(),
          stats.closedOrders.toString(),
          stats.totalRevenue.toStringAsFixed(2),
        ]);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/customers_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);

      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to: $filePath'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export customers: $e')),
      );
    }
  }

  void _showCustomerDetails(Customer customer) async {
    final stats = await _loadCustomerStats(customer.id);
    showDialog(
      context: context,
      builder: (context) => CustomerDetailsDialog(
        customer: customer,
        onUpdate: (updatedCustomer) async {
          await _customerDatabase.updateCustomer(updatedCustomer);
          _loadCustomers();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer updated successfully')),
          );
        },
        onDelete: (customer) async {
          final orders = await _orderDatabase.getAllOrders();
          final hasActiveOrders = orders.any(
            (o) =>
                o.customerId.toString() == customer.id &&
                o.status == OrderStatus.active,
          );

          if (hasActiveOrders) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Cannot delete customer with active orders')),
            );
            return;
          }

          await _customerDatabase.deleteCustomer(customer.id);
          _loadCustomers();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer deleted successfully')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download),
            tooltip: 'Export Customers',
            onPressed: _exportCustomersToExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Customers',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  // Filter will be applied automatically
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                if (_searchController.text.isNotEmpty &&
                    !customer.name
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase()) &&
                    !customer.phoneNumber.contains(_searchController.text)) {
                  return SizedBox.shrink();
                }
                return _buildCustomerCard(customer);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddCustomerDialog(
              onAdd: (customer) async {
                await _customerDatabase.saveCustomer(customer);
                _loadCustomers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Customer added successfully')),
                );
              },
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Customer',
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showCustomerDetails(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: TextStyle(fontSize: 24),
                ),
                radius: 30,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      customer.phoneNumber,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      customer.address,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              FutureBuilder<CustomerStats>(
                future: _loadCustomerStats(customer.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  final stats = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats.activeOrders} Active',
                        style: TextStyle(color: Colors.blue),
                      ),
                      Text(
                        '${stats.closedOrders} Closed',
                        style: TextStyle(color: Colors.green),
                      ),
                      Text(
                        '₹${stats.totalRevenue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
