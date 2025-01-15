import 'package:data_table_2/data_table_2.dart';
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

class CustomerStats {
  final int activeOrders;
  final int closedOrders;
  final double totalRevenue;

  CustomerStats({
    required this.activeOrders,
    required this.closedOrders,
    required this.totalRevenue,
  });
}

class CustomerDashboard extends StatefulWidget {
  @override
  _CustomerDashboardState createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final _customerDatabase = CustomerDatabase();
  final _orderDatabase = OrderDatabase();
  List<Customer> customers = [];
  List<Customer> _paginatedCustomers = [];
  int _rowsPerPage = 10;
  int _currentPage = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _customerDatabase.init();
    _orderDatabase.init();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final allCustomers = await _customerDatabase.getAllCustomers();
    setState(() {
      customers = allCustomers;
      _updatePaginatedCustomers();
    });
  }

  void _updatePaginatedCustomers() {
    final filteredCustomers = customers.where((customer) {
      final searchLower = _searchQuery.toLowerCase();
      return customer.name.toLowerCase().contains(searchLower) ||
          customer.phoneNumber.contains(searchLower) ||
          customer.address.toLowerCase().contains(searchLower);
    }).toList();

    final startIndex = _currentPage * _rowsPerPage;
    setState(() {
      _paginatedCustomers =
          filteredCustomers.skip(startIndex).take(_rowsPerPage).toList();
    });
  }

  Widget _buildCustomersTable() {
    final filteredCustomers = customers.where((customer) {
      final searchLower = _searchQuery.toLowerCase();
      return customer.name.toLowerCase().contains(searchLower) ||
          customer.phoneNumber.contains(searchLower) ||
          customer.address.toLowerCase().contains(searchLower);
    }).toList();

    final totalRows = filteredCustomers.length;
    final totalPages = (totalRows / _rowsPerPage).ceil();

    return Expanded(
      child: Card(
        margin: EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 0;
                    _updatePaginatedCustomers();
                  });
                },
              ),
            ),
            Expanded(
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                columns: [
                  DataColumn2(label: Text('Name'), size: ColumnSize.L),
                  DataColumn2(label: Text('Phone'), size: ColumnSize.M),
                  DataColumn2(label: Text('Address'), size: ColumnSize.L),
                  DataColumn2(label: Text('proof'), size: ColumnSize.M),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                ],
                rows: _paginatedCustomers.map((customer) {
                  return DataRow(
                    cells: [
                      DataCell(Text(customer.name)),
                      DataCell(Text(customer.phoneNumber)),
                      DataCell(Text(customer.address)),
                      DataCell(Text(customer.proofNumber ?? 'Not provided')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showCustomerDetails(customer),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCustomer(customer),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Rows per page: '),
                      DropdownButton<int>(
                        value: _rowsPerPage,
                        items: [10, 20, 50, 100].map((value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _rowsPerPage = value!;
                            _currentPage = 0;
                            _updatePaginatedCustomers();
                          });
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '${_currentPage * _rowsPerPage + 1}-${(_currentPage + 1) * _rowsPerPage > totalRows ? totalRows : (_currentPage + 1) * _rowsPerPage} of $totalRows',
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() {
                                  _currentPage--;
                                  _updatePaginatedCustomers();
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right),
                        onPressed: (_currentPage + 1) < totalPages
                            ? () {
                                setState(() {
                                  _currentPage++;
                                  _updatePaginatedCustomers();
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      for (var customer in customers) {
        final stats = await _loadCustomerStats(customer.id.toString());
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

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Customer'),
        content: CustomerDetailsDialog(
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

            await _customerDatabase.deleteCustomer(customer.id.toString());
            _loadCustomers();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _customerDatabase.deleteCustomer(customer.id.toString());
      _loadCustomers();
    }
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
          _buildCustomersTable(),
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
                future: _loadCustomerStats(customer.id.toString()),
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
