import 'package:flutter/material.dart';
import 'package:stock_rental/customer/customer_dashboard.dart';
import 'package:stock_rental/order/order_dashboard.dart';
import 'package:stock_rental/product/product.dart';
import 'package:stock_rental/repo/customer_db_helper.dart';
import 'package:stock_rental/repo/order_db_helper.dart';
import 'package:stock_rental/repo/product_db_helper.dart';
import 'package:stock_rental/repo/payment_db_helper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stock_rental/payment/payment_dashboard.dart';
import 'package:stock_rental/order/create_order_screen.dart';
import 'package:stock_rental/model/product.dart';
import 'package:stock_rental/model/customer.dart';
import 'package:stock_rental/model/order.dart';
import 'package:stock_rental/model/payment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CustomerDatabase().init();
  await OrderDatabase().init();
  await PaymentDatabase().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Product> _products = [];
  List<Customer> _customers = [];
  List<Order> _orders = [];
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productDb = ProductDatabase();
    final customerDb = CustomerDatabase();
    final orderDb = OrderDatabase();

    final products = await productDb.getProducts();
    final customers = await customerDb.getAllCustomers();
    final orders = await orderDb.getAllOrders();
    final payments = await PaymentDatabase().getAllPayments();

    setState(() {
      _products = products;
      _customers = customers;
      _orders = orders;
      _payments = payments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.business, color: Colors.blue),
            SizedBox(width: 8),
            Text('Sri Sai Enterprises'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            tooltip: 'New Order',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateOrderScreen(
                  customers: _customers,
                  availableProducts: _products,
                  onCreate: (order) {
                    _loadData();
                    Navigator.pop(context);
                  },
                  productDatabase: ProductDatabase(),
                ),
              ),
            ),
          ),
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(
              icon: Icon(Icons.person_outlined),
              onPressed: () {}), // PopupMenuButton(
          //   child: Padding(
          //     padding: EdgeInsets.symmetric(horizontal: 16),
          //     child: Row(
          //       children: [
          //         Text('Hachib'),
          //         Icon(Icons.arrow_drop_down),
          //       ],
          //     ),
          //   ),
          //   itemBuilder: (context) => [],
          // ),
          // IconButton(icon: Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Sri Sai Enterprises'),
                    ],
                  ),
                ],
              ),
            ),
            _buildDrawerItem(Icons.people, 'Profile', true),
            // _buildDrawerItem(Icons.dashboard, 'Dashboard', true),
            // _buildDrawerItem(Icons.inventory_2, 'Inventory', false),
            // _buildDrawerItem(Icons.shopping_cart, 'Purchase', false),
            // _buildDrawerItem(
            //     Icons.assignment_return, 'Suppliers Return', false),
            // _buildDrawerItem(Icons.receipt, 'Invoice', false),
            // _buildDrawerItem(Icons.point_of_sale, 'Sales', false),
            // _buildDrawerItem(Icons.receipt_long, 'Bill', false),
            // _buildDrawerItem(Icons.people, 'Customers', false),
            // _buildDrawerItem(Icons.business, 'Suppliers', false),
            // _buildDrawerItem(Icons.payment, 'Payments', false),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dashboard',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildNavigationCard(
                    'New Order',
                    'Create new rental order',
                    Icons.add_shopping_cart,
                    Colors.purple,
                    'Create Order',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateOrderScreen(
                          customers: _customers,
                          availableProducts: _products,
                          onCreate: (order) {
                            _loadData();
                            Navigator.pop(context);
                          },
                          productDatabase: ProductDatabase(),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildNavigationCard(
                    'Payments',
                    'View payment history',
                    Icons.payment,
                    Colors.blue,
                    '${_payments.length} payments',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PaymentDashboard()),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildNavigationCard(
                    'Products',
                    'Manage your inventory',
                    Icons.inventory_2,
                    Colors.blue,
                    '${_products.length} items',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductScreen()),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildNavigationCard(
                    'Customers',
                    'View customer details',
                    Icons.people,
                    Colors.green,
                    '${_customers.length} customers',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CustomerDashboard()),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildNavigationCard(
                    'Orders',
                    'Manage rental orders',
                    Icons.shopping_cart,
                    Colors.orange,
                    '${_orders.length} orders',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OrdersDashboard()),
                    ),
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
            SizedBox(height: 24),
            // Row(
            //   children: [
            //     Expanded(
            //       child: _buildOverviewCard(
            //         'Sales Overview',
            //         [
            //           _buildMetric('Total Sales', '786', Icons.shopping_cart,
            //               Colors.blue[100]!),
            //           _buildMetric('Revenue', '17584', Icons.attach_money,
            //               Colors.orange[100]!),
            //           _buildMetric('Cost', '12487', Icons.trending_down,
            //               Colors.red[100]!),
            //           _buildMetric('Profit', '5097', Icons.trending_up,
            //               Colors.green[100]!),
            //         ],
            //       ),
            //     ),
            //     SizedBox(width: 16),
            //     Expanded(
            //       child: _buildOverviewCard(
            //         'Purchase Overview',
            //         [
            //           _buildMetric('No of Purchase', '45', Icons.shopping_bag,
            //               Colors.purple[100]!),
            //           _buildMetric(
            //               'Cancel Order', '04', Icons.cancel, Colors.red[100]!),
            //           _buildMetric('Cost', '786', Icons.trending_down,
            //               Colors.orange[100]!),
            //           _buildMetric('Returns', '07', Icons.assignment_return,
            //               Colors.blue[100]!),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            SizedBox(height: 24),
            // Row(
            //   children: [
            //     Expanded(
            //       child: _buildSummaryCard(
            //         'Inventory Summary',
            //         [
            //           _buildSummaryItem('Quantity in Hand', '214',
            //               Icons.inventory_2, Colors.green),
            //           _buildSummaryItem('Will be Received', '44',
            //               Icons.local_shipping, Colors.orange),
            //         ],
            //       ),
            //     ),
            //     SizedBox(width: 16),
            //     Expanded(
            //       child: _buildDetailsCard(
            //         'Product Details',
            //         [
            //           _buildDetailRow('Low Stock Items', '02'),
            //           _buildDetailRow('Item Group', '14'),
            //           _buildDetailRow('No of Items', '104'),
            //         ],
            //       ),
            //     ),
            //     SizedBox(width: 16),
            //     Expanded(
            //       child: _buildSummaryCard(
            //         'No. of Users',
            //         [
            //           _buildSummaryItem(
            //               'Total Customers', '1.8k', Icons.people, Colors.blue),
            //           _buildSummaryItem('Total Suppliers', '27', Icons.business,
            //               Colors.purple),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            SizedBox(height: 24),
            SizedBox(height: 24),
            _buildChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.green : Colors.grey),
      title: Text(title,
          style:
              TextStyle(color: isSelected ? Colors.green : Colors.grey[600])),
      selected: isSelected,
      onTap: () {},
    );
  }

  Widget _buildOverviewCard(String title, List<Widget> metrics) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.more_vert),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children:
                  metrics.map((metric) => Expanded(child: metric)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
      String title, String value, IconData icon, Color backgroundColor) {
    return Card(
      elevation: 0,
      color: backgroundColor.withOpacity(0.2),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20),
                ),
                SizedBox(width: 8),
                Text(title,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            SizedBox(height: 12),
            Text(value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, List<Widget> items) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.more_vert),
              ],
            ),
            SizedBox(height: 16),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String title, List<Widget> rows) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.more_vert),
              ],
            ),
            SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // TODO: Implement chart
    return Container(height: 300);
  }

  Widget _buildNavigationCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String count,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
