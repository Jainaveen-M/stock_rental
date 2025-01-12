import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_rental/model/order.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RetailBillPreview extends StatelessWidget {
  final Order order;
  final int rentalDays;

  const RetailBillPreview({
    Key? key,
    required this.order,
    required this.rentalDays,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double subtotal = order.products.fold<double>(
      0,
      (sum, product) =>
          (sum + (product.quantity * (product.price ?? 0) * rentalDays))
              .toDouble(),
    );
    double tax = subtotal * 0.05;
    double total = subtotal + tax;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () => _printBill(context, total),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(32),
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[700],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('INVOICE #'),
                            Text('INVOICE DATE'),
                            Text('DUE DATE'),
                          ],
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(order.orderId.toString()),
                            Text(DateFormat('MM/dd/yyyy')
                                .format(order.orderDate)),
                            Text(DateFormat('MM/dd/yyyy')
                                .format(order.endDate ?? order.orderDate)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 48),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MY COMPANY NAME',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('1520 E. John Galt Drive'),
                          Text('Suite 300 Box'),
                          Text('Provo, UT 84001'),
                          Text('808.868.8686'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BILL TO:',
                              style: TextStyle(color: Colors.grey)),
                          Text(order.customerName,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Customer ID: ${order.customerId}'),
                          if (order.startDate != null)
                            Text(
                                'Rental Start: ${DateFormat('MM/dd/yyyy').format(order.startDate!)}'),
                          if (order.endDate != null)
                            Text(
                                'Rental End: ${DateFormat('MM/dd/yyyy').format(order.endDate!)}'),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(flex: 3, child: Text('PRODUCTS / SERVICES')),
                          Expanded(child: Text('QTY')),
                          Expanded(child: Text('PRICE/DAY')),
                          Expanded(child: Text('TOTAL')),
                        ],
                      ),
                      ...order.products.map((product) {
                        final total = (product.quantity *
                                (product.price ?? 0) *
                                rentalDays)
                            .toDouble();
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                                bottom:
                                    BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 3, child: Text(product.productName)),
                              Expanded(child: Text('${product.quantity}')),
                              Expanded(
                                  child: Text(
                                      '₹${(product.price ?? 0).toStringAsFixed(2)}')),
                              Expanded(
                                  child: Text('₹${total.toStringAsFixed(2)}')),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      _buildTotalRow('SUBTOTAL', subtotal),
                      _buildTotalRow('TAX 5%', tax),
                      SizedBox(height: 8),
                      Container(
                        color: Colors.grey.shade200,
                        padding: EdgeInsets.all(16),
                        child: _buildTotalRow('AMOUNT DUE', total),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PAYMENT METHODS',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('BANK INFO'),
                        Text('Bank Name Goes Here'),
                        Text('Bank Account: 12345678'),
                        SizedBox(height: 8),
                        Text('PAYPAL'),
                        Text('mycompanyname@email.com'),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.print),
                      label: Text('Print Invoice'),
                      onPressed: () => _printBill(context, total),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(width: 120, child: Text(label)),
          SizedBox(width: 24),
          Text('₹${amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _printBill(BuildContext context, double total) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('RENTAL INVOICE',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice No: ${order.orderId}'),
                    pw.Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Rental Period: $rentalDays days'),
                    if (order.startDate != null)
                      pw.Text(
                          'From: ${DateFormat('dd/MM/yyyy').format(order.startDate!)}'),
                    if (order.endDate != null)
                      pw.Text(
                          'To: ${DateFormat('dd/MM/yyyy').format(order.endDate!)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Customer Details:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Name: ${order.customerName}'),
                  pw.Text('ID: ${order.customerId}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Item', 'Qty', 'Rate/Day', 'Days', 'Amount'],
              data: order.products.map((product) {
                double total =
                    (product.quantity * (product.price ?? 0) * rentalDays)
                        .toDouble();
                return [
                  product.productName,
                  product.quantity.toString(),
                  '₹${(product.price ?? 0).toStringAsFixed(2)}',
                  rentalDays.toString(),
                  '₹${total.toStringAsFixed(2)}',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total Amount: ₹${total.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
