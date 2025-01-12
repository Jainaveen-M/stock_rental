import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:stock_rental/model/payment.dart';
import 'package:stock_rental/repo/payment_db_helper.dart';
import 'package:stock_rental/repo/order_db_helper.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/order/retail_bill_preview.dart';

class PaymentDashboard extends StatefulWidget {
  @override
  _PaymentDashboardState createState() => _PaymentDashboardState();
}

class _PaymentDashboardState extends State<PaymentDashboard> {
  final _paymentDatabase = PaymentDatabase();
  final _orderDatabase = OrderDatabase();
  List<Payment> _payments = [];
  Map<int, Order> _orders = {};
  int _rowsPerPage = 10;
  int _currentPage = 0;
  List<Payment> _paginatedPayments = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final orders = await _orderDatabase.getAllOrders();
    _orders = {for (var order in orders) order.orderId: order};

    final allPayments = await _paymentDatabase.getAllPayments();
    setState(() {
      _payments = allPayments;
      _updatePaginatedPayments();
    });
  }

  void _updatePaginatedPayments() {
    final filteredPayments = _payments.where((payment) {
      final order = _orders[payment.orderId];
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = payment.orderId.toString().contains(searchLower) ||
          (order?.customerName.toLowerCase().contains(searchLower) ?? false) ||
          payment.paymentMode.toLowerCase().contains(searchLower) ||
          payment.status.toLowerCase().contains(searchLower);

      final matchesStatus = _selectedStatus == 'All' ||
          payment.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;

    setState(() {
      _paginatedPayments = filteredPayments.sublist(
        startIndex,
        endIndex > filteredPayments.length ? filteredPayments.length : endIndex,
      );
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Order ID, Customer, Payment Mode...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                  _updatePaginatedPayments();
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _currentPage = 0;
                  _updatePaginatedPayments();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildSearchBar()),
          SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedStatus,
            items: ['All', 'completed', 'partial']
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: status == 'completed'
                                  ? Colors.green
                                  : status == 'partial'
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(status.toUpperCase()),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
                _currentPage = 0;
                _updatePaginatedPayments();
              });
            },
          ),
        ],
      ),
    );
  }

  void _showCustomerInfo(Order? order) {
    if (order == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Customer Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${order.customerName}'),
            Text('ID: ${order.customerId}'),
            if (order.startDate != null)
              Text(
                  'Rental Start: ${DateFormat('dd/MM/yyyy').format(order.startDate!)}'),
            if (order.endDate != null)
              Text(
                  'Rental End: ${DateFormat('dd/MM/yyyy').format(order.endDate!)}'),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showInvoicePreview(Order? order, Payment payment) {
    if (order == null) return;

    final totalAmount = order.totalAmount ?? 0.0;
    final advanceAmount = order.advanceAmount ?? 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RetailBillPreview(
          order: order,
          rentalDays: order.endDate != null && order.startDate != null
              ? order.endDate!.difference(order.startDate!).inDays + 1
              : 1,
          advanceAmount: advanceAmount,
          balanceAmount: totalAmount - advanceAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRows = _payments.where((payment) {
      final order = _orders[payment.orderId];
      final searchLower = _searchQuery.toLowerCase();

      return payment.orderId.toString().contains(searchLower) ||
          (order?.customerName.toLowerCase().contains(searchLower) ?? false) ||
          payment.paymentMode.toLowerCase().contains(searchLower) ||
          payment.status.toLowerCase().contains(searchLower);
    }).length;

    final totalPages = (totalRows / _rowsPerPage).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
      ),
      body: Card(
        margin: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Payment Records',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildFilters(),
            Expanded(
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                columns: [
                  DataColumn2(label: Text('Order ID'), size: ColumnSize.S),
                  DataColumn2(label: Text('Invoice'), size: ColumnSize.S),
                  DataColumn2(label: Text('Customer'), size: ColumnSize.M),
                  DataColumn2(label: Text('Total Amount'), size: ColumnSize.S),
                  DataColumn2(label: Text('Advance Paid'), size: ColumnSize.S),
                  DataColumn2(label: Text('Balance'), size: ColumnSize.S),
                  DataColumn2(label: Text('Payment Date'), size: ColumnSize.M),
                  DataColumn2(label: Text('Payment Mode'), size: ColumnSize.S),
                  DataColumn2(label: Text('Status'), size: ColumnSize.S),
                ],
                rows: _paginatedPayments.map((payment) {
                  final order = _orders[payment.orderId];
                  return DataRow2(
                    cells: [
                      DataCell(Text('#${payment.orderId}')),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.receipt, size: 20),
                          onPressed: () => _showInvoicePreview(
                              _orders[payment.orderId], payment),
                          tooltip: 'View Invoice',
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(order?.customerName ?? 'Unknown'),
                            IconButton(
                              icon: Icon(Icons.info_outline, size: 20),
                              onPressed: () => _showCustomerInfo(order),
                              tooltip: 'Customer Info',
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                          Text('₹${payment.totalAmount.toStringAsFixed(2)}')),
                      DataCell(
                          Text('₹${payment.advanceAmount.toStringAsFixed(2)}')),
                      DataCell(
                          Text('₹${payment.balanceAmount.toStringAsFixed(2)}')),
                      DataCell(Text(DateFormat('dd/MM/yyyy')
                          .format(payment.paymentDate))),
                      DataCell(Text(payment.paymentMode.toUpperCase())),
                      DataCell(
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: payment.status == 'completed'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            payment.status.toUpperCase(),
                            style: TextStyle(
                              color: payment.status == 'completed'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
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
                            _updatePaginatedPayments();
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
                      SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() {
                                  _currentPage--;
                                  _updatePaginatedPayments();
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
                                  _updatePaginatedPayments();
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
}
