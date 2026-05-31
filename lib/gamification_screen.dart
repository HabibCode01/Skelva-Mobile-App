import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'spin_wheel_game.dart'; // We will create this next
import 'meteor_shooter_game.dart'; // We will create this too

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  bool _checkedInToday = false;
  double _coins = 0.0; // Changed to double to support 0.1 increments

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          // Ensure we handle both int and double from Firestore
          _coins = (doc.data()?['coins'] ?? 0).toDouble();
        });
        // Check check-in timestamp logic here (omitted for brevity)
      }
    }
  }

  Future<void> _dailyCheckIn() async {
    if (_checkedInToday) return;
    
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _coins += 10;
      _checkedInToday = true;
    });

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'coins': FieldValue.increment(10),
      'lastCheckIn': FieldValue.serverTimestamp(),
    });

    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checked in! +10 Coins")));
  }

  // Generic function to deduct coins and enter a game
  Future<void> _enterGame(int cost, Widget gameScreen) async {
    if (_coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Need $cost coins to play!")));
      return;
    }

    // Deduct entry fee immediately
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _coins -= cost);
    
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'coins': FieldValue.increment(-cost),
    });

    if (!mounted) return;

    // Navigate to Game and wait for result (coins earned)
    final earned = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );

    // If game returned earnings, update UI
    if (earned != null && earned is double && earned > 0) {
      setState(() => _coins += earned);
      // Note: The game screen itself handles the Firestore update for earnings
      _fetchUserData(); // Refresh to be safe
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text("Arcade Center"), backgroundColor: const Color(0xFF335D61), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Coins Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              color: const Color(0xFF335D61),
              child: Column(
                children: [
                  const Icon(Icons.monetization_on, size: 50, color: Colors.amber),
                  const SizedBox(height: 10),
                  Text("${_coins.toStringAsFixed(1)} Coins", style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Daily Check In
            Container(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text("Daily Check-in"),
                subtitle: const Text("Get 10 coins daily"),
                trailing: ElevatedButton(
                  onPressed: _checkedInToday ? null : _dailyCheckIn,
                  child: Text(_checkedInToday ? "Done" : "Check In"),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Mini Games", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // GAME 1: SPIN WHEEL
                  _buildGameCard(
                    title: "Spin & Win",
                    description: "Test your luck! Win big prizes.",
                    cost: 10,
                    color: Colors.purple.shade50,
                    icon: Icons.casino,
                    onPlay: () => _enterGame(10, const SpinWheelGame()),
                  ),

                  const SizedBox(height: 15),

                  // GAME 2: METEOR SHOOTER
                  _buildGameCard(
                    title: "Space Defender",
                    description: "Shoot meteors! 0.1 coin per hit.",
                    cost: 5,
                    color: Colors.indigo.shade50,
                    icon: Icons.rocket_launch,
                    onPlay: () => _enterGame(5, const MeteorShooterGame()),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({required String title, required String description, required int cost, required Color color, required IconData icon, required VoidCallback onPlay}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: const Color(0xFF335D61)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 5),
                Text("Entry Cost: $cost Coins", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF963B))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPlay,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF335D61)),
            child: const Text("Play", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}