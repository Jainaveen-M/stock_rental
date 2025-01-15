import 'dart:math';

import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:stock_rental/config/app_theme.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/repo/product_db_helper.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _db = ProductDatabase();
  List<Product> _products = [];
  List<Product> _paginatedProducts = [];
  final _searchController = TextEditingController();
  String _sortBy = "Name";

  // Pagination variables
  int _rowsPerPage = 10;
  int _currentPage = 0;
  int get _startIndex => _currentPage * _rowsPerPage;
  int get _endIndex =>
      min(_startIndex + _rowsPerPage, _filteredProducts.length);

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final search = _searchController.text.toLowerCase();
      return product.name.toLowerCase().contains(search) ||
          product.category.toLowerCase().contains(search);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadProducts() async {
    final products = await _db.getProducts();
    setState(() {
      _products = products.map((map) => Product.fromMap(map.toMap())).toList();
      _updatePaginatedProducts();
    });
  }

  void _showProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? "");
    final categoryController =
        TextEditingController(text: product?.category ?? "");
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
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    product == null ? 'Add New Product' : 'Edit Product',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeRegular,
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
                      if (_validateInputs(nameController.text)) {
                        final newProduct = Product(
                          id: product?.id ??
                              DateTime.now().millisecondsSinceEpoch,
                          name: nameController.text,
                          category: categoryController.text,
                          stock: int.tryParse(stockController.text) ?? 0,
                          description: descriptionController.text,
                          rented: product?.rented ?? 0,
                        );

                        if (product == null) {
                          await _db.addProduct(newProduct.toMap());
                        } else {
                          final dbProduct = await _db.getProduct(product.id);
                          if (dbProduct != null) {
                            await _db.updateProduct(
                                dbProduct.dbKey!, newProduct.toMap());
                          }
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
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            size: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          labelStyle: TextStyle(
            fontSize: AppTheme.fontSizeRegular,
          ),
        ),
      ),
    );
  }

  bool _validateInputs(String name) {
    if (name.isEmpty) {
      _showError('Product name is required');
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

  void _updatePaginatedProducts() {
    setState(() {
      _paginatedProducts =
          _filteredProducts.skip(_startIndex).take(_rowsPerPage).toList();
    });
  }

  // Update the build method to use pagination
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Management',
            style: TextStyle(fontSize: AppTheme.fontSizeMedium)),
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
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle:
                            TextStyle(fontSize: AppTheme.fontSizeRegular),
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
              margin: EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 10,
                      columns: [
                        DataColumn2(label: Text('ID'), size: ColumnSize.S),
                        DataColumn2(label: Text('Name'), size: ColumnSize.S),
                        DataColumn2(
                            label: Text('Category'), size: ColumnSize.S),
                        DataColumn2(label: Text('Stock'), size: ColumnSize.S),
                        DataColumn2(
                            label: Text('Available'), size: ColumnSize.S),
                        DataColumn2(label: Text('Rented'), size: ColumnSize.S),
                        DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                      ],
                      rows: _paginatedProducts.map((product) {
                        return DataRow2(
                          cells: [
                            DataCell(Text(
                              '#${product.id}',
                              style:
                                  TextStyle(fontSize: AppTheme.fontSizeSmall),
                            )),
                            DataCell(Text(
                              product.name,
                              style:
                                  TextStyle(fontSize: AppTheme.fontSizeSmall),
                            )),
                            DataCell(Text(
                              product.category,
                              style:
                                  TextStyle(fontSize: AppTheme.fontSizeSmall),
                            )),
                            DataCell(Text(
                              '${product.stock}',
                              style:
                                  TextStyle(fontSize: AppTheme.fontSizeSmall),
                            )),
                            DataCell(Text(
                              '${product.stock - (product.rented ?? 0)}',
                              style:
                                  TextStyle(fontSize: AppTheme.fontSizeSmall),
                            )),
                            DataCell(Text(
                              '${product.rented ?? 0}',
                              style:
                                  TextStyle(fontSize: AppTheme.fontSizeSmall),
                            )),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  onPressed: () =>
                                      _showProductDialog(product: product),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 16,
                                  ),
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
                  // Pagination controls
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${_startIndex + 1} to ${_endIndex} of ${_filteredProducts.length}',
                          style: TextStyle(fontSize: AppTheme.fontSizeSmall),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0
                                  ? () {
                                      setState(() {
                                        _currentPage--;
                                        _updatePaginatedProducts();
                                      });
                                    }
                                  : null,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'Page ${_currentPage + 1}',
                                style:
                                    TextStyle(fontSize: AppTheme.fontSizeSmall),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed: (_startIndex + _rowsPerPage) <
                                      _filteredProducts.length
                                  ? () {
                                      setState(() {
                                        _currentPage++;
                                        _updatePaginatedProducts();
                                      });
                                    }
                                  : null,
                            ),
                            SizedBox(width: 24),
                            DropdownButton<int>(
                              value: _rowsPerPage,
                              items: [10, 20, 50, 100].map((rows) {
                                return DropdownMenuItem<int>(
                                  value: rows,
                                  child: Text('$rows per page'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _rowsPerPage = value;
                                    _currentPage = 0;
                                    _updatePaginatedProducts();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update search functionality
  void _onSearchChanged() {
    setState(() {
      _currentPage = 0;
      _updatePaginatedProducts();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
