import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'seller_center_screen.dart'; 
import 'gamification_screen.dart'; 
import 'home_screen.dart'; 

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _registerAsSeller(BuildContext context, String uid) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Activate Seller Account"),
        content: const Text("Confirm that you are a UTHM student?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirm")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': 'seller', 
        'shopName': 'My Student Shop', 
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! You are now a Seller.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isStudentEmail = user?.email != null && user!.email!.endsWith("@student.uthm.edu.my");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
        ),
        title: const Text("My Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async {
             await FirebaseAuth.instance.signOut();
             if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
          })
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String role = userData['role'] ?? 'buyer'; 

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundColor: Colors.grey.shade300, child: Text((userData['firstName'] ?? "U")[0].toUpperCase(), style: const TextStyle(fontSize: 30, color: Colors.white))),
                const SizedBox(height: 10),
                Text(userData['fullName'] ?? "User", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 30),

                // --- SELLER LOGIC ---
                if (isStudentEmail) ...[
                  if (role == 'seller') ...[
                    // CASE A: Seller -> Show Seller Center (Manage Everything Here)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: const Color(0xFF335D61).withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF335D61))),
                      child: ListTile(
                        leading: const Icon(Icons.store, color: Color(0xFF335D61)),
                        title: const Text("Seller Center", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF335D61))),
                        subtitle: const Text("Manage products, orders & dashboard"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerCenterScreen())),
                      ),
                    ),
                  ] else ...[
                    // CASE B: Student but not Seller -> Register
                    Container(
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue)),
                      child: ListTile(
                        leading: const Icon(Icons.verified, color: Colors.blue),
                        title: const Text("Register as Business", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        subtitle: const Text("Start your shop today"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _registerAsSeller(context, user!.uid),
                      ),
                    ),
                  ],
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.videogame_asset, color: Colors.orange),
                  title: const Text("Play & Win Rewards"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen())),
                ),
                const Divider(),
                const ListTile(leading: Icon(Icons.history), title: Text("Order History")),
                const ListTile(leading: Icon(Icons.favorite_border), title: Text("Wishlist")),
                const ListTile(leading: Icon(Icons.help_outline), title: Text("Help Centre")),
              ],
            ),
          );
        }
      ),
    );
  }
}