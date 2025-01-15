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
    return SizedBox(
      width: 300,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                'Name',
                _nameController,
                Icons.person,
                enabled: true,
              ),
              SizedBox(height: 16),
              _buildTextField(
                'Phone',
                _phoneController,
                Icons.phone,
                enabled: true,
              ),
              SizedBox(height: 16),
              _buildTextField(
                'Address',
                _addressController,
                Icons.location_on,
                enabled: true,
                maxLines: 3,
              ),
              SizedBox(height: 16),
              _buildTextField(
                'Proof Number',
                _proofController,
                Icons.perm_identity_outlined,
                enabled: true,
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return SizedBox(
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: !enabled,
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
