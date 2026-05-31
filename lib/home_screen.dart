import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- IMPORTS FOR ALL SCREENS ---
import 'search_screen.dart';
import 'profile_tab.dart';
import 'explore_screen.dart';
import 'ai_chat_screen.dart';
import 'cart_screen.dart'; 
import 'product_detail_screen.dart'; 
import 'notification_screen.dart'; 
import 'live_feed_screen.dart';   
import 'add_post_screen.dart';    
import 'add_product_screen.dart'; 
import 'broadcast_page.dart'; 
import 'chat_inbox_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final Color primaryColor = const Color(0xFF335D61);

  // --- SELLER STATE ---
  bool isSeller = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 1. WIDGET OPTIONS (Tabs) ---
  final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),        // 0: Home Dashboard
    const LiveFeedScreen(),     // 1: Live Feed (Viewing)
    const ExploreScreen(),      // 2: Explore Map/Grid
    const ProfileTab(),         // 3: User Profile
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // --- CHECK USER ROLE FUNCTION ---
  void _checkUserRole() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          // Strict check: User MUST have 'role' set to 'seller'
          if (data['role'] == 'seller') {
            if (mounted) {
              setState(() {
                isSeller = true;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                isSeller = false;
              });
            }
          }
        }
      } catch (e) {
        print("Error checking role: $e");
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- SMART CREATE MENU (Logic for Seller vs Student) ---
  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          // Height adjusts based on role
          height: isSeller ? 330 : 150, 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create & Explore", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // ====================================================
              //        SELLER ONLY OPTIONS (Go Live & List Product)
              // ====================================================
              if (isSeller) ...[
                // 1. Go Live
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.videocam, color: Colors.red),
                  ),
                  title: const Text("Go Live Now"),
                  subtitle: const Text("Start streaming to your followers"),
                  onTap: () async {
                    Navigator.pop(context); // Close menu
                    _handleGoLive();
                  },
                ),
                
                // 2. List a Product
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.storefront, color: Colors.green),
                  ),
                  title: const Text("List a Product"),
                  subtitle: const Text("Sell items to students"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductScreen()));
                  },
                ),
                const Divider(),
              ],

              // ====================================================
              //            PUBLIC OPTIONS (Social Post)
              // ====================================================
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.post_add, color: Colors.blue),
                ),
                title: const Text("New Social Post"),
                subtitle: const Text("Share moments on Explore feed"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPostScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Logic for Going Live
  Future<void> _handleGoLive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String roomID = user.uid; 
      String name = user.displayName ?? "Seller";

      // 1. Clean up old sessions
      await FirebaseFirestore.instance.collection('active_lives').doc(roomID).delete();

      // 2. Create new session
      await FirebaseFirestore.instance.collection('active_lives').doc(roomID).set({
        'sellerName': name,
        'roomID': roomID,
        'viewers': 0,
        'status': 'live',
        'previewUrl': 'https://assets.mixkit.co/videos/preview/mixkit-potter-making-a-clay-pot-42398-large.mp4',
      });

      if (mounted) {
        // 3. Navigate
        await Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => BroadcastPage(
              liveID: roomID, 
              isHost: true,   
              userID: roomID,
              userName: name,
            ),
          ),
        );

        // 4. Cleanup on return
        await FirebaseFirestore.instance.collection('active_lives').doc(roomID).delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      
      body: _widgetOptions.elementAt(_selectedIndex),
      
      // --- FAB GROUP ---
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "btn_ai",
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatScreen()));
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.auto_awesome, color: Color(0xFFEF963B)),
          ),
          const SizedBox(height: 15),
          
          FloatingActionButton(
            heroTag: "btn_add",
            onPressed: () => _showCreateOptions(context),
            backgroundColor: primaryColor,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      // --- BOTTOM NAV ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.play_circle_filled), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}

// =========================================================
//               HOME DASHBOARD CONTENT
// =========================================================

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  final Color primaryColor = const Color(0xFF335D61);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 25),
          _buildSectionTitle("Shop by Category"),
          const SizedBox(height: 15),
          _buildEtsyStyleCategories(),
          const SizedBox(height: 30),
          _buildSectionTitle("Trending Finds"),
          const SizedBox(height: 15),
          // --- UPDATED: REAL DATA FROM FIRESTORE ---
          _buildTrendingGrid(context),
          const SizedBox(height: 100), 
        ],
      ),
    );
  }

  // --- HEADER WITH GREETING, MESSAGES, CART & NOTIFICATIONS ---
  Widget _buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.85, 0.03),
          end: Alignment(0.20, 1.00),
          colors: [Color(0xFF335D61), Color(0xFF6FB2A6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // User Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hello,', style: TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 5),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                      builder: (context, snapshot) {
                        String nameToDisplay = "User";
                        if (snapshot.hasData && snapshot.data!.exists) {
                          var data = snapshot.data!.data() as Map<String, dynamic>;
                          nameToDisplay = data['fullName'] ?? data['firstName'] ?? user?.displayName ?? "User";
                        }
                        return Text(
                          nameToDisplay,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Action Icons
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatInboxScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.message_outlined, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.notifications_outlined, color: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 25),
          
          // Search Bar
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Text("Search for items...", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B2431))),
    );
  }

  Widget _buildEtsyStyleCategories() {
    final newCategories = [
      {'name': 'Handcraft', 'img': 'https://i.etsystatic.com/isa/bcdeed/152313270168/isa_760xN.152313270168_oi5q.jpg?version=0'},
      {'name': 'Clothing', 'img': 'https://cdn.pixabay.com/photo/2022/07/04/05/14/clothing-7300399_1280.jpg'},
      {'name': 'Food', 'img': 'https://wallpapers.com/images/hd/food-4k-spdnpz7bhmx4kv2r.jpg'},
      {'name': 'Vintage', 'img': 'https://wallpapercave.com/wp/sB34OPs.jpg'},
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20),
        scrollDirection: Axis.horizontal,
        itemCount: newCategories.length,
        itemBuilder: (context, index) {
          final cat = newCategories[index];
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: NetworkImage(cat['img']!), fit: BoxFit.cover),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(cat['name']!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UPDATED: FETCH REAL DATA FROM FIRESTORE ---
  Widget _buildTrendingGrid(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Connect to 'services' collection in Firestore
      stream: FirebaseFirestore.instance
          .collection('services')
          .limit(10) // Optional: limit to 10 latest items
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Empty State
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No items found. Be the first to sell!", style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        // 3. Data Available -> Build Grid
        var docs = snapshot.data!.docs;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.75,
              crossAxisSpacing: 15,
              mainAxisSpacing: 20,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Extract data safely
              var data = docs[index].data() as Map<String, dynamic>;
              
              // Safe defaults if fields are missing
              String image = data['image'] ?? 'https://placehold.co/200';
              String name = data['name'] ?? 'Unknown Item';
              String sellerName = data['sellerName'] ?? 'Verified Seller';
              String price = data['price']?.toString() ?? '0.00';
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(serviceData: data),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey[200],
                          image: DecorationImage(
                            image: NetworkImage(image), 
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    Text(
                      sellerName, 
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "RM $price", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}