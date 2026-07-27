import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const pitchGreen = Color(0xFF00A86B);
  static const darkGreen = Color(0xFF006B3F);
  static const lightGreen = Color(0xFFE8F5E9);

  static const football = Color(0xFF4CAF50);
  static const basketball = Color(0xFFFF9800);
  static const tennis = Color(0xFFFDD835);
  static const volleyball = Color(0xFF2196F3);
  static const padel = Color(0xFF9C27B0);

  static const darkBg = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkCard = Color(0xFF2C2C2C);

  static Color sportColor(String sportId) {
    return switch (sportId) {
      'football' => football,
      'basketball' => basketball,
      'tennis' => tennis,
      'volleyball' => volleyball,
      'padel' => padel,
      _ => pitchGreen,
    };
  }
}
