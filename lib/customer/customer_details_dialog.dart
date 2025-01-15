import 'package:flutter/material.dart';
import 'package:stock_rental/model/customer.dart';

class CustomerDetailsDialog extends StatelessWidget {
  final Customer customer;
  final Function(Customer) onUpdate;
  final Function(Customer) onDelete;
  final _formKey = GlobalKey<FormState>();
  final _nameController;
  final _phoneController;
  final _addressController;
  final _proofController;

  CustomerDetailsDialog({
    required this.customer,
    required this.onUpdate,
    required this.onDelete,
  })  : _nameController = TextEditingController(text: customer.name),
        _phoneController = TextEditingController(text: customer.phoneNumber),
        _addressController = TextEditingController(text: customer.address),
        _proofController = TextEditingController(text: customer.proofNumber);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Phone number is required' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Address is required' : null,
              ),
              TextFormField(
                controller: _proofController,
                decoration: InputDecoration(
                  labelText: 'proof Number',
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
                maxLength: 12,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value.length != 12) {
                      return 'proof number must be 12 digits';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Only numbers are allowed';
                    }
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        final updatedCustomer = Customer(
                          id: customer.id,
                          name: _nameController.text,
                          phoneNumber: _phoneController.text,
                          address: _addressController.text,
                          proofNumber: _proofController.text.isEmpty
                              ? null
                              : _proofController.text,
                        );
                        onUpdate(updatedCustomer);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
