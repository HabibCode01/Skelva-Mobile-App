import 'package:flutter/material.dart';
import 'search_results_screen.dart'; // Import the results screen

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(searchQuery: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER & SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF777777), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _performSearch, // Trigger search on Enter
                              decoration: const InputDecoration(
                                hintText: 'Try "Nasi Lemak" or "Crochet"',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- POPULAR SEARCHES (Updated Tags) ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Trending at UTHM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B2431),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // New tags matching your Etsy-style database
                  _buildTag("Nasi Lemak"),
                  _buildTag("Choco Jar"),
                  _buildTag("Crochet"),
                  _buildTag("Vintage Shirt"),
                  _buildTag("Tote Bag"),
                  _buildTag("Sambal"),
                  _buildTag("Stickers"),
                  _buildTag("Burger"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return GestureDetector(
      onTap: () => _performSearch(text), // Click tag to search
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF1B2431),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}