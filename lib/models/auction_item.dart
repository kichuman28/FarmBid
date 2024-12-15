enum AuctionStatus {
  live,
  closed,
  upcoming,
}

class AuctionItem {
  final String id;
  final String name;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final int quantity;
  final String category;
  final String otherCategoryDescription;
  final double startingBid;
  final double currentBid;
  final String sellerId;
  final String sellerName;
  final List<Bid> bids;
  final DateTime endTime;
  final AuctionStatus status;
  final List<String> images;
  final String? winnerId;
  final String? winnerName;
  final bool? deliveryConfirmed;
  final String? confirmationText;

  AuctionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.quantity,
    required this.category,
    required this.otherCategoryDescription,
    required this.startingBid,
    required this.currentBid,
    required this.sellerId,
    required this.sellerName,
    required this.bids,
    required this.endTime,
    required this.status,
    required this.images,
    this.winnerId,
    this.winnerName,
    this.deliveryConfirmed,
    this.confirmationText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'quantity': quantity,
      'category': category,
      'otherCategoryDescription': otherCategoryDescription,
      'startingBid': startingBid,
      'currentBid': currentBid,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'bids': bids.map((bid) => bid.toMap()).toList(),
      'endTime': endTime.toIso8601String(),
      'status': status.toString(),
      'images': images,
    };
  }
}

class Bid {
  final String bidderId;
  final String bidderName;
  final double amount;

  Bid({
    required this.bidderId,
    required this.bidderName,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'bidderId': bidderId,
      'bidderName': bidderName,
      'amount': amount,
    };
  }
}
