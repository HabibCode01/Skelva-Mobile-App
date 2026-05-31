import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // REQUIRED FOR UPLOAD
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  String _selectedType = 'Image';
  File? _selectedImage;

  // --- 1. PICK IMAGE LOGIC ---
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final returnedImage = await ImagePicker().pickImage(source: source);
      if (returnedImage == null) return;
      setState(() {
        _selectedImage = File(returnedImage.path);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  // --- 2. UPLOAD IMAGE LOGIC ---
  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      // Create a unique filename based on time
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('posts/${user!.uid}/$fileName.jpg');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  Future<void> _sharePost() async {
    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write a caption")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final userData = userDoc.data()!;

      String? imageUrl;

      // 1. Upload Image if selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToStorage(_selectedImage!);
        if (imageUrl == null) throw "Image upload failed";
      } else {
        // Fallback or force user to pick image
        imageUrl = 'https://placehold.co/600x400/png?text=No+Image';
      }

      // 2. Save Data to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userName': userData['fullName'] ?? user.displayName ?? 'Student',
        'userImage': user.photoURL,
        'caption': _captionController.text,
        'type': _selectedType,
        'mediaUrl': imageUrl, // NOW SAVES THE REAL URL
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Posted Successfully!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Post"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator())
              : TextButton(
                  onPressed: _sharePost,
                  child: const Text("Share", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF335D61))),
                )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      hintText: "Write a caption...",
                      border: InputBorder.none,
                    ),
                    maxLines: 5,
                  ),
                ),
                
                // --- CLICKABLE IMAGE AREA (Fixed Click) ---
                GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context),
                  behavior: HitTestBehavior.opaque, // Ensures click is detected even on empty space
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      image: _selectedImage != null
                          ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _selectedImage == null
                        ? const Icon(Icons.add_a_photo, color: Colors.grey)
                        : null,
                  ),
                )
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF335D61)),
              title: const Text("Post Type"),
              trailing: DropdownButton<String>(
                value: _selectedType,
                underline: Container(),
                items: ['Image', 'Video'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedType = newValue!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}