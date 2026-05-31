import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart'; 
import 'chat_screen.dart'; 

class ShopProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const ShopProfileScreen({super.key, required this.sellerId, required this.sellerName});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.sellerName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PROFILE HEADER ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 2)
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: const Color(0xFF335D61),
                            child: Text(
                              widget.sellerName.isNotEmpty ? widget.sellerName[0].toUpperCase() : "S", 
                              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem("4.9", "Rating"),
                              _buildStatItem("1.2k", "Followers"),
                              _buildStatItem("100%", "Chat"),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(widget.sellerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Text("FSKTM Entrepreneur 🎓 • Handcrafts & Food\nDM for custom orders!", style: TextStyle(color: Colors.black87, fontSize: 13)),
                    const SizedBox(height: 15),

                    // --- ACTION BUTTONS ---
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => _isFollowing = !_isFollowing),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing ? Colors.grey[200] : const Color(0xFF335D61),
                              foregroundColor: _isFollowing ? Colors.black : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            child: Text(_isFollowing ? "Following" : "Follow"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => ChatScreen(sellerId: widget.sellerId, sellerName: widget.sellerName))
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: const BorderSide(color: Colors.grey)
                            ),
                            child: const Text("Chat", style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // --- STICKY TABS ---
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF335D61),
                  indicatorWeight: 2,
                  labelColor: const Color(0xFF335D61),
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on), text: "Shop"),
                    Tab(icon: Icon(Icons.video_library_outlined), text: "Posts"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductGrid(), // Tab 1: Products
            _buildSocialGrid(),  // Tab 2: Social Posts
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // --- TAB 1: FETCH PRODUCTS ---
  Widget _buildProductGrid() {
    return StreamBuilder<QuerySnapshot>(
      // Fetches from 'services' collection where sellerId matches
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('sellerId', isEqualTo: widget.sellerId) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("No products listed yet.", style: TextStyle(color: Colors.grey)),
          ));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(serviceData: data)));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade100)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        data['image'] ?? 'https://placehold.co/200',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? "Item", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          Text("RM ${data['price']}", style: const TextStyle(color: Color(0xFFEF963B), fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- TAB 2: FETCH SOCIAL POSTS ---
  Widget _buildSocialGrid() {
    return StreamBuilder<QuerySnapshot>(
      // Fetches from 'posts' collection where userId matches sellerId
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.sellerId) 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("No social posts yet.", style: TextStyle(color: Colors.grey)),
          ));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            bool isVideo = data['type'] == 'Video'; 

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  data['mediaUrl'] ?? 'https://placehold.co/150',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200]),
                ),
                if (isVideo)
                  const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 24))
              ],
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}