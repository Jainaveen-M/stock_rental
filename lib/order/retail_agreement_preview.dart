import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stock_rental/model/order.dart';

class RetailAgreementPreview extends StatelessWidget {
  final Order order;
  final int rentalDays;
  final double advanceAmount;
  final double balanceAmount;

  const RetailAgreementPreview({
    Key? key,
    required this.order,
    required this.rentalDays,
    required this.advanceAmount,
    required this.balanceAmount,
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
            onPressed: () => _printBill(context, total, subtotal, tax),
          ),
          IconButton(
            icon: Icon(Icons.save_alt),
            onPressed: () => _saveAsPdf(context, total, subtotal, tax),
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
                      'Rental Agreement',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[700],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Order ID: #${order.orderId}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          DateFormat('dd/MM/yyyy')
                              .format(order.rentalAgreement!.agreementDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 32),
                _buildCustomerDetails(),
                SizedBox(height: 16),
                Text(
                  'Rental Days: $rentalDays',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 32),
                _buildProductTable(),
                SizedBox(height: 32),
                _buildTotalRow('Subtotal', subtotal),
                _buildTotalRow('Tax (5%)', tax),
                _buildTotalRow('Total', total),
                _buildTotalRow('Advance Paid', advanceAmount),
                _buildTotalRow('Balance Due', balanceAmount,
                    isHighlighted: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _printBill(
      BuildContext context, double total, double subtotal, double tax) async {
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
                    pw.Text(
                        'Customer: ${order.rentalAgreement!.customer.name}'),
                    pw.Text('Order ID: #${order.orderId}'),
                  ],
                ),
                pw.Text(DateFormat('dd/MM/yyyy')
                    .format(order.rentalAgreement!.startDate!)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Rental Days: $rentalDays',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Product', 'Quantity', 'Price', 'Total'],
                ...order.products.map((product) => [
                      product.productName,
                      product.quantity.toString(),
                      '₹${product.price?.toStringAsFixed(2) ?? '0.00'}',
                      '₹${(product.quantity * (product.price ?? 0)).toStringAsFixed(2)}'
                    ])
              ],
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
                  pw.Text('Tax (5%): ₹${tax.toStringAsFixed(2)}'),
                  pw.Text('Total: ₹${total.toStringAsFixed(2)}'),
                  pw.Text('Advance Paid: ₹${advanceAmount.toStringAsFixed(2)}'),
                  pw.Text('Balance Due: ₹${balanceAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _saveAsPdf(
      BuildContext context, double total, double subtotal, double tax) async {
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
                    pw.Text(
                        'Customer: ${order.rentalAgreement!.customer.name}'),
                    pw.Text('Order ID: #${order.orderId}'),
                  ],
                ),
                pw.Text(DateFormat('dd/MM/yyyy')
                    .format(order.rentalAgreement!.agreementDate)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('Rental Days: $rentalDays',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Product', 'Quantity', 'Price', 'Total'],
                ...order.products.map((product) => [
                      product.productName,
                      product.quantity.toString(),
                      '₹${product.price?.toStringAsFixed(2) ?? '0.00'}',
                      '₹${(product.quantity * (product.price ?? 0)).toStringAsFixed(2)}'
                    ])
              ],
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
                  pw.Text('Tax (5%): ₹${tax.toStringAsFixed(2)}'),
                  pw.Text('Total: ₹${total.toStringAsFixed(2)}'),
                  pw.Text('Advance Paid: ₹${advanceAmount.toStringAsFixed(2)}'),
                  pw.Text('Balance Due: ₹${balanceAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/invoice_${order.orderId}.pdf");
    log("path to pdf --- ${output.path}/invoice_${order.orderId}.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invoice saved as PDF: ${file.path}')),
    );
  }

  Widget _buildCustomerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8),
        Text('Name: ${order.rentalAgreement!.customer.name}'),
        Text('Order ID: #${order.orderId}'),
      ],
    );
  }

  Widget _buildProductTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[200]),
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Product',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text('Quantity',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child:
                  Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child:
                  Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...order.products.map((product) {
          return TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(product.productName),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(product.quantity.toString()),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text('₹${product.price?.toStringAsFixed(2) ?? '0.00'}'),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                    '₹${(product.quantity * (product.price ?? 0)).toStringAsFixed(2)}'),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(width: 120, child: Text(label)),
          SizedBox(width: 24),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
