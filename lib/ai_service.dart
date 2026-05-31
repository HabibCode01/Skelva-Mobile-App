import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AiService {
  // ⚠️ REPLACE WITH YOUR ACTUAL API KEY
  static const String openAiKey = "OPENAI_KEY_HERE";
  
  // ✅ FIX: Now that openAiKey is static, apiKey can safely read it during initialization
  final String apiKey = openAiKey;

  Future<String> getRecommendation(String userQuery) async {
    String productContext = "";

    try {
      // 1. Fetch real products from your 'services' or 'products' collection
      // We limit to 10 to keep the prompt size manageable
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('services').limit(10).get();
      
      if (snapshot.docs.isEmpty) {
        productContext = "No products currently listed.";
      } else {
        // Create a simple text list of what's available
        List<String> items = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return "${data['name']} (${data['category']}) - ${data['price']}";
        }).toList();
        productContext = items.join(", ");
      }
    } catch (e) {
      productContext = "Unable to fetch live catalog.";
    }

    // 2. Call OpenAI
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content": "You are SkelvaBot, a shopping assistant for the Skelva App (a marketplace for student entrepreneurs). "
                         "Here is the current list of available products: [$productContext]. "
                         "Based ONLY on this list, recommend products to the user. "
                         "If they ask for best sellers, pick 2-3 items from the list and enthusiastically recommend them. "
                         "Keep responses short, friendly, and use emojis."
            },
            {
              "role": "user",
              "content": userQuery
            }
          ],
          "max_tokens": 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        return "I'm having trouble thinking right now. (Error: ${response.statusCode})";
      }
    } catch (e) {
      return "Connection error. Please try again.";
    }
  }
}