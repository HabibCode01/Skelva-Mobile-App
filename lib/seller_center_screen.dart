import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product_screen.dart'; 

class SellerCenterScreen extends StatefulWidget {
  const SellerCenterScreen({super.key});

  @override
  State<SellerCenterScreen> createState() => _SellerCenterScreenState();
}

class _SellerCenterScreenState extends State<SellerCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Seller Center", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF335D61),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF335D61),
          tabs: const [
            Tab(text: "My Products"),
            Tab(text: "Incoming Orders"), 
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductList(),
          _buildOrderManagement(), 
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
        backgroundColor: const Color(0xFFEF963B),
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
      ),
    );
  }

  // --- TAB 1: MANAGE PRODUCTS (View & Delete) ---
  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('sellerId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text("No products listed yet.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(data['image'] ?? 'https://placehold.co/50'),
                      fit: BoxFit.cover
                    )
                  ),
                ),
                title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("RM ${data['price']} • ${data['category']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit Button (Placeholder)
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                    // DELETE BUTTON
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(doc.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('services').doc(docId).delete();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product deleted")));
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          )
        ],
      )
    );
  }

  // --- TAB 2: MANAGE ORDERS (Confirm Ship) ---
  Widget _buildOrderManagement() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: currentUserId)
          //.orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No incoming orders.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var orderDoc = snapshot.data!.docs[index];
            var order = orderDoc.data() as Map<String, dynamic>;
            String status = order['status'] ?? 'Unknown';

            // Extract item info safely
            List<dynamic> items = order['items'] ?? [];
            var firstItem = items.isNotEmpty ? items[0] : {};

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Buyer: ${order['buyerName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(status, style: TextStyle(color: status == 'To Ship' ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Image.network(firstItem['image'] ?? 'https://placehold.co/50', width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(firstItem['name'] ?? 'Item'),
                      subtitle: Text("Qty: ${firstItem['quantity']} • Total: RM ${order['totalPrice']}"),
                    ),
                    
                    if (status == 'To Ship') 
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _confirmShipment(orderDoc.id),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF335D61)),
                          child: const Text("Confirm Shipment", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmShipment(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'To Receive'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order updated! Buyer notified.")));
  }
}