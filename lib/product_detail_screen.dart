import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service_details_payment_screen.dart'; 
import 'chat_screen.dart'; 
import 'cart_screen.dart'; 
import 'shop_profile_screen.dart'; // <--- NEW IMPORT

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;

  const ProductDetailScreen({super.key, required this.serviceData});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isAddingToCart = false;

  // --- Add to Cart Function ---
  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    setState(() => _isAddingToCart = true);

    try {
      final cartRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart');

      final existingItems = await cartRef
          .where('name', isEqualTo: widget.serviceData['name'])
          .limit(1)
          .get();

      if (existingItems.docs.isNotEmpty) {
        var docId = existingItems.docs.first.id;
        int currentQty = existingItems.docs.first['qty'];
        await cartRef.doc(docId).update({'qty': currentQty + 1});
      } else {
        await cartRef.add({
          'name': widget.serviceData['name'],
          'price': widget.serviceData['price'], 
          'image': widget.serviceData['image'],
          'shopName': widget.serviceData['sellerName'] ?? 'Student Shop',
          'qty': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Cart Successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper variables
    String sellerId = widget.serviceData['sellerId'] ?? 'dummy_seller';
    String sellerName = widget.serviceData['sellerName'] ?? 'Student Seller';
    
    // Clean Price
    String priceDisplay = widget.serviceData['price'].toString().replaceAll("RM", "").trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. PRODUCT IMAGE
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                backgroundColor: Colors.white,
                leading: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    widget.serviceData['image'] ?? 'https://placehold.co/400',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. INFO SECTION
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "RM $priceDisplay",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFEF963B)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.serviceData['name'] ?? "Unknown Product",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(" ${widget.serviceData['rating']} "),
                          const SizedBox(width: 5),
                          Text("|  ${widget.serviceData['completedJobs']} Sold", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. SHOP INFO
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF335D61),
                        child: Text(sellerName[0], style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text("Verified Student", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      
                      // --- UPDATED VIEW SHOP BUTTON ---
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShopProfileScreen(
                                sellerId: sellerId,
                                sellerName: sellerName,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF335D61))),
                        child: const Text("View Shop", style: TextStyle(color: Color(0xFF335D61))),
                      )
                      // --------------------------------
                    ],
                  ),
                ),
              ),

              // 4. DESCRIPTION
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Product Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Text(
                        "Category: ${widget.serviceData['category']}\nLocation: ${widget.serviceData['location']}\n\nSupport local student entrepreneurship! This product is prepared with care by UTHM students.",
                        style: const TextStyle(height: 1.5, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // BOTTOM BAR
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0,-2))]
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(sellerId: sellerId, sellerName: sellerName))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.chat_bubble_outline, color: Color(0xFF335D61)),
                          Text("Chat", style: TextStyle(fontSize: 10, color: Color(0xFF335D61)))
                        ],
                      ),
                    ),
                  ),
                  
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: _isAddingToCart 
                        ? null 
                        : () async {
                            await _addToCart(); 
                          },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _isAddingToCart 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_shopping_cart, color: Color(0xFF335D61)),
                          Text(_isAddingToCart ? "Adding..." : "Add to Cart", style: const TextStyle(fontSize: 10, color: Color(0xFF335D61)))
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceDetailsPaymentScreen(
                          serviceData: widget.serviceData,
                          addressData: const {},
                        )));
                      },
                      child: Container(
                        color: const Color(0xFFEF963B),
                        alignment: Alignment.center,
                        child: const Text("Buy Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}