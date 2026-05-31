import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Store "Selected" status locally using Doc IDs
  final Map<String, bool> _selectedItems = {}; 
  bool isAllSelected = false;

  User? get user => FirebaseAuth.instance.currentUser;

  // --- HELPERS ---
  
  // Calculate total price of selected items
  double _calculateSubtotal(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var doc in docs) {
      if (_selectedItems[doc.id] == true) {
        var data = doc.data() as Map<String, dynamic>;
        double price = _parsePrice(data['price']);
        int qty = data['qty'] ?? 1;
        total += (price * qty);
      }
    }
    return total;
  }

  // Handle "RM 5.00" string to double conversion
  double _parsePrice(dynamic price) {
    if (price is num) return price.toDouble();
    String pStr = price.toString().replaceAll("RM", "").trim();
    return double.tryParse(pStr) ?? 0.0;
  }

  // Update Firestore Quantity
  void _updateQuantity(String docId, int currentQty, int change) {
    int newQty = currentQty + change;
    if (newQty < 1) return; // Minimum 1
    
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(docId)
        .update({'qty': newQty});
  }

  // Delete Item
  void _deleteItem(String docId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Shopping Cart", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- 1. STREAM LIVE DATA FROM FIREBASE ---
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('cart')
            .orderBy('addedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Your cart is empty", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;
          double subtotal = _calculateSubtotal(docs);
          int selectedCount = docs.where((d) => _selectedItems[d.id] == true).length;

          return Column(
            children: [
              // Free Shipping Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                color: const Color(0xFFE0F2F1),
                child: Row(
                  children: const [
                    Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF335D61)),
                    SizedBox(width: 8),
                    Text("Free shipping for orders over RM15.00", style: TextStyle(fontSize: 12, color: Color(0xFF335D61))),
                  ],
                ),
              ),

              // Cart Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String docId = doc.id;
                    bool isSelected = _selectedItems[docId] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          // Shop Name Header
                          Row(
                            children: [
                              Icon(Icons.store, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 5),
                              Text(data['shopName'] ?? "Shop", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _deleteItem(docId),
                                child: const Text("Delete", style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            children: [
                              // Checkbox
                              Checkbox(
                                activeColor: const Color(0xFF335D61),
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedItems[docId] = val ?? false;
                                    // Update Select All state logic if needed
                                  });
                                },
                              ),
                              // Image
                              Container(
                                width: 70, height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(5),
                                  image: DecorationImage(
                                    image: NetworkImage(data['image'] ?? 'https://placehold.co/70'), 
                                    fit: BoxFit.cover
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 5),
                                    Text("RM ${_parsePrice(data['price']).toStringAsFixed(2)}", 
                                      style: const TextStyle(color: Color(0xFFEF963B), fontWeight: FontWeight.bold)),
                                    
                                    // Qty Control
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _qtyButton("-", () => _updateQuantity(docId, data['qty'], -1)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text("${data['qty']}"),
                                        ),
                                        _qtyButton("+", () => _updateQuantity(docId, data['qty'], 1)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Checkout Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: Row(
                  children: [
                    Checkbox(
                      activeColor: const Color(0xFF335D61),
                      value: isAllSelected,
                      onChanged: (val) {
                        setState(() {
                          isAllSelected = val ?? false;
                          for (var doc in docs) {
                            _selectedItems[doc.id] = isAllSelected;
                          }
                        });
                      },
                    ),
                    const Text("All", style: TextStyle(color: Colors.grey)),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Total", style: TextStyle(fontSize: 12)),
                        Text("RM ${subtotal.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFEF963B), fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton(
                      onPressed: subtotal > 0 
                        ? () {
                            // Prepare items for Checkout
                            List<Map<String, dynamic>> checkoutList = [];
                            for(var doc in docs) {
                              if (_selectedItems[doc.id] == true) {
                                var d = doc.data() as Map<String, dynamic>;
                                checkoutList.add({
                                  'name': d['name'],
                                  'price': _parsePrice(d['price']),
                                  'image': d['image'],
                                  'qty': d['qty'],
                                  'shopName': d['shopName']
                                });
                              }
                            }
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(checkoutItems: checkoutList)));
                          }
                        : null,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF963B)),
                      child: Text("Check Out ($selectedCount)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _qtyButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 25, height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
        child: Text(text),
      ),
    );
  }
}