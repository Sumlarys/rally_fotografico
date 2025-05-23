// lib/utils/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  // Primary palette
  primaryColor: const Color(0xFF6A1B9A),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.deepPurple,
  ).copyWith(
    primary: const Color(0xFF6A1B9A),
    secondary: const Color(0xFFAB47BC),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
  ),

  // Typography
  textTheme: TextTheme(
    titleLarge: GoogleFonts.robotoSlab(
      fontSize: 28, fontWeight: FontWeight.bold,
    ),
    titleMedium: GoogleFonts.robotoSlab(
      fontSize: 20, fontWeight: FontWeight.w600,
    ),
    bodyMedium: GoogleFonts.openSans(
      fontSize: 16, fontWeight: FontWeight.normal,
    ),
    labelLarge: GoogleFonts.openSans(
      fontSize: 18, fontWeight: FontWeight.w600,
    ),
  ),

  // TextField borders all purple
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF6A1B9A), // purple border when idle
        width: 1.5,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF6A1B9A), // same purple when focused
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.red.shade700,
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Colors.red.shade700,
        width: 2,
      ),
    ),
    labelStyle: GoogleFonts.openSans(
      color: Color(0xFF6A1B9A),
      fontWeight: FontWeight.w600,
    ),
  ),

  // Elevated buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6A1B9A),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: GoogleFonts.openSans(
        fontSize: 18, fontWeight: FontWeight.w600,
      ),
      elevation: 4,
    ),
  ),

  // Cards
  cardTheme: CardTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 4,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),

  iconTheme: const IconThemeData(size: 28),
  scaffoldBackgroundColor: Colors.grey[50],
);
