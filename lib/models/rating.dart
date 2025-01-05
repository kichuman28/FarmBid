class Rating {
  final String id;
  final String auctionId;
  final String sellerId;
  final String buyerId;
  final String buyerName;
  final double rating;
  final String review;
  final DateTime timestamp;

  Rating({
    required this.id,
    required this.auctionId,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    required this.review,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'auctionId': auctionId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'rating': rating,
      'review': review,
      'timestamp': timestamp,
    };
  }
} 