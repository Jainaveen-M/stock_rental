import 'package:flutter/material.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/repo/product_db_helper.dart';
import 'package:uuid/uuid.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _db = ProductDatabase();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = "";
  String _sortBy = "Name"; // Default sort option.
  bool _isAscending = true; // Sorting order.

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

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product == null ? 'Add Product' : 'Edit Product',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final name = _nameController.text;
                        final category = _categoryController.text;
                        final price =
                            double.tryParse(_priceController.text) ?? 0.0;

                        if (name.isNotEmpty &&
                            category.isNotEmpty &&
                            price > 0) {
                          if (product == null) {
                            // Add new product.
                            final newProduct = Product(
                              id: const Uuid().v4(),
                              name: name,
                              category: category,
                              price: price,
                            );
                            await _db.addProduct(newProduct.toMap());
                          } else {
                            // Update existing product.
                            final updatedProduct = product.copyWith(
                              name: name,
                              category: category,
                              price: price,
                            );

                            if (updatedProduct.dbKey != null) {
                              await _db.updateProduct(updatedProduct.dbKey!,
                                  updatedProduct.toMap());
                            }
                          }

                          Navigator.of(context).pop();
                          _loadProducts();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill all fields correctly'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(product == null ? 'Add' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar.
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
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

          // Sort dropdown.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text("Sort by: "),
                DropdownButton<String>(
                  value: _sortBy,
                  items: ["Name", "Category", "Price"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _applyFilters();
                    });
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                      _isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _isAscending = !_isAscending;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),

          // Product data table.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _filteredProducts.map((product) {
                  return DataRow(cells: [
                    DataCell(Text(product.name)),
                    DataCell(Text(product.category)),
                    DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showProductDialog(product: product),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
