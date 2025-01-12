import 'package:flutter/material.dart';
import 'package:stock_rental/model/customer.dart';

class CustomerDetailsDialog extends StatefulWidget {
  final Customer customer;
  final Function(Customer) onUpdate;
  final Function(Customer) onDelete;

  const CustomerDetailsDialog({
    Key? key,
    required this.customer,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  _CustomerDetailsDialogState createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<CustomerDetailsDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    _addressController = TextEditingController(text: widget.customer.address);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isEditing ? Icons.save : Icons.edit),
                      onPressed: () {
                        if (_isEditing) {
                          final updatedCustomer = widget.customer.copyWith(
                            name: _nameController.text,
                            phoneNumber: _phoneController.text,
                            address: _addressController.text,
                          );
                          widget.onUpdate(updatedCustomer);
                        }
                        setState(() {
                          _isEditing = !_isEditing;
                        });
                      },
                      tooltip: _isEditing ? 'Save' : 'Edit',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(context),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            _buildTextField(
              'Name',
              _nameController,
              Icons.person,
              enabled: _isEditing,
            ),
            SizedBox(height: 16),
            _buildTextField(
              'Phone',
              _phoneController,
              Icons.phone,
              enabled: _isEditing,
            ),
            SizedBox(height: 16),
            _buildTextField(
              'Address',
              _addressController,
              Icons.location_on,
              enabled: _isEditing,
              maxLines: 3,
            ),
            SizedBox(height: 24),
            if (!_isEditing) _buildCustomerStats(),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          ],
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
    return TextField(
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
    );
  }

  Widget _buildCustomerStats() {
    return FutureBuilder<CustomerStats>(
      future: _loadCustomerStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  'Active Orders',
                  stats.activeOrders.toString(),
                  Icons.pending_actions,
                  Colors.blue,
                ),
                SizedBox(width: 16),
                _buildStatCard(
                  'Closed Orders',
                  stats.closedOrders.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                SizedBox(width: 16),
                _buildStatCard(
                  'Total Revenue',
                  '₹${stats.totalRevenue.toStringAsFixed(2)}',
                  Icons.payments,
                  Colors.purple,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<CustomerStats> _loadCustomerStats() async {
    // Implement this method to load customer statistics
    // This should query your local database for orders and payments
    return CustomerStats(
      activeOrders: 0,
      closedOrders: 0,
      totalRevenue: 0,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete this customer? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              widget.onDelete(widget.customer);
              Navigator.pop(context); // Close details dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
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
