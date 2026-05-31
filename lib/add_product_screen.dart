import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController(); // NEW: Description
  String _selectedCategory = 'Food';
  bool _isLoading = false;
  File? _productImage;

  final List<String> _categories = ['Food', 'Handcraft', 'Clothing', 'Services'];

  // --- 1. PICK IMAGE ---
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (image != null) setState(() => _productImage = File(image.path));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final image = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (image != null) setState(() => _productImage = File(image.path));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 2. UPLOAD IMAGE TO FIREBASE STORAGE ---
  Future<String?> _uploadProductImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      String fileName = "${DateTime.now().millisecondsSinceEpoch}_product.jpg";
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('products/${user!.uid}/$fileName');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Product Upload Error: $e");
      return null;
    }
  }

  // --- 3. SUBMIT PRODUCT ---
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_productImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a photo of your product")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // A. Upload Image
      String? imageUrl = await _uploadProductImage(_productImage!);
      if (imageUrl == null) throw "Failed to upload image";

      // B. Parse Price to Number (Critical for Checkout)
      double price = double.tryParse(_priceController.text) ?? 0.0;

      // C. Save to Firestore
      await FirebaseFirestore.instance.collection('services').add({
        'name': _nameController.text,
        'price': price, // Saved as Number
        'description': _descController.text, // New Field
        'category': _selectedCategory,
        'sellerId': user!.uid, // Links to Seller Center
        'sellerName': user.displayName ?? "Student Seller",
        'location': "UTHM Campus",
        'status': "Available",
        'rating': 5.0, // Default start rating
        'reviewCount': 0,
        'completedJobs': 0,
        'image': imageUrl,
        'searchKeywords': _generateKeywords(_nameController.text), // Helps Search
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product Listed Successfully!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper for Search Keywords
  List<String> _generateKeywords(String title) {
    List<String> keywords = [];
    String temp = "";
    for (int i = 0; i < title.length; i++) {
      temp = temp + title[i].toLowerCase();
      keywords.add(temp);
    }
    return keywords;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Listing"), 
        backgroundColor: Colors.white, 
        foregroundColor: Colors.black, 
        elevation: 0
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- IMAGE PICKER ---
                Center(
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _productImage != null
                            ? DecorationImage(image: FileImage(_productImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _productImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                                SizedBox(height: 10),
                                Text("Tap to add photo", style: TextStyle(color: Colors.grey, fontSize: 16))
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
            
                // --- NAME INPUT ---
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Product Name", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 15),
            
                // --- PRICE & CATEGORY ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: "Price (RM)", border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // --- DESCRIPTION INPUT (NEW) ---
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description", 
                    hintText: "Describe your item (e.g. ingredients, size, condition)",
                    border: OutlineInputBorder()
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 30),
            
                // --- SUBMIT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitProduct,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF335D61)),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("List Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}