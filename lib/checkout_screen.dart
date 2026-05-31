import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'select_address_screen.dart'; 
import 'home_screen.dart'; 

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> checkoutItems;

  const CheckoutScreen({super.key, required this.checkoutItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Map<String, dynamic>? _selectedAddress; 
  String _shippingOption = "Standard Delivery";
  bool _freeShippingApplied = false;
  bool _isProcessing = false;

  // --- CALCULATIONS ---
  double get _itemTotal {
    double t = 0;
    for (var item in widget.checkoutItems) {
      double price = 0.0;
      if (item['price'] is String) {
        price = double.tryParse(item['price'].toString().replaceAll("RM", "").trim()) ?? 0.0;
      } else if (item['price'] is num) {
        price = item['price'].toDouble();
      }
      
      int qty = 1;
      if (item['qty'] is int) qty = item['qty'];
      else if (item['qty'] is String) qty = int.tryParse(item['qty']) ?? 1;

      t += (price * qty);
    }
    return t;
  }

  double get _shippingFee => _freeShippingApplied ? 0.00 : 5.00;
  double get _grandTotal => _itemTotal + _shippingFee;

  // --- ADDRESS SELECTION ---
  Future<void> _changeAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectAddressScreen(serviceData: null),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  void _openVoucherModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Voucher", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_shipping, color: Color(0xFF335D61)),
                title: const Text("Free Shipping Voucher"),
                subtitle: const Text("Min. spend RM15"),
                trailing: Checkbox(
                  value: _freeShippingApplied,
                  activeColor: const Color(0xFF335D61),
                  onChanged: (val) {
                    setState(() => _freeShippingApplied = val!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- STRIPE PAYMENT LOGIC ---
  Future<void> _makeStripePayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a delivery address"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      String amountInCents = (_grandTotal * 100).toInt().toString();
      final paymentIntentData = await createPaymentIntent(amountInCents, 'myr');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'Skelva Student Market',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      await _saveOrderToFirestore(); // SAVE ORDER AFTER SUCCESS

    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Cancelled")));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Stripe Error: ${e.error.localizedMessage}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card', 
      };

      var response = await http.post(
        Uri.parse("YOUR_STRIPE_PAYMENT_INTENT_URL"), // REPLACE WITH YOUR BACKEND ENDPOINT
        body: body,
        headers: {
          // REPLACE WITH YOUR SECRET KEY
          'Authorization': "Bearer YOUR_STRIPE_SECRET_KEY", 
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      );
      return jsonDecode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  // --- SAVE ORDER (GROUPED BY SELLER) ---
  Future<void> _saveOrderToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    
    // 1. Group items by Seller ID
    Map<String, List<Map<String, dynamic>>> itemsBySeller = {};
    
    for (var item in widget.checkoutItems) {
      String sellerId = item['sellerId'] ?? 'unknown_seller';
      if (!itemsBySeller.containsKey(sellerId)) {
        itemsBySeller[sellerId] = [];
      }
      itemsBySeller[sellerId]!.add(item);
    }

    // 2. Create an order for EACH seller
    WriteBatch batch = FirebaseFirestore.instance.batch();

    itemsBySeller.forEach((sellerId, items) {
      String orderId = "ORD-${DateTime.now().millisecondsSinceEpoch}-${sellerId.substring(0, 4)}";
      DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);

      double sellerTotal = 0.0;
      for (var i in items) {
         double p = double.tryParse(i['price'].toString().replaceAll("RM", "").trim()) ?? 0.0;
         int q = int.tryParse(i['qty'].toString()) ?? 1;
         sellerTotal += (p * q);
      }

      batch.set(orderRef, {
        'orderId': orderId,
        'buyerId': user!.uid,
        'buyerName': user.displayName ?? "Student Buyer",
        'sellerId': sellerId,
        'sellerName': items[0]['sellerName'] ?? 'Seller', // Take name from first item
        'items': items,
        'totalPrice': sellerTotal,
        'status': 'To Ship', // INITIAL STATUS
        'address': _selectedAddress,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Order Placed!", style: TextStyle(color: Color(0xFF335D61), fontWeight: FontWeight.bold)),
          content: const Text("Your order has been sent to the seller(s). Track it in 'My Orders'."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()), 
                  (route) => false
                );
              },
              child: const Text("OK"),
            )
          ],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF963B))) 
        : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ADDRESS
                  GestureDetector(
                    onTap: _changeAddress,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red, Colors.blue, Colors.red, Colors.blue],
                                stops: [0.0, 0.2, 0.2, 1.0],
                              )
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFF335D61)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _selectedAddress == null 
                                    ? const Text("Select Delivery Address", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("Delivery Address", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text("${_selectedAddress!['receiverName']} | ${_selectedAddress!['phone']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text("${_selectedAddress!['fullAddress']}", maxLines: 2, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ITEMS
                  ...widget.checkoutItems.map((item) {
                    double price = double.tryParse(item['price'].toString().replaceAll("RM", "").trim()) ?? 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      color: Colors.white,
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              image: DecorationImage(
                                image: NetworkImage(item['image'] ?? 'https://placehold.co/60'), 
                                fit: BoxFit.cover
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("RM ${price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("x${item['qty']}", style: const TextStyle(color: Colors.grey)),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),

                  // SUMMARY
                  const SizedBox(height: 10),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        _buildSummaryRow("Merchandise Subtotal", "RM ${_itemTotal.toStringAsFixed(2)}"),
                        _buildSummaryRow("Shipping Subtotal", "RM ${_shippingFee.toStringAsFixed(2)}"),
                        if (_freeShippingApplied) _buildSummaryRow("Shipping Voucher", "-RM 5.00", isDiscount: true),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Payment", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("RM ${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF963B))),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // BOTTOM BAR
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Total: RM ${_grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: _makeStripePayment, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF963B),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Place Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String val, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: TextStyle(color: isDiscount ? const Color(0xFF335D61) : Colors.black)),
        ],
      ),
    );
  }
}