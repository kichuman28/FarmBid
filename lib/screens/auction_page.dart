import 'package:flutter/material.dart';
import '../models/auction_item.dart';
import '../services/auction_service.dart';
import 'add_product_page.dart';
import 'bid_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auction_detail_page.dart';
import '../widgets/auction_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../tutorial/auction_page_tutorial.dart';
import '../tutorial/tutorial_overlay.dart';
import '../tutorial/tutorial_controller.dart';

class AuctionPage extends StatefulWidget {
  @override
  _AuctionPageState createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> with SingleTickerProviderStateMixin {
  final AuctionService _auctionService = AuctionService();
  final List<GlobalKey> _tutorialKeys = [
    GlobalKey(), // App bar
    GlobalKey(), // Available auctions tab
    GlobalKey(), // My auctions tab
    GlobalKey(), // Won auctions tab
    GlobalKey(), // Add auction button
  ];
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Rice',
    'Grains',
    'Dairy',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _checkAndShowTutorial();
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Check every minute for expired auctions
    Future.delayed(Duration(seconds: 5), () async {
      await _auctionService.checkExpiredAuctions();
      _startPeriodicCheck();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    if (!await TutorialController.hasSeenAuctionTutorial()) {
      // Wait for the widget to be built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTutorial();
      });
    }
  }

  void _startTutorial() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: AuctionPageTutorial.getSteps(context, _tutorialKeys),
        onComplete: () {
          Navigator.of(context).pop();
          TutorialController.markAuctionTutorialAsSeen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          key: _tutorialKeys[0],
          elevation: 0,
          title: Text('FarmBid Market'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(
                key: _tutorialKeys[1],
                icon: Icon(Icons.gavel),
                text: 'Available Auctions',
              ),
              Tab(
                key: _tutorialKeys[2],
                icon: Icon(Icons.inventory),
                text: 'My Auctions',
              ),
              Tab(
                key: _tutorialKeys[3],
                icon: Icon(Icons.emoji_events),
                text: 'Won Auctions',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Start Tutorial',
              onPressed: _startTutorial,
            ),
            IconButton(
              key: _tutorialKeys[4],
              icon: Icon(Icons.add_circle_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductPage()),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAvailableAuctionsTab(),
            _buildMyAuctionsTab(),
            _buildWonAuctionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableAuctionsTab() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<List<AuctionItem>>(
      stream: _auctionService.getAuctionItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allAuctionItems = snapshot.data ?? [];
        // Filter out auctions owned by the current user
        final auctionItems = allAuctionItems
            .where((item) => item.sellerId != currentUser?.uid)
            .toList();
        
        if (auctionItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No auctions available'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: auctionItems.length,
          itemBuilder: (context, index) {
            final item = auctionItems[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailPage(item: item),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section
                    Container(
                      width: 120,
                      height: 120,
                      child: item.images.isNotEmpty
                          ? Image.network(
                              item.images[0],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.error_outline, color: Colors.red),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                    ),
                    // Content section
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${item.currentBid}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  _formatRemainingTime(item.endTime.difference(DateTime.now())),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search Auctions',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          DropdownButton<String>(
            value: _selectedCategory,
            hint: Text('Select Category'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            items: categories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIndicator(AuctionItem item) {
    if (item.status == AuctionStatus.closed) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: item.endTime.isAfter(DateTime.now()) ? Colors.blue : Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMyAuctionsTab() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<List<AuctionItem>>(
      stream: _auctionService.getAuctionItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final auctionItems = snapshot.data ?? [];
        final myItems = auctionItems
            .where((item) => item.sellerId == currentUser?.uid)
            .toList();

        if (myItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No auctions yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductPage()),
                  ),
                  icon: Icon(Icons.add),
                  label: Text('Add New Auction'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: myItems.length,
          itemBuilder: (context, index) {
            final item = myItems[index];
            final remainingTime = item.endTime.difference(DateTime.now());
            
            return Card(
              child: ListTile(
                title: Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Bid: ₹${item.currentBid.toStringAsFixed(2)}'),
                    Text('Time Remaining: ${_formatRemainingTime(remainingTime)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getStatusIndicator(item),

                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailPage(item: item),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWonAuctionsTab() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<List<AuctionItem>>(
      stream: _auctionService.getWonAuctions(currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final wonItems = snapshot.data ?? [];

        if (wonItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No won auctions yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: wonItems.length,
          itemBuilder: (context, index) {
            final item = wonItems[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text(item.description),
              trailing: IconButton(
                icon: Icon(Icons.map),
                onPressed: () => _launchMaps(item.latitude, item.longitude),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuctionDetailPage(
                    item: item,
                    showLocation: true,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _launchMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.isNegative) {
      return 'Ended';
    }
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

}