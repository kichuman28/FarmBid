import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_item.dart';
import '../services/user_service.dart';
import '../screens/interests_page.dart';
import '../screens/financial_assistance_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, int> _userStats = {
    'activeAuctions': 0,
    'activeBids': 0,
    'completedDeals': 0
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final user = _auth.currentUser;
    if (user != null) {
      final stats = await _userService.getUserStats(user.uid);
      setState(() {
        _userStats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    // Add test auctions
    await firestore.collection('auctions').add({
      'sellerId': user.uid,
      'status': 'active',
      'name': 'Test Auction 1',
      'price': 100,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await firestore.collection('auctions').add({
      'sellerId': user.uid,
      'status': 'completed',
      'name': 'Test Auction 2',
      'price': 200,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Add test bids
    await firestore.collection('bids').add({
      'bidderId': user.uid,
      'status': 'active',
      'amount': 150,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Refresh stats
    _loadUserStats();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings page
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  user?.photoURL != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(user!.photoURL!),
                          radius: 40,
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.account_circle, size: 50),
                          radius: 40,
                        ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatCard(
                    'Active\nAuctions',
                    _userStats['activeAuctions'].toString(),
                    Icons.gavel,
                  ),
                  _buildStatCard(
                    'Active\nBids',
                    _userStats['activeBids'].toString(),
                    Icons.trending_up,
                  ),
                  _buildStatCard(
                    'Completed\nDeals',
                    _userStats['completedDeals'].toString(),
                    Icons.check_circle,
                  ),
                ],
              ),
            ),

            // Interests Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InterestsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.favorite),
                label: const Text('My Interests'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),

            // Financial Assistance Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinancialAssistancePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.monetization_on),
                label: const Text('Apply for Financial Assistance'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.green, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String subtitle, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'bid':
        return Icons.gavel;
      case 'created':
        return Icons.add_circle;
      case 'won':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
