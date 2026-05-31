import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; 
import 'home_screen.dart'; 

class ServiceDetailsPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;
  final Map<String, dynamic> addressData;

  const ServiceDetailsPaymentScreen({super.key, required this.serviceData, required this.addressData});

  @override
  State<ServiceDetailsPaymentScreen> createState() => _ServiceDetailsPaymentScreenState();
}

class _ServiceDetailsPaymentScreenState extends State<ServiceDetailsPaymentScreen> {
  // Store selections
  final Map<String, String?> _selections = {};
  bool _isProcessingPayment = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Initialize dropdown selections
    final configs = _getDropdownConfigs();
    for (var config in configs) {
      _selections[config['label']] = null;
    }
  }

  // --- 1. DYNAMIC DROPDOWN CONFIGURATION ---
  List<Map<String, dynamic>> _getDropdownConfigs() {
    String category = (widget.serviceData['category'] ?? 'Services').toString();
    
    if (category.contains('Food')) {
      return [
        {'label': 'Spiciness Level', 'items': ['Not Spicy', 'Mild', 'Spicy', 'Extra Spicy']},
        {'label': 'Cutlery Needed?', 'items': ['Yes, please', 'No, going green']},
        {'label': 'Drink Add-on', 'items': ['None', 'Iced Milo (+RM3)', 'Teh O Ais (+RM2)', 'Syrup Bandung (+RM2)']},
      ];
    } else if (category.contains('Handcraft')) {
      return [
        {'label': 'Gift Wrapping?', 'items': ['No', 'Yes (+RM5)', 'Yes + Card (+RM7)']},
        {'label': 'Color Preference', 'items': ['Pastel', 'Bright/Bold', 'Black & White', 'Artist Choice']},
        {'label': 'Customization', 'items': ['None', 'Add Name', 'Add Date', 'Custom Message']},
      ];
    } else if (category.contains('Clothing')) {
       return [
        {'label': 'Size', 'items': ['XS', 'S', 'M', 'L', 'XL', 'XXL']},
        {'label': 'Material Preference', 'items': ['Cotton', 'Polyester', 'Silk/Satin', 'No Preference']},
        {'label': 'Fit Type', 'items': ['Slim Fit', 'Regular Fit', 'Oversized']},
      ];
    } else {
      return [
        {'label': 'Urgency', 'items': ['Standard', 'Urgent (Today)']},
        {'label': 'Special Request', 'items': ['None', 'Call before delivery', 'Leave at guardhouse']},
      ];
    }
  }

  // --- 2. DYNAMIC PRICE CALCULATION ---
  double get _totalPrice {
    // Extract base price safely
    String priceStr = widget.serviceData['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '0';
    double basePrice = double.tryParse(priceStr) ?? 0.0;
    
    double extras = 0.0;

    // Add extra costs logic
    if (_selections['Drink Add-on']?.contains('+RM3') ?? false) extras += 3.0;
    if (_selections['Drink Add-on']?.contains('+RM2') ?? false) extras += 2.0;
    if (_selections['Gift Wrapping?']?.contains('+RM5') ?? false) extras += 5.0;
    if (_selections['Gift Wrapping?']?.contains('+RM7') ?? false) extras += 7.0;

    return (basePrice + extras) * _quantity;
  }

  // --- 3. STRIPE PAYMENT LOGIC ---
  Future<void> _makeStripePayment() async {
    // Validation
    if (_selections.containsValue(null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select all options.")));
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      String amountInCents = (_totalPrice * 100).toInt().toString();
      final paymentIntentData = await createPaymentIntent(amountInCents, 'myr');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'Skelva Student Market',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      await _saveOrderToFirestore();

    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Cancelled")));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Stripe Error: ${e.error.localizedMessage}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
    try {
      // 1. Declare your Stripe key outside of the request parameters
      const stripeKey = "STRIPE_KEY_HERE"; 

      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
        'payment_method_types[]': 'card', 
      };

      var response = await http.post(
        Uri.parse("YOUR_STRIPE_PAYMENT_INTENT_URL"), // REPLACE WITH YOUR BACKEND ENDPOINT
        body: body,
        // 2. Now pass a properly formatted Map to the headers
        headers: {
          'Authorization': 'Bearer $stripeKey',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
      );
      return jsonDecode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  // --- 4. SAVE ORDER TO FIREBASE ---
  Future<void> _saveOrderToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    String orderId = "ORD-${Random().nextInt(999999)}";
    
    // Prepare item data format to match Checkout flow
    List<Map<String, dynamic>> items = [{
      'name': widget.serviceData['name'],
      'image': widget.serviceData['image'],
      'price': double.tryParse(widget.serviceData['price'].toString()) ?? 0.0,
      'quantity': _quantity,
      'details': _selections
    }];

    await FirebaseFirestore.instance.collection('orders').doc(orderId).set({
      'orderId': orderId,
      'buyerId': user!.uid,
      'buyerName': user.displayName ?? "Student Buyer",
      // Ensure we pass the correct seller ID from the product
      'sellerId': widget.serviceData['sellerId'] ?? 'unknown_seller',
      'sellerName': widget.serviceData['sellerName'] ?? "Seller",
      'items': items,
      'totalAmount': _totalPrice, // Matches Stripe amount
      'totalPrice': _totalPrice,  // For consistency with checkout
      'status': 'To Ship', // Triggers Seller Notification
      'details': _selections,
      'address': widget.addressData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Payment Successful!", style: TextStyle(color: Color(0xFF335D61), fontWeight: FontWeight.bold)),
          content: const Text("Your order has been placed. Track it in 'My Orders'."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()), 
                  (route) => false
                );
              },
              child: const Text("OK", style: TextStyle(color: Color(0xFF335D61), fontWeight: FontWeight.bold)),
            )
          ],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(widget.serviceData['name'] ?? "Details", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: _isProcessingPayment 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF963B))) 
        : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PRODUCT CARD ---
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F5FD), 
                      borderRadius: BorderRadius.circular(15)
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(widget.serviceData['image'] ?? 'https://placehold.co/60'),
                              fit: BoxFit.cover
                            )
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.serviceData['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                widget.serviceData['category'] ?? 'Item', 
                                style: const TextStyle(fontSize: 12, color: Colors.grey)
                              ),
                            ],
                          ),
                        ),
                        Text("RM ${widget.serviceData['price']}", 
                          style: const TextStyle(color: Color(0xFF335D61), fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- QUANTITY SELECTOR ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18), 
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              }
                            ),
                            Text("$_quantity", style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18), 
                              onPressed: () {
                                setState(() => _quantity++);
                              }
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // --- DYNAMIC DROPDOWNS ---
                  ..._getDropdownConfigs().map((config) {
                    return _buildDropdown(
                      config['label'],
                      config['items'],
                      _selections[config['label']],
                      (val) => setState(() => _selections[config['label']] = val)
                    );
                  }).toList(),

                ],
              ),
            ),
          ),

          // --- BOTTOM PAYMENT BAR ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-5))]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Total to pay", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      "RM ${_totalPrice.toStringAsFixed(2)}", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF335D61))
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _makeStripePayment, // <--- Calls Stripe
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF963B), 
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                  ),
                  child: const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String title, List<String> items, String? currentValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Select option", style: TextStyle(fontSize: 13, color: Colors.grey)),
              value: currentValue,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}