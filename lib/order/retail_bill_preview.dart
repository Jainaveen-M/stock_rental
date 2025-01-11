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
    double orderTotal = order.products.fold<double>(
      0,
      (sum, product) =>
          (sum + (product.quantity * (product.price ?? 0) * rentalDays))
              .toDouble(),
    );

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RENTAL INVOICE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.print),
                      label: Text('Print'),
                      onPressed: () => _printBill(context, orderTotal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoice No: ${order.orderId}',
                        style: TextStyle(fontSize: 16)),
                    Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rental Period: $rentalDays days',
                        style: TextStyle(fontSize: 16)),
                    if (order.startDate != null)
                      Text(
                          'From: ${DateFormat('dd/MM/yyyy').format(order.startDate!)}',
                          style: TextStyle(fontSize: 16)),
                    if (order.endDate != null)
                      Text(
                          'To: ${DateFormat('dd/MM/yyyy').format(order.endDate!)}',
                          style: TextStyle(fontSize: 16)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Details:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Name: ${order.customerName}',
                      style: TextStyle(fontSize: 16)),
                  Text('ID: ${order.customerId}',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Rate/Day')),
                      DataColumn(label: Text('Days')),
                      DataColumn(label: Text('Amount')),
                    ],
                    rows: order.products.map((product) {
                      double total =
                          (product.quantity * (product.price ?? 0) * rentalDays)
                              .toDouble();
                      return DataRow(cells: [
                        DataCell(Text(product.productName)),
                        DataCell(Text('${product.quantity}')),
                        DataCell(Text(
                            '₹${(product.price ?? 0).toStringAsFixed(2)}')),
                        DataCell(Text('$rentalDays')),
                        DataCell(Text('₹${total.toStringAsFixed(2)}')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('₹${orderTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor)),
                ],
              ),
            ),
          ],
        ),
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
