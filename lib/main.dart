import 'package:flutter/material.dart';
import 'package:stock_rental/customer/customer_dashboard.dart';
import 'package:stock_rental/product/product.dart';
import 'package:stock_rental/repo/customer_db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CustomerDatabase().init();
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

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Hi, Taylor Kareem!",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              // const CircleAvatar(
              //   backgroundImage: AssetImage(
              //       'assets/profile_image.png'), // Replace with your asset
              //   radius: 18,
              // ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Dakota',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Customer Dashboard'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomerDashboard(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Product'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Order'),
              trailing: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '5',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.pages),
              title: const Text('Special Pages'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Documentation'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sales Analytics Section
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Sales Analytics",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        // Placeholder for chart or analytics content
                        Text("Graph Placeholder"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      // Visitor Section
                      _buildInfoCard("Visitor", "6,354"),
                      const SizedBox(height: 16),
                      // Product Section
                      _buildInfoCard("Product", "\$5363"),
                      const SizedBox(height: 16),
                      // Bounce Rate Section
                      _buildInfoCard("Bounce Rate", "200%"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Last Invoice Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Last Invoice",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text("Invoice Table Placeholder"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
