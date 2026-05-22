import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // الألوان الرئيسية
  static const Color primaryColor = Color(0xFF00A77E);
  static const Color secondaryColor = Color(0xFFC9A84C);
  static const Color errorColor = Color(0xFFB00020);

  // ألوان مساعدة
  static const Color primaryLight = Color(0xFF00A77E);
  static const Color goldLight = Color(0xFFE2C06A);

  // ألوان الوضع الفاتح
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Colors.white;
  static const Color lightCardBg = Color(0xFFF8F9FA);

  // ألوان الوضع المظلم
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBg = Color(0xFF2C2C2C);

  static final TextTheme _baseTextTheme = GoogleFonts.cairoTextTheme().copyWith(
    bodyLarge: GoogleFonts.cairo(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
  );

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      backgroundColor: lightBackground,
      surfaceColor: lightSurface,
      cardBg: lightCardBg,
      textColor: Colors.black87,
      displayColor: Colors.black,
      appBarBg: Colors.white,
      inputFill: const Color(0xFFF5F5F5),
      dividerColor: Colors.grey[100]!,
      chipBg: Colors.grey[100]!,
      overlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      backgroundColor: darkBackground,
      surfaceColor: darkSurface,
      cardBg: darkCardBg,
      textColor: Colors.white70,
      displayColor: Colors.white,
      appBarBg: darkSurface,
      inputFill: const Color(0xFF2C2C2C),
      dividerColor: const Color(0xFF2C2C2C),
      chipBg: const Color(0xFF2C2C2C),
      overlayStyle: SystemUiOverlayStyle.light,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color cardBg,
    required Color textColor,
    required Color displayColor,
    required Color appBarBg,
    required Color inputFill,
    required Color dividerColor,
    required Color chipBg,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        brightness: brightness,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: textColor,
        displayColor: displayColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: GoogleFonts.cairo(
          color: isDark ? Colors.white : primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : primaryColor,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        elevation: isDark ? 0 : 2,
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surfaceColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
          fontWeight: FontWeight.normal,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3C3C3C) : Colors.grey[200]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3C3C3C) : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.cairo(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey,
        indicatorColor: primaryColor,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.cairo(),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
    );
  }
}