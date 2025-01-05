import 'package:FarmBid/models/auction_item.dart';
import 'package:FarmBid/models/pre_auction_listing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreAuctionService {
  final CollectionReference _preAuctionCollection =
      FirebaseFirestore.instance.collection('pre_auction_listings');

  Future<void> createPreAuctionListing(PreAuctionListing listing) async {
    try {
      print('Creating pre-auction listing');

      DocumentReference docRef = await _preAuctionCollection.add({
        'sellerId': listing.sellerId,
        'sellerName': listing.sellerName,
        'productName': listing.productName,
        'description': listing.description,
        'location': listing.location,
        'expectedHarvestDate': listing.expectedHarvestDate.toIso8601String(),
        'estimatedQuantity': listing.estimatedQuantity,
        'category': listing.category,
        'interestedBuyerIds': [],
        'isListed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Pre-auction listing created successfully with ID: ${docRef.id}');
    } catch (e) {
      print('Error creating pre-auction listing: $e');
      throw e;
    }
  }

  Stream<QuerySnapshot> getFutureHarvests() {
    try {
      return _preAuctionCollection
          .where('isListed', isEqualTo: false)
          .orderBy('expectedHarvestDate')
          .snapshots();
    } catch (e) {
      print('Error in getFutureHarvests: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getUserInterests(String userId) {
    try {
      return _preAuctionCollection
          .where('isListed', isEqualTo: false)
          .where('interestedBuyerIds', arrayContains: userId)
          .orderBy('expectedHarvestDate')
          .snapshots();
    } catch (e) {
      print('Error in getUserInterests: $e');
      rethrow;
    }
  }

  Future<void> markInterested(String listingId, String buyerId) async {
    try {
      await _preAuctionCollection.doc(listingId).update({
        'interestedBuyerIds': FieldValue.arrayUnion([buyerId])
      });
      print('Successfully marked interest for listing: $listingId');
    } catch (e) {
      print('Error marking interest: $e');
      throw e;
    }
  }

  Future<void> unmarkInterested(String listingId, String buyerId) async {
    try {
      await _preAuctionCollection.doc(listingId).update({
        'interestedBuyerIds': FieldValue.arrayRemove([buyerId])
      });
      print('Successfully unmarked interest for listing: $listingId');
    } catch (e) {
      print('Error unmarking interest: $e');
      throw e;
    }
  }

  Future<void> convertToAuction(
      String listingId, AuctionItem auctionItem) async {
    // Start a transaction to ensure data consistency
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Mark pre-auction as listed
      await transaction
          .update(_preAuctionCollection.doc(listingId), {'isListed': true});

      // Create the auction
      await transaction
          .set(FirebaseFirestore.instance.collection('auction_items').doc(), {
        // auction item details
      });

      // Notify interested buyers
      final listing =
          await transaction.get(_preAuctionCollection.doc(listingId));
      final interestedBuyers =
          listing.get('interestedBuyerIds') as List<String>;

      for (String buyerId in interestedBuyers) {
        await transaction
            .set(FirebaseFirestore.instance.collection('notifications').doc(), {
          'userId': buyerId,
          'type': 'auction_started',
          'title': 'Harvest Ready for Auction',
          'message': '${auctionItem.name} is now available for bidding',
          'auctionId': auctionItem.id,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    });
  }

  Future<void> deletePreAuctionListing(String listingId) async {
    try {
      await _preAuctionCollection.doc(listingId).delete();
      print('Successfully deleted listing: $listingId');
    } catch (e) {
      print('Error deleting listing: $e');
      throw e;
    }
  }
}
