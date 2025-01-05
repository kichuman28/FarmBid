import 'package:flutter/material.dart';
import '../models/auction_item.dart';
import '../services/auction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'bid_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'delivery_success_page.dart';

class AuctionDetailPage extends StatelessWidget {
  final AuctionItem item;
  final bool showLocation;
  final AuctionService _auctionService = AuctionService();

  AuctionDetailPage({
    required this.item,
    this.showLocation = false,
  });

  Widget _buildImageCarousel() {
    if (item.images.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 300,
      child: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(item.images[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        itemCount: item.images.length,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(),
        ),
        backgroundDecoration: BoxDecoration(
          color: Colors.black,
        ),
        pageController: PageController(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highestBid = item.bids.isNotEmpty
        ? item.bids.reduce((a, b) => a.amount > b.amount ? a : b)
        : null;
    final remainingTime = item.endTime.difference(DateTime.now());
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner = currentUser?.uid == item.sellerId;
    final bool isWinner = currentUser?.uid == item.winnerId;
    final bool canConfirm = isWinner && 
                          item.status == AuctionStatus.closed && 
                          !(item.deliveryConfirmed ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          if (isOwner && item.status != AuctionStatus.closed)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'end') {
                  _showEndAuctionDialog(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'end',
                  child: Text('End Auction Now'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(item.description, style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Location', item.location),
                          _buildInfoRow('Quantity', item.quantity.toString()),
                          _buildInfoRow('Starting Bid', '₹${item.startingBid}'),
                          _buildInfoRow('Current Bid', '₹${item.currentBid}'),
                          _buildInfoRow('Time Remaining', 
                            remainingTime.isNegative ? 'Auction Ended' : 
                            '${remainingTime.inHours}h ${remainingTime.inMinutes.remainder(60)}m'),
                          _buildInfoRow('Highest Bidder', 
                            highestBid != null ? highestBid.bidderName : 'No bids yet'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Bid History:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: item.bids.length,
                      itemBuilder: (context, index) {
                        final bid = item.bids[index];
                        return ListTile(
                          leading: Icon(Icons.person_outline),
                          title: Text(bid.bidderName),
                          trailing: Text(
                            '₹${bid.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: canConfirm ? Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => _showConfirmationDialog(context),
          child: Text('Confirm Delivery'),
        ),
      ) : (!isOwner && item.status != AuctionStatus.closed ? Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Bid',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${item.currentBid.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: remainingTime.isNegative ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BidPage(item: item),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  remainingTime.isNegative ? 'Auction Ended' : 'Place Bid',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ) : null),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (label == 'Location' && !showLocation) {
      return SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (label == 'Location' && showLocation)
            GestureDetector(
              onTap: () => _launchMaps(item.latitude, item.longitude),
              child: Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.map, size: 16, color: Colors.blue),
                ],
              ),
            )
          else
            Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }

  void _launchMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _showEndAuctionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('End Auction Now'),
          content: Text('Are you sure you want to end this auction immediately?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _auctionService.endAuctionNow(item.id);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('End Now'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    final TextEditingController confirmationController = TextEditingController();
    bool isAgreed = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Confirm Product Delivery'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: confirmationController,
                    decoration: InputDecoration(
                      labelText: 'Confirmation Message',
                      hintText: 'Describe the condition of the received product',
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isAgreed,
                        onChanged: (bool? value) {
                          setState(() {
                            isAgreed = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'I agree that by confirming, the locked funds will be transferred to the seller and this action cannot be undone.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: !isAgreed ? null : () async {
                    if (confirmationController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a confirmation message')),
                      );
                      return;
                    }
                    
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      final success = await _auctionService.confirmDelivery(
                        item.id,
                        currentUser.uid,
                        confirmationController.text,
                      );
                      if (success) {
                        Navigator.pop(context);
                        _showRatingDialog(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to confirm delivery. Please try again.')),
                        );
                      }
                    }
                  },
                  child: Text('Confirm Delivery'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showRatingDialog(BuildContext context) {
    double rating = 3.0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Rate Seller'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write your review...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (reviewController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please write a review')),
                      );
                      return;
                    }
                    await _auctionService.addRating(
                      item.id,
                      rating,
                      reviewController.text,
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => DeliverySuccessPage(
                          itemName: item.name,
                        ),
                      ),
                    );
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}