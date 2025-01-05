// lib/services/user_service.dart
import 'package:FarmBid/models/activity_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Get active auctions count
      final activeAuctions = await _firestore
          .collection('auction_items')
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      // Get active bids count
      final activeBids = await _firestore
          .collection('bids')
          .where('bidderId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      // Get completed deals count
      final completedDeals = await _firestore
          .collection('auction_items')
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .count()
          .get();

      return {
        'activeAuctions': activeAuctions.count ?? 0,
        'activeBids': activeBids.count ?? 0,
        'completedDeals': completedDeals.count ?? 0,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return {'activeAuctions': 0, 'activeBids': 0, 'completedDeals': 0};
    }
  }

  Stream<List<ActivityItem>> getUserActivities(String userId) {
    return _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityItem.fromFirestore(doc))
            .toList());
  }
}
