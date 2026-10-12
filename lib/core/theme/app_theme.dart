import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const yellow = Color(0xFFF5CB58);
  static const yellowTwo = Color(0xFFF3E9B5);
  static const orange = Color(0xFFD95F33);
  static const inputFill = Color(0xFFF1E7B9);
  static const surface = Color(0xFFF7F7F7);
  static const text = Color(0xFF3A1F14);
  static const peach = Color(0xFFFBDDCF);
  static const error = Color(0xFFB3261E);
}

const yellowStatusBar = SystemUiOverlayStyle(
  statusBarColor: AppColors.yellow,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
);

const lightStatusBar = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.orange)
      .copyWith(primary: AppColors.orange, onPrimary: Colors.white);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.orange,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(160, 44),
        shape: const StadiumBorder(),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
