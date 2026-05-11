import 'package:flutter/material.dart';

class AppColors {
  // Deep Backgrounds
  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF151B23);
  
  // Neon Accents
  static const Color primary = Color(0xFF00D2FF); // Neon Blue
  static const Color accent = Color(0xFF9D50BB); // Purple
  static const Color success = Color(0xFF00F260); // Neon Green
  static const Color error = Color(0xFFFF4B2B); // Vibrant Red
  
  // Text
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  
  // Glassmorphism
  static Color glassBackground = Colors.white.withValues(alpha: 0.05);
  static Color glassBorder = Colors.white.withValues(alpha: 0.1);
  
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
