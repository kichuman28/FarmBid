import 'package:flutter/material.dart';
import 'package:FarmBid/tutorial/tutorial_overlay.dart';

class AuctionPageTutorial {
  static List<TutorialStep> getSteps(BuildContext context, List<GlobalKey> keys) {
    return [
      TutorialStep(
        title: 'Welcome to FarmBid Market',
        description: 'Here you can browse, manage, and participate in auctions',
        position: _getWidgetPosition(keys[0]),
        size: _getWidgetSize(keys[0]),
      ),
      TutorialStep(
        title: 'Available Auctions', 
        description: 'Browse and bid on available farm produce auctions',
        position: _getWidgetPosition(keys[1]) - const Offset(0, 50),
        size: _getWidgetSize(keys[1]),
      ),
      TutorialStep(
        title: 'My Auctions',
        description: 'View and manage the auctions you\'ve created',
        position: _getWidgetPosition(keys[2]) - const Offset(0, 50),
        size: _getWidgetSize(keys[2]),
      ),
      TutorialStep(
        title: 'Won Auctions',
        description: 'Track the auctions you\'ve won and get seller locations',
        position: _getWidgetPosition(keys[3]) - const Offset(0, 50),
        size: _getWidgetSize(keys[3]),
      ),
      TutorialStep(
        title: 'Create Auction',
        description: 'Click here to list your produce for auction',
        position: _getWidgetPosition(keys[4]) - const Offset(0, 50),
        size: _getWidgetSize(keys[4]),
      ),
    ];
  }

  static Offset _getWidgetPosition(GlobalKey key) {
    final RenderBox renderBox = key.currentContext?.findRenderObject() as RenderBox;
    return renderBox.localToGlobal(Offset.zero);
  }

  static Size _getWidgetSize(GlobalKey key) {
    final RenderBox renderBox = key.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size;
  }
}
