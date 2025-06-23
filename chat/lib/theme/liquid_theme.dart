import 'package:flutter/material.dart';

class LiquidTheme {
  // Liquid Color Palette
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryPink = Color(0xFFF7B2C1);
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color backgroundDark = Color(0xFF0F0F23);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color chatBubbleOutgoing = Color(0xFF3B82F6);
  static const Color chatBubbleIncoming = Color(0xFFF3F4F6);
  
  // Gradients
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B35),
      Color(0xFFF7B2C1),
      Color(0xFF3B82F6),
    ],
  );
  
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E3A8A),
      Color(0xFF3B82F6),
      Color(0xFF06B6D4),
    ],
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x40FFFFFF),
      Color(0x10FFFFFF),
    ],
  );
  
  // Animation Curves
  static const Curve liquidCurve = Curves.easeInOutCubic;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.bounceOut;
  
  // Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 800);
}