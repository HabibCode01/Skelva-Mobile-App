import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'chat_screen.dart'; // Ensure you have ChatScreen

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Orders", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF335D61),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF335D61),
            tabs: [
              Tab(text: "All"),
              Tab(text: "To Pay"),
              Tab(text: "To Ship"),
              Tab(text: "To Receive"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('buyerId', isEqualTo: currentUserId)
              //.orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState("No orders found");

            final allOrders = snapshot.data!.docs;

            return TabBarView(
              children: [
                _buildOrderList(allOrders, "All"),
                _buildOrderList(allOrders, "To Pay"),
                _buildOrderList(allOrders, "To Ship"),
                _buildOrderList(allOrders, "To Receive"),
                _buildOrderList(allOrders, "Completed"),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<QueryDocumentSnapshot> allOrders, String status) {
    final filteredOrders = status == "All"
        ? allOrders
        : allOrders.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == status).toList();

    if (filteredOrders.isEmpty) return _buildEmptyState("No orders in '$status'");

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final orderDoc = filteredOrders[index];
        final order = orderDoc.data() as Map<String, dynamic>;
        final List<dynamic> items = order['items'] ?? [];
        final firstItem = items.isNotEmpty ? items[0] : {};
        final int itemCount = items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, size: 18),
                        const SizedBox(width: 5),
                        Text(order['sellerName'] ?? 'Seller', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(order['status'] ?? 'Unknown', style: TextStyle(color: _getStatusColor(order['status']), fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.grey[200]),
                      child: Image.network(firstItem['image'] ?? 'https://placehold.co/60', fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(firstItem['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${itemCount} items • Total: RM ${order['totalPrice']?.toStringAsFixed(2)}"),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                
                // DYNAMIC BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (order['status'] == 'To Receive') {
                        _confirmOrderReceived(orderDoc.id);
                      } else if (order['status'] == 'To Ship') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(sellerId: order['sellerId'], sellerName: order['sellerName'])));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _getStatusColor(order['status'])),
                    child: Text(_getButtonText(order['status']), style: const TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]), const SizedBox(height: 10), Text(message, style: TextStyle(color: Colors.grey[600]))]));
  }

  String _getButtonText(String? status) {
    switch (status) {
      case 'To Pay': return 'Pay Now';
      case 'To Ship': return 'Contact Seller';
      case 'To Receive': return 'Order Received';
      case 'Completed': return 'Buy Again';
      default: return 'View Details';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'To Pay': return Colors.orange;
      case 'To Ship': return Colors.blueGrey;
      case 'To Receive': return const Color(0xFF335D61);
      case 'Completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _confirmOrderReceived(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'Completed'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Completed!")));
  }
}