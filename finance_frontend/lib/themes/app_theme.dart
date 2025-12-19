import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Add google_fonts to your pubspec.yaml

class AppTheme {
  // Define colors once to reuse them
  static const _primaryColor = Color(0xFF0A74DA);
  static const _secondaryColor = Color(0xFF00BFA6);
  static const _lightBackgroundColor = Color(0xFFF5F5F5);
  static const _darkBackgroundColor = Color(0xFF121212);
  static const _darkSurfaceColor = Color(0xFF1E1E1E);

  // --- Base Text Theme ---
  static final TextTheme _textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(fontSize: 57, fontWeight: FontWeight.w400),
    displayMedium: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
    labelMedium: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
  );

  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _lightBackgroundColor,
    textTheme: _textTheme.apply(bodyColor: Colors.black, displayColor: Colors.black),
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: Colors.white, // For components like Card, Dialog
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black, // Text/icons on components
      error: Color(0xFFB00020),
      onError: Colors.white,
    ),

    // --- Component Themes ---
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white, // Color for icons and text
      elevation: 2,
      titleTextStyle: _textTheme.headlineSmall?.copyWith(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
  );

  // --- Dark Theme ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _darkBackgroundColor,
    textTheme: _textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: _darkSurfaceColor, // For components like Card, Dialog
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white, // Text/icons on components
      error: Color(0xFFCF6679),
      onError: Colors.black,
    ),
    
    // --- Component Themes ---
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurfaceColor,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: _textTheme.headlineSmall?.copyWith(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _darkSurfaceColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _secondaryColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: _textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
  );
}