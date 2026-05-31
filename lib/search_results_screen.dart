import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final String searchQuery;

  const SearchResultsScreen({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    // 1. Prepare search term (Lowercase for matching)
    final String term = searchQuery.toLowerCase().trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Results for \"$searchQuery\"",
          style: const TextStyle(color: Color(0xFF1B2431), fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Text("Sort by", style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 2. Stream Builder with SAFETY CHECKS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Fetch ALL services (Fixes Case Sensitivity & Index Errors)
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // 3. FILTER LOGIC (Manual Filter)
                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString().toLowerCase();
                  
                  // Check if name contains the search term
                  return name.contains(term) || category.contains(term);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildServiceCard(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          Text("No items found for \"$searchQuery\"",
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> data) {
    // Safety check for Image URL
    String imageUrl = data['image'] ?? '';
    bool isValidUrl = imageUrl.isNotEmpty && imageUrl.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(serviceData: data),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // Ensure card is white
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E5E5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image (Fixed Size with Safety)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                    image: isValidUrl 
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                          onError: (e, s) {}, // Handle load error silently
                        )
                      : null, // No image if URL invalid
                  ),
                  child: !isValidUrl 
                    ? const Icon(Icons.image_not_supported, color: Colors.grey) 
                    : null,
                ),
                const SizedBox(width: 12),
                
                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown Item',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B2431),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Location Row
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['location'] ?? 'Parit Raja',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Sold Count Row
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 12, color: Color(0xFF335D61)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['completedJobs']?.toString() ?? 'New Item',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF335D61), fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E5E5)),
            const SizedBox(height: 12),
            
            // Bottom Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(data['rating']?.toString() ?? '5.0',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 2),
                    Text(data['reviewCount']?.toString() ?? '(0)',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                // Price (Handle String or Number safely)
                Text(
                  "RM ${data['price']?.toString() ?? '0.00'}",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF335D61)),
                ),
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Text(
                    data['status'] ?? 'Available',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}