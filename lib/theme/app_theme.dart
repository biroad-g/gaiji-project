import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 古字アルバム カラーパレット（藍 × 金 × 生成り）
class AppColors {
  static const indigo = Color(0xFF1E2A47);
  static const indigoDeep = Color(0xFF131B2E);
  static const indigoSoft = Color(0xFF2C3C61);
  static const gold = Color(0xFFC7A24C);
  static const goldSoft = Color(0xFFE3CE96);
  static const kinari = Color(0xFFF6F3EA);
  static const paper = Color(0xFFFDFBF4);
  static const ink = Color(0xFF1B1B1B);
  static const inkSoft = Color(0xFF5F5B52);
  static const inkFaint = Color(0xFF9A9488);
  static const line = Color(0xFFE2DCCC);
  static const shu = Color(0xFFB04A32);
}

class AppTheme {
  static const fontSans = 'NotoSansJP';
  static const fontSerif = 'NotoSerifJP';

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.kinari,
      fontFamily: fontSans,
      colorScheme: const ColorScheme.light(
        primary: AppColors.indigo,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.indigoDeep,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        error: AppColors.shu,
      ),
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: fontSerif,
          fontSize: 19,
          letterSpacing: 2.0,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
            color: AppColors.inkSoft, fontSize: 13, letterSpacing: 0.5),
        hintStyle: const TextStyle(color: AppColors.inkFaint, fontSize: 14),
        floatingLabelStyle: const TextStyle(
            color: AppColors.indigo, fontSize: 13, letterSpacing: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: fontSans,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.indigo,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.line, width: 1.2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontFamily: fontSans,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.indigo,
          textStyle: const TextStyle(fontFamily: fontSans, fontSize: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.indigoDeep,
        contentTextStyle: const TextStyle(
            fontFamily: fontSans, color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme:
          const DividerThemeData(color: AppColors.line, thickness: 1),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: const TextStyle(
          fontFamily: fontSerif,
          fontSize: 34,
          color: AppColors.ink,
          letterSpacing: 4,
          fontWeight: FontWeight.w600),
      headlineMedium: const TextStyle(
          fontFamily: fontSerif,
          fontSize: 24,
          color: AppColors.ink,
          letterSpacing: 2,
          fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(
          fontFamily: fontSerif,
          fontSize: 18,
          color: AppColors.ink,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(
          fontFamily: fontSans,
          fontSize: 15,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5),
      bodyMedium: const TextStyle(
          fontFamily: fontSans,
          fontSize: 14,
          color: AppColors.ink,
          height: 1.7),
      bodySmall: const TextStyle(
          fontFamily: fontSans,
          fontSize: 12,
          color: AppColors.inkSoft,
          height: 1.6),
      labelLarge: const TextStyle(
          fontFamily: fontSans,
          fontSize: 13,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600),
    );
  }
}
