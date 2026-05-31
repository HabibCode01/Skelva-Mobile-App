import 'package:cloud_firestore/cloud_firestore.dart';

class PopulateFirebase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- METHOD 1: Add Products (Services) ---
  Future<void> addDummyData() async {
    // Collection name
    final CollectionReference services = _firestore.collection('services');

    // 20 New "Etsy-Style" Student Products (Food, Handcraft, Clothing)
    final List<Map<String, dynamic>> dummyData = [
      
      // --- FOOD (7 Items) ---
      {
        "name": "Nasi Lemak 'Bujang' Special",
        "category": "Food",
        "location": "Kolej Kediaman Tun Dr. Ismail (KKTDI)",
        "status": "Available",
        "completedJobs": "500+ sold",
        "rating": "4.9",
        "reviewCount": "(120)",
        "price": "RM 5.00",
        "timeAway": "10 mins",
        "image": "https://placehold.co/300x300/orange/white?text=Nasi+Lemak",
        "keywords": ["food", "nasi lemak", "spicy", "breakfast", "dinner", "sambal", "rice"]
      },
      {
        "name": "Homemade Choco Jar (Crispy)",
        "category": "Food",
        "location": "Parit Raja",
        "status": "In Stock",
        "completedJobs": "200 jars sold",
        "rating": "4.8",
        "reviewCount": "(85)",
        "price": "RM 12.00",
        "timeAway": "15 mins",
        "image": "https://placehold.co/300x300/brown/white?text=Choco+Jar",
        "keywords": ["food", "choco", "chocolate", "sweet", "snack", "jar", "dessert"]
      },
      {
        "name": "Spicy Sambal Penyet (Bottle)",
        "category": "Food",
        "location": "Kolej Tun Fatimah",
        "status": "Available",
        "completedJobs": "50 bottles sold",
        "rating": "5.0",
        "reviewCount": "(40)",
        "price": "RM 15.00",
        "timeAway": "5 mins",
        "image": "https://placehold.co/300x300/red/white?text=Sambal",
        "keywords": ["food", "sambal", "spicy", "pedas", "condiment", "homemade"]
      },
      {
        "name": "Honey Cornflakes (Raya Ed.)",
        "category": "Food",
        "location": "Kolej Perwira",
        "status": "Pre-order",
        "completedJobs": "Seasonal Best Seller",
        "rating": "4.7",
        "reviewCount": "(30)",
        "price": "RM 22.00",
        "timeAway": "20 mins",
        "image": "https://placehold.co/300x300/yellow/black?text=Cornflakes",
        "keywords": ["food", "cookies", "raya", "honey", "sweet", "cornflakes"]
      },
      {
        "name": "Iced Coffee 'Ikat Tepi'",
        "category": "Food",
        "location": "Library Foyer",
        "status": "Open",
        "completedJobs": "Daily fix for students",
        "rating": "4.6",
        "reviewCount": "(100)",
        "price": "RM 3.50",
        "timeAway": "On Campus",
        "image": "https://placehold.co/300x300/brown/white?text=Kopi",
        "keywords": ["food", "coffee", "drink", "ice", "kopi", "beverage"]
      },
      {
        "name": "Spicy Basreng (Fried Meatballs)",
        "category": "Food",
        "location": "Taman Universiti",
        "status": "Available",
        "completedJobs": "Addictive snack!",
        "rating": "4.9",
        "reviewCount": "(55)",
        "price": "RM 8.00",
        "timeAway": "25 mins",
        "image": "https://placehold.co/300x300/red/yellow?text=Basreng",
        "keywords": ["food", "snack", "spicy", "chips", "basreng", "keropok"]
      },
      {
        "name": "Student Budget Burger",
        "category": "Food",
        "location": "KKTDI Gate",
        "status": "Open Nightly",
        "completedJobs": "Supper favorite",
        "rating": "4.5",
        "reviewCount": "(200)",
        "price": "RM 4.00",
        "timeAway": "5 mins",
        "image": "https://placehold.co/300x300/orange/black?text=Burger",
        "keywords": ["food", "burger", "dinner", "supper", "meat", "fast food"]
      },

      // --- HANDCRAFT (7 Items) ---
      {
        "name": "Crochet Flower Bouquet",
        "category": "Handcraft",
        "location": "Kolej Bestari",
        "status": "Custom Order",
        "completedJobs": "Perfect for convos",
        "rating": "5.0",
        "reviewCount": "(45)",
        "price": "RM 35.00",
        "timeAway": "3 days lead time",
        "image": "https://placehold.co/300x300/pink/white?text=Crochet",
        "keywords": ["handcraft", "crochet", "flower", "gift", "bouquet", "knit", "convo"]
      },
      {
        "name": "Custom Resin Keychain",
        "category": "Handcraft",
        "location": "Parit Raja",
        "status": "Available",
        "completedJobs": "150 custom names",
        "rating": "4.8",
        "reviewCount": "(60)",
        "price": "RM 8.00",
        "timeAway": "2 days",
        "image": "https://placehold.co/300x300/purple/white?text=Resin",
        "keywords": ["handcraft", "resin", "keychain", "custom", "gift", "name", "art"]
      },
      {
        "name": "Hand-Painted Tote Bag",
        "category": "Handcraft",
        "location": "FSKTM Faculty",
        "status": "In Stock",
        "completedJobs": "Unique designs",
        "rating": "4.9",
        "reviewCount": "(25)",
        "price": "RM 25.00",
        "timeAway": "On Campus",
        "image": "https://placehold.co/300x300/blue/white?text=Tote+Bag",
        "keywords": ["handcraft", "bag", "tote", "paint", "art", "canvas", "fashion"]
      },
      {
        "name": "Beaded Phone Strap",
        "category": "Handcraft",
        "location": "Kolej Tun Fatimah",
        "status": "Available",
        "completedJobs": "Trendy accessory",
        "rating": "4.7",
        "reviewCount": "(30)",
        "price": "RM 6.00",
        "timeAway": "5 mins",
        "image": "https://placehold.co/300x300/cyan/white?text=Strap",
        "keywords": ["handcraft", "beads", "phone", "accessory", "charm", "colorful"]
      },
      {
        "name": "Paracord Bracelet (Rugged)",
        "category": "Handcraft",
        "location": "Kolej Perwira",
        "status": "Available",
        "completedJobs": "Durable gear",
        "rating": "4.6",
        "reviewCount": "(15)",
        "price": "RM 12.00",
        "timeAway": "10 mins",
        "image": "https://placehold.co/300x300/green/white?text=Paracord",
        "keywords": ["handcraft", "bracelet", "paracord", "outdoor", "fashion", "men"]
      },
      {
        "name": "Laptop Stickers Pack (Dev)",
        "category": "Handcraft",
        "location": "Library",
        "status": "In Stock",
        "completedJobs": "For coding life",
        "rating": "5.0",
        "reviewCount": "(80)",
        "price": "RM 10.00",
        "timeAway": "Instant",
        "image": "https://placehold.co/300x300/black/white?text=Stickers",
        "keywords": ["handcraft", "stickers", "laptop", "coding", "art", "print"]
      },
      {
        "name": "Scented Soy Wax Candle",
        "category": "Handcraft",
        "location": "Taman Manis",
        "status": "Available",
        "completedJobs": "Relaxing vibes",
        "rating": "4.8",
        "reviewCount": "(20)",
        "price": "RM 18.00",
        "timeAway": "15 mins",
        "image": "https://placehold.co/300x300/grey/white?text=Candle",
        "keywords": ["handcraft", "candle", "wax", "scent", "home", "decor", "relax"]
      },

      // --- CLOTHING (6 Items) ---
      {
        "name": "Vintage Graphic Tee (L)",
        "category": "Clothing",
        "location": "KKTDI",
        "status": "1 Unit",
        "completedJobs": "Thrift find",
        "rating": "New",
        "reviewCount": "(0)",
        "price": "RM 35.00",
        "timeAway": "10 mins",
        "image": "https://placehold.co/300x300/black/white?text=T-Shirt",
        "keywords": ["clothing", "shirt", "vintage", "bundle", "fashion", "men"]
      },
      {
        "name": "Pre-loved Denim Jacket",
        "category": "Clothing",
        "location": "Parit Raja",
        "status": "Available",
        "completedJobs": "Good condition",
        "rating": "4.5",
        "reviewCount": "(5)",
        "price": "RM 50.00",
        "timeAway": "20 mins",
        "image": "https://placehold.co/300x300/blue/white?text=Jacket",
        "keywords": ["clothing", "jacket", "denim", "outerwear", "bundle", "fashion"]
      },
      {
        "name": "Custom Printed Jersey",
        "category": "Clothing",
        "location": "FKAAS Faculty",
        "status": "Pre-order",
        "completedJobs": "Class shirts expert",
        "rating": "4.9",
        "reviewCount": "(10 teams)",
        "price": "RM 45.00",
        "timeAway": "1 week",
        "image": "https://placehold.co/300x300/red/white?text=Jersey",
        "keywords": ["clothing", "jersey", "sport", "custom", "print", "team"]
      },
      {
        "name": "Tie-Dye Hoodie (Pastel)",
        "category": "Clothing",
        "location": "Kolej Tun Syed Nasir",
        "status": "Available",
        "completedJobs": "Hand dyed",
        "rating": "5.0",
        "reviewCount": "(12)",
        "price": "RM 60.00",
        "timeAway": "3 days",
        "image": "https://placehold.co/300x300/pink/white?text=Hoodie",
        "keywords": ["clothing", "hoodie", "tiedye", "art", "fashion", "pastel"]
      },
      {
        "name": "Pre-loved Kurta (Size M)",
        "category": "Clothing",
        "location": "Kolej Bestari",
        "status": "Available",
        "completedJobs": "Worn once",
        "rating": "New",
        "reviewCount": "(0)",
        "price": "RM 40.00",
        "timeAway": "10 mins",
        "image": "https://placehold.co/300x300/green/white?text=Kurta",
        "keywords": ["clothing", "kurta", "traditional", "men", "bundle", "raya"]
      },
      {
        "name": "Bundle Windbreaker",
        "category": "Clothing",
        "location": "Taman Universiti",
        "status": "Available",
        "completedJobs": "Retro style",
        "rating": "4.7",
        "reviewCount": "(8)",
        "price": "RM 25.00",
        "timeAway": "15 mins",
        "image": "https://placehold.co/300x300/purple/white?text=Windbreaker",
        "keywords": ["clothing", "jacket", "windbreaker", "bundle", "sport", "retro"]
      },
    ];

    try {
      for (var service in dummyData) {
        await services.add(service);
      }
      print("✅ Successfully added 20 Student Products (Food, Handcraft, Clothing)!");
    } catch (e) {
      print("❌ Error adding data: $e");
    }
  }

  // --- METHOD 2: Add Social Posts (Explore Feed) ---
  Future<void> addDummyPosts() async {
    final CollectionReference posts = _firestore.collection('posts');

    final List<Map<String, dynamic>> dummyPosts = [
      {
        "userId": "dummy_user_1",
        "userName": "Sarah Bakes",
        "userImage": null, // No profile pic
        "caption": "Fresh batch of Honey Cornflakes ready for Raya! 🌽🍯 DM to reserve yours now. Limited jars left!",
        "type": "Image",
        "mediaUrl": "https://placehold.co/600x600/orange/white?text=Cornflakes",
        "likes": ["user_2", "user_3"],
        "timestamp": FieldValue.serverTimestamp(),
      },
      {
        "userId": "dummy_user_2",
        "userName": "Ali Pottery",
        "userImage": null,
        "caption": "Behind the scenes of glazing my new ceramic mugs. 🔥 Kiln opening tomorrow!",
        "type": "Video", // Will show the video icon
        "mediaUrl": "https://placehold.co/600x800/brown/white?text=Pottery+Video",
        "likes": ["user_1", "user_4", "user_5"],
        "timestamp": FieldValue.serverTimestamp(),
      },
      {
        "userId": "dummy_user_3",
        "userName": "KL Textiles",
        "userImage": null,
        "caption": "New Batik shirts in stock! 🌿 Perfect for Friday wear. Size S-XL available.",
        "type": "Image",
        "mediaUrl": "https://placehold.co/600x700/blue/white?text=Batik+Shirt",
        "likes": [],
        "timestamp": FieldValue.serverTimestamp(),
      },
      {
        "userId": "dummy_user_4",
        "userName": "Mama Recipe",
        "userImage": null,
        "caption": "Spicy Sambal is back! 🌶️ Made fresh this morning. Grab yours at KKTDI foyer.",
        "type": "Image",
        "mediaUrl": "https://placehold.co/600x600/red/white?text=Sambal",
        "likes": ["user_2"],
        "timestamp": FieldValue.serverTimestamp(),
      },
      {
        "userId": "dummy_user_5",
        "userName": "Borneo Crafts",
        "userImage": null,
        "caption": "Weaving a new basket pattern today. Stay tuned for the final result! 🧺",
        "type": "Video",
        "mediaUrl": "https://placehold.co/600x900/green/white?text=Weaving+Video",
        "likes": ["user_1", "user_2"],
        "timestamp": FieldValue.serverTimestamp(),
      },
      {
        "userId": "dummy_user_6",
        "userName": "SilverSmith",
        "userImage": null,
        "caption": "Polishing up some custom silver rings. ✨ Open for custom sizing orders.",
        "type": "Image",
        "mediaUrl": "https://placehold.co/600x600/grey/white?text=Silver+Rings",
        "likes": ["user_3", "user_4"],
        "timestamp": FieldValue.serverTimestamp(),
      },
      {
        "userId": "dummy_user_7",
        "userName": "Vintage Finds",
        "userImage": null,
        "caption": "Thrift haul alert! 🚨 Dropping these vintage windbreakers tonight at 8PM.",
        "type": "Image",
        "mediaUrl": "https://placehold.co/600x500/purple/white?text=Jackets",
        "likes": ["user_1", "user_5", "user_6"],
        "timestamp": FieldValue.serverTimestamp(),
      },
      {
        "userId": "dummy_user_8",
        "userName": "Crochet Corner",
        "userImage": null,
        "caption": "Cute whale plushies finished! 🐳 Only RM 15 each.",
        "type": "Image",
        "mediaUrl": "https://placehold.co/600x600/cyan/white?text=Plushies",
        "likes": ["user_2", "user_7"],
        "timestamp": FieldValue.serverTimestamp(),
      },
    ];

    try {
      for (var post in dummyPosts) {
        await posts.add(post);
      }
      print("✅ Successfully added 8 Dummy Posts to Explore!");
    } catch (e) {
      print("❌ Error adding posts: $e");
    }
  }
}