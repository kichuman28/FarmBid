import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/auction_item.dart';
import '../services/auction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? preAuctionData;
  final String? preAuctionId;

  AddProductPage({this.preAuctionData, this.preAuctionId});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final AuctionService _auctionService = AuctionService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _startingBidController = TextEditingController();
  final TextEditingController _otherCategoryController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String _selectedCategory = 'Vegetables'; // Default category
  Duration _auctionDuration = Duration(hours: 12); // Default auction duration
  bool _isLoadingLocation = false;

  List<String> categories = [
    'Vegetables',
    'Fruits',
    'Rice',
    'Grains',
    'Dairy',
    'Others',
  ];

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Location services are disabled. Please enable the services')),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.locality}, ${place.administrativeArea}';
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _addAuctionItem() async {
    setState(() => _isUploading = true);

    try {
      final String name = _nameController.text;
      final String description = _descriptionController.text;
      final String location = _locationController.text;
      final int quantity = int.tryParse(_quantityController.text) ?? 0;
      final double startingBid =
          double.tryParse(_startingBidController.text) ?? 0.0;
      final String otherCategoryDescription =
          _selectedCategory == 'Others' ? _otherCategoryController.text : '';

      final int durationHours = int.tryParse(_durationController.text) ?? 12;
      _auctionDuration = Duration(hours: durationHours);

      if (name.isNotEmpty &&
          description.isNotEmpty &&
          location.isNotEmpty &&
          quantity > 0 &&
          startingBid > 0) {
        List<String> imageUrls = await _uploadImages();

        final User? user = FirebaseAuth.instance.currentUser;
        final String sellerId = user?.uid ?? 'unknown_user';
        final String sellerName = user?.displayName ?? 'Unknown';

        final newItem = AuctionItem(
          id: '',
          name: name,
          description: description,
          location: location,
          quantity: quantity,
          category: _selectedCategory,
          otherCategoryDescription: otherCategoryDescription,
          startingBid: startingBid,
          currentBid: startingBid,
          sellerId: sellerId,
          sellerName: sellerName,
          bids: [],
          endTime: DateTime.now().add(_auctionDuration),
          status: AuctionStatus.upcoming,
          images: imageUrls,
        );

        await _auctionService.addAuctionItem(newItem);

        if (widget.preAuctionId != null) {
          await FirebaseFirestore.instance
              .collection('pre_auction_listings')
              .doc(widget.preAuctionId)
              .update({'isListed': true});
        }

        Navigator.pop(context);
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _selectedImages) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('auction_images')
          .child(fileName);

      await ref.putFile(image);
      String downloadUrl = await ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    return imageUrls;
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add_photo_alternate, size: 40),
                ),
              ),
            );
          }
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.preAuctionData != null) {
      _nameController.text = widget.preAuctionData!['productName'] ?? '';
      _descriptionController.text = widget.preAuctionData!['description'] ?? '';
      _locationController.text = widget.preAuctionData!['location'] ?? '';
      _quantityController.text =
          widget.preAuctionData!['estimatedQuantity'].toString();
      _selectedCategory = widget.preAuctionData!['category'] ?? 'Vegetables';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _startingBidController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Auction Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // _buildImagePreview(),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                suffixIcon: IconButton(
                  icon: _isLoadingLocation
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                ),
              ),
            ),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _startingBidController,
              decoration: InputDecoration(labelText: 'Starting Bid'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _durationController,
              decoration: InputDecoration(
                  labelText: 'Auction Duration (hours, default 12)'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              items: categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            if (_selectedCategory == 'Others')
              TextField(
                controller: _otherCategoryController,
                decoration:
                    InputDecoration(labelText: 'Describe Other Category'),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _addAuctionItem,
              child: _isUploading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Uploading...'),
                      ],
                    )
                  : Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}
