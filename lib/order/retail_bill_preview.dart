import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stock_rental/model/order.dart';

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
        width: 400,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RENTAL INVOICE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Invoice No: ${order.orderId}'),
                Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
              ],
            ),
            SizedBox(height: 8),
            Divider(),
            Text('Customer Details:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(order.customerName),
            SizedBox(height: 16),
            Table(
              columnWidths: {
                0: FlexColumnWidth(4),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    TableCell(
                        child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Item',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    TableCell(
                        child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Qty',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    TableCell(
                        child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Rate',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                    TableCell(
                        child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Amount',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                  ],
                ),
                ...order.products.map((product) {
                  double total =
                      (product.quantity * (product.price ?? 0) * rentalDays)
                          .toDouble();
                  return TableRow(
                    children: [
                      TableCell(
                          child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(product.productName),
                      )),
                      TableCell(
                          child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('${product.quantity}'),
                      )),
                      TableCell(
                          child: Padding(
                        padding: EdgeInsets.all(8),
                        child:
                            Text('₹${(product.price ?? 0).toStringAsFixed(2)}'),
                      )),
                      TableCell(
                          child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('₹${total.toStringAsFixed(2)}'),
                      )),
                    ],
                  );
                }).toList(),
              ],
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rental Period:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$rentalDays days'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '₹${orderTotal.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Implement save functionality
                    Navigator.pop(context);
                  },
                  child: Text('Save Order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
