import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/repo/product_db_helper.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _db = ProductDatabase();
  List<Product> _products = [];
  final _searchController = TextEditingController();
  String _sortBy = "Name";

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _db.getProducts();
    setState(() {
      _products = products.map((map) => Product.fromMap(map.toMap())).toList();
    });
  }

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? "");
    final categoryController =
        TextEditingController(text: product?.category ?? "");
    final priceController =
        TextEditingController(text: product?.price.toString() ?? "");
    final stockController =
        TextEditingController(text: product?.stock.toString() ?? "0");
    final descriptionController =
        TextEditingController(text: product?.description ?? "");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.4,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    product == null ? Icons.add_box : Icons.edit,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    product == null ? 'Add New Product' : 'Edit Product',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: nameController,
                      label: 'Product Name',
                      icon: Icons.inventory,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: categoryController,
                      label: 'Category',
                      icon: Icons.category,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: priceController,
                      label: 'Price per Day',
                      icon: Icons.attach_money,
                      isNumber: true,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: stockController,
                      label: 'Stock',
                      icon: Icons.inventory_2,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_validateInputs(
                          nameController.text, priceController.text)) {
                        final newProduct = Product(
                          id: product?.id ??
                              DateTime.now().millisecondsSinceEpoch,
                          name: nameController.text,
                          category: categoryController.text,
                          price: double.parse(priceController.text),
                          stock: int.tryParse(stockController.text) ?? 0,
                          description: descriptionController.text,
                        );

                        if (product == null) {
                          await _db.addProduct(newProduct.toMap());
                        } else {
                          await _db.updateProduct(
                              product.dbKey!, newProduct.toMap());
                        }
                        _loadProducts();
                        Navigator.pop(context);
                      }
                    },
                    child:
                        Text(product == null ? 'Add Product' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  bool _validateInputs(String name, String price) {
    if (name.isEmpty) {
      _showError('Product name is required');
      return false;
    }
    if (price.isEmpty || double.tryParse(price) == null) {
      _showError('Valid price is required');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _showProductDialog(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                columns: [
                  DataColumn2(label: Text('ID'), size: ColumnSize.S),
                  DataColumn2(label: Text('Name'), size: ColumnSize.L),
                  DataColumn2(label: Text('Category'), size: ColumnSize.M),
                  DataColumn2(label: Text('Price/Day'), size: ColumnSize.S),
                  DataColumn2(label: Text('Stock'), size: ColumnSize.S),
                  DataColumn2(label: Text('Available'), size: ColumnSize.S),
                  DataColumn2(label: Text('Rented'), size: ColumnSize.S),
                  DataColumn2(label: Text('Actions'), size: ColumnSize.M),
                ],
                rows: _products.map((product) {
                  return DataRow2(
                    cells: [
                      DataCell(Text('#${product.id}')),
                      DataCell(Text(product.name)),
                      DataCell(Text(product.category)),
                      DataCell(Text('₹${product.price.toStringAsFixed(2)}')),
                      DataCell(Text('${product.stock}')),
                      DataCell(
                          Text('${product.stock - (product.rented ?? 0)}')),
                      DataCell(Text('${product.rented ?? 0}')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showProductDialog(product: product),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Implement delete functionality
                            },
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
