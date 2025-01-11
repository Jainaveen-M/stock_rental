import 'package:flutter/material.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/repo/product_db_helper.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _db = ProductDatabase();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = "";
  String _sortBy = "Name";
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final productMaps = await _db.getProducts();
    setState(() {
      _products = productMaps.map((map) => Product.fromMap(map)).toList();
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      // Filter products based on search query.
      _filteredProducts = _products
          .where((product) =>
              product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.category
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              product.price.toString().contains(_searchQuery))
          .toList();

      // Sort the filtered products.
      _filteredProducts.sort((a, b) {
        int comparison;
        switch (_sortBy) {
          case "Name":
            comparison = a.name.compareTo(b.name);
            break;
          case "Category":
            comparison = a.category.compareTo(b.category);
            break;
          case "Price":
            comparison = a.price.compareTo(b.price);
            break;
          default:
            comparison = 0;
        }
        return _isAscending ? comparison : -comparison;
      });
    });
  }

  void _showProductDialog({Product? product}) {
    final _nameController = TextEditingController(text: product?.name ?? "");
    final _categoryController =
        TextEditingController(text: product?.category ?? "");
    final _priceController = TextEditingController(
        text: product != null ? product.price.toString() : "");
    final _stockController =
        TextEditingController(text: product?.stock.toString() ?? "0");
    final _descriptionController =
        TextEditingController(text: product?.description ?? "");

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product == null ? 'Add Product' : 'Edit Product',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price per Day',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Total Stock',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final name = _nameController.text;
                        final category = _categoryController.text;
                        final price =
                            double.tryParse(_priceController.text) ?? 0.0;
                        final stock = int.tryParse(_stockController.text) ?? 0;
                        final description = _descriptionController.text;

                        if (name.isNotEmpty &&
                            category.isNotEmpty &&
                            price > 0) {
                          if (product == null) {
                            final newProduct = Product(
                              id: DateTime.now().millisecondsSinceEpoch,
                              name: name,
                              category: category,
                              price: price,
                              stock: stock,
                              description: description,
                              rented: 0, // Initially no items are rented
                            );
                            await _db.addProduct(newProduct.toMap());
                          } else {
                            final updatedProduct = product.copyWith(
                              name: name,
                              category: category,
                              price: price,
                              stock: stock,
                              description: description,
                            );
                            await _db.updateProduct(
                                updatedProduct.dbKey!, updatedProduct.toMap());
                          }
                          Navigator.pop(context);
                          _loadProducts();
                        }
                      },
                      child: Text(product == null ? 'Add' : 'Update'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Products',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                DropdownButton<String>(
                  value: _sortBy,
                  items: ["Name", "Category", "Stock", "Price"].map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Price/Day')),
                  DataColumn(label: Text('Total Stock')),
                  DataColumn(label: Text('Available')),
                  DataColumn(label: Text('Rented')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _filteredProducts.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(Text(product.name)),
                      DataCell(Text(product.category)),
                      DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
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
                            icon: Icon(Icons.info_outline),
                            onPressed: () => _showProductDetails(product),
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

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Category: ${product.category}'),
            Text('Price per Day: \$${product.price.toStringAsFixed(2)}'),
            Text('Total Stock: ${product.stock}'),
            Text('Available: ${product.stock - (product.rented ?? 0)}'),
            Text('Currently Rented: ${product.rented ?? 0}'),
            SizedBox(height: 8),
            Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(product.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
