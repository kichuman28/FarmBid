import 'package:flutter/material.dart';
import 'package:FarmBid/tutorial/tutorial_overlay.dart';



class HomePageTutorial {
  static List<TutorialStep> getSteps(BuildContext context, List<GlobalKey> keys) {
    return [
      TutorialStep(
        title: 'Welcome to FarmBid',
        description: 'Let\'s take a quick tour of your dashboard',
        position: _getWidgetPosition(keys[0]) - const Offset(0, 50),
        size: _getWidgetSize(keys[0]),
      ),
      TutorialStep(
        title: 'Future Harvests',
        description: 'View and manage upcoming harvest listings',
        position: _getWidgetPosition(keys[1]),
        size: _getWidgetSize(keys[1]),
      ),
      TutorialStep(
        title: 'Your Posts',
        description: 'Track all your current listings and their status',
        position: _getWidgetPosition(keys[2]),
        size: _getWidgetSize(keys[2]),
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