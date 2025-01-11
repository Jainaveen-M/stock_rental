import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/intl.dart';

class AddProductFieldsWidget extends StatefulWidget {
  @override
  _AddProductFieldsWidgetState createState() => _AddProductFieldsWidgetState();
}

class _AddProductFieldsWidgetState extends State<AddProductFieldsWidget> {
  List<ProductField> _productFields = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display the dynamic product input fields
        ..._productFields.map((field) {
          return ProductFieldWidget(
            productField: field,
            onRemove: () {
              setState(() {
                _productFields.remove(field);
              });
            },
          );
        }).toList(),

        // Button to add a new product input field
        ElevatedButton(
          onPressed: () {
            setState(() {
              _productFields.add(ProductField());
            });
          },
          child: Text('Add Product'),
        ),
      ],
    );
  }
}

class ProductField {
  String? productName;
  int quantity = 1;
  DateTime? startDate;
  DateTime? endDate;
}

class ProductFieldWidget extends StatefulWidget {
  final ProductField productField;
  final VoidCallback onRemove;

  ProductFieldWidget({required this.productField, required this.onRemove});

  @override
  _ProductFieldWidgetState createState() => _ProductFieldWidgetState();
}

class _ProductFieldWidgetState extends State<ProductFieldWidget> {
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();

  void _pickDate(BuildContext context, bool isStartDate) async {
    DateTime? selectedDate = await DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime.now().add(Duration(days: 365)),
      // theme: DatePickerTheme(
      //   headerColor: Colors.blue,
      //   backgroundColor: Colors.white,
      //   itemStyle: TextStyle(color: Colors.black),
      //   doneStyle: TextStyle(color: Colors.blue),
      // ),
    );
    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          widget.productField.startDate = selectedDate;
        } else {
          widget.productField.endDate = selectedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Dropdown or TextField
          Row(
            children: [
              TextFormField(
                controller: _productController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                ),
                onChanged: (value) {
                  widget.productField.productName = value;
                },
              ),

              // Quantity Field
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  widget.productField.quantity = int.tryParse(value) ?? 1;
                },
              ),
            ],
          ),

          // Start Date Picker
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _pickDate(context, true),
                child: Text(widget.productField.startDate == null
                    ? 'Select Start Date'
                    : 'Start Date: ${DateFormat.yMMMd().format(widget.productField.startDate!)}'),
              ),
            ],
          ),

          // End Date Picker
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _pickDate(context, false),
                child: Text(widget.productField.endDate == null
                    ? 'Select End Date'
                    : 'End Date: ${DateFormat.yMMMd().format(widget.productField.endDate!)}'),
              ),
            ],
          ),

          // Remove Button
          TextButton(
            onPressed: widget.onRemove,
            child: Text('Remove Product'),
          ),
        ],
      ),
    );
  }
}
