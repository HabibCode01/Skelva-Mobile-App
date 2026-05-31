import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfirmAddressScreen extends StatefulWidget {
  const ConfirmAddressScreen({super.key});

  @override
  State<ConfirmAddressScreen> createState() => _ConfirmAddressScreenState();
}

class _ConfirmAddressScreenState extends State<ConfirmAddressScreen> {
  // UTHM Initial Location
  static const LatLng _initialPosition = LatLng(1.8596, 103.0853);
  LatLng _selectedLocation = _initialPosition;
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};

  // Form Controllers
  final TextEditingController _receiverNameController = TextEditingController(); // NEW
  final TextEditingController _phoneController = TextEditingController();        // NEW
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addMarker(_initialPosition);
    // Pre-fill user data if available
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null) {
      _receiverNameController.text = user!.displayName!;
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _addMarker(position);
    });
    mapController.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _addMarker(LatLng position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected-location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  // --- SAVE ADDRESS TO FIREBASE ---
  Future<void> _saveAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login first")));
      return;
    }

    if (_receiverNameController.text.isEmpty || _phoneController.text.isEmpty || _buildingController.text.isEmpty || _streetController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in required fields")));
       return;
    }

    setState(() => _isLoading = true);

    try {
      // Create full address string
      String fullAddress = "${_buildingController.text}, ${_streetController.text}";
      if (_unitController.text.isNotEmpty) fullAddress = "${_unitController.text}, $fullAddress";

      // Data object
      Map<String, dynamic> addressData = {
        'receiverName': _receiverNameController.text, // Save Name
        'phone': _phoneController.text,               // Save Phone
        'building': _buildingController.text,
        'floor': _floorController.text,
        'unit': _unitController.text,
        'street': _streetController.text,
        'fullAddress': fullAddress,
        'latitude': _selectedLocation.latitude,
        'longitude': _selectedLocation.longitude,
        'isDefault': _isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore under users/{uid}/addresses
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add(addressData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address saved successfully!")));
        Navigator.pop(context); // Return to selection screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // --------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add New Address", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
        children: [
          // --- MAP SECTION ---
          SizedBox(
            height: 200, // Slightly reduced height to fit new fields
            child: GoogleMap(
                  onMapCreated: (c) => mapController = c,
                  initialCameraPosition: const CameraPosition(target: _initialPosition, zoom: 15.0),
                  markers: _markers,
                  onTap: _onMapTapped,
                  myLocationButtonEnabled: false, zoomControlsEnabled: false,
                ),
          ),

          // --- FORM SECTION ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Contact Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildTextField("Receiver Name*", "e.g., Ahmad Habib", controller: _receiverNameController),
                  const SizedBox(height: 15),
                  _buildTextField("Phone Number*", "e.g., +60 12-345 6789", controller: _phoneController, inputType: TextInputType.phone),
                  
                  const SizedBox(height: 25),
                  const Text("Address Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Building/Block*", "e.g., Kolej Perwira", controller: _buildingController)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField("Floor", "e.g., Level 2", controller: _floorController)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTextField("Unit / Room No.", "e.g., A-2-10", controller: _unitController),
                  const SizedBox(height: 15),
                  _buildTextField("Street / Area*", "e.g., Parit Raja, UTHM", controller: _streetController),
                  const SizedBox(height: 25),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF335D61),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Save Address", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {required TextEditingController controller, TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}