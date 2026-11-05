import 'package:flutter/material.dart';

class AppTheme {
  // اللون الأساسي للأخضر المميز لحانوتي: #2f9e5f
  static const Color primary = Color(0xFF2F9E5F);
  static const Color primaryDark = Color(0xFF247D4B);
  static const Color primaryLight = Color(0xFFE8F5EE);

  static const Color background = Color(0xFFF9FAFB);
  static const Color cardColor = Colors.white;
  static const Color textMain = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // ألوان الحالات
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Tajawal',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: background,
      surfaceContainerLowest: cardColor,
      error: danger,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textMain,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
  );
}

// ثوابت النصوص وتنسيق الدرهم المغربي
String formatMAD(double n) {
  return '${n.toStringAsFixed(2)} د.م';
}

String formatQty(double qty, String unitType) {
  if (unitType == 'KILO') {
    return '${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)} كغ';
  } else if (unitType == 'LITER') {
    return '${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)} لتر';
  }
  return '${qty.toInt()} حبة';
}

String unitLabel(String unitType) {
  if (unitType == 'KILO') return 'كيلو';
  if (unitType == 'LITER') return 'لتر';
  return 'حبة';
}
