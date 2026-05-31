import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'confirm_address_screen.dart'; 
import 'service_details_payment_screen.dart'; 

class SelectAddressScreen extends StatefulWidget {
  // Nullable serviceData allows this screen to be used for both "Checkout Selection" and "Buy Now" flows
  final Map<String, dynamic>? serviceData; 

  const SelectAddressScreen({super.key, this.serviceData});

  @override
  State<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  String? _selectedAddressId;
  Map<String, dynamic>? _selectedAddressData;

  // --- NEW: DELETE ADDRESS FUNCTION ---
  Future<void> _deleteAddress(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Show Confirmation Dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to remove this address?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(docId)
          .delete();
      
      // If we deleted the currently selected address, clear selection
      if (_selectedAddressId == docId) {
        setState(() {
          _selectedAddressId = null;
          _selectedAddressData = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address removed")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isSelectionMode = widget.serviceData == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Select Address", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConfirmAddressScreen()),
              );
            },
            icon: const Icon(Icons.add_location_alt, color: Color(0xFF335D61)),
            label: const Text("Add New", style: TextStyle(color: Color(0xFF335D61))),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('addresses')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Error loading addresses"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text("No addresses found.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    final isSelected = _selectedAddressId == id;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAddressId = id;
                          _selectedAddressData = data;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF335D61) : const Color(0xFFE5E5E5),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: isSelected ? const Color(0xFF335D61) : Colors.grey),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(data['receiverName'] ?? data['building'] ?? 'My Address', 
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      if (data['isDefault'] == true)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                                          child: const Text("Default", style: TextStyle(fontSize: 10, color: Colors.red)),
                                        )
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(data['phone'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(data['fullAddress'] ?? '', 
                                    style: const TextStyle(color: Colors.grey, fontSize: 13), 
                                    maxLines: 2, overflow: TextOverflow.ellipsis
                                  ),
                                ],
                              ),
                            ),
                            
                            // Check Icon if Selected OR Delete Icon if Not Selected
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF335D61))
                            else
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => _deleteAddress(id),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Bottom Confirmation Button
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,-5))]
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedAddressId == null ? null : () {
                  if (isSelectionMode) {
                    // MODE A: Return data to Checkout Screen
                    Navigator.pop(context, _selectedAddressData);
                  } else {
                    // MODE B: Continue to Payment (Buy Now flow)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailsPaymentScreen(
                          serviceData: widget.serviceData!,
                          addressData: _selectedAddressData!,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF335D61),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  isSelectionMode ? "Confirm Address" : "Continue to Payment", 
                  style: const TextStyle(color: Colors.white, fontSize: 16)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}