import 'package:flutter/material.dart';

class AppColors {
  static const base = Color(0xFFF7F3EE);
  static const surface = Color(0xFFFCF7F1);
  static const surfaceMuted = Color(0xFFF1E8DD);
  static const ink = Color(0xFF1E1B18);
  static const inkMuted = Color(0xFF5F564E);
  static const accent = Color(0xFF1C7C7C);
  static const accentWarm = Color(0xFFE5724E);
  static const accentCool = Color(0xFF1A5D7A);
  static const border = Color(0xFFE2D7C7);
  static const success = Color(0xFF3A9D6B);
  static const warning = Color(0xFFB07219);
  static const danger = Color(0xFFD04A4A);
}

class AppRadii {
  static const double large = 28;
  static const double medium = 18;
  static const double small = 12;
}

class AppShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 12),
    ),
  ];

  static const tight = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 6),
    ),
  ];
}
