import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_styles.dart';

part 'app_theme_provider.g.dart';

@Riverpod(keepAlive: true)
ThemeData appTheme(Ref ref) {
  final base = ThemeData.light(useMaterial3: true);
  final conversationText =
      GoogleFonts.zenMaruGothicTextTheme(base.textTheme);
  final uiText = GoogleFonts.mPlusRounded1cTextTheme(base.textTheme);
  final systemText = GoogleFonts.kosugiMaruTextTheme(base.textTheme);

  return base.copyWith(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.accentWarm,
      onSecondary: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerLow: AppColors.surfaceMuted,
      outline: AppColors.border,
    ),
    scaffoldBackgroundColor: AppColors.base,
    textTheme: conversationText.copyWith(
      displayLarge: uiText.displayLarge?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.8,
        color: AppColors.ink,
      ),
      displayMedium: uiText.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.6,
        color: AppColors.ink,
      ),
      headlineLarge: uiText.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.4,
        color: AppColors.ink,
      ),
      titleLarge: uiText.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
      titleMedium: uiText.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.ink,
      ),
      bodyLarge: conversationText.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: AppColors.ink,
      ),
      bodyMedium: conversationText.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.45,
        color: AppColors.inkMuted,
      ),
      bodySmall: conversationText.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.4,
        color: AppColors.inkMuted,
      ),
      labelLarge: GoogleFonts.kosugiMaru(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.inkMuted,
      ),
      labelMedium: GoogleFonts.kosugiMaru(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.inkMuted,
      ),
      labelSmall: GoogleFonts.kosugiMaru(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.inkMuted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.ink,
      titleTextStyle: uiText.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: systemText.bodyMedium?.copyWith(
        color: AppColors.inkMuted,
      ),
      hintStyle: systemText.bodyMedium?.copyWith(
        color: AppColors.inkMuted.withValues(alpha: 0.7),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.small),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.small),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.small),
        borderSide: const BorderSide(
          color: AppColors.accent,
          width: 1.2,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentWarm,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: uiText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: uiText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.ink,
      unselectedItemColor: AppColors.inkMuted,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 24,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: conversationText.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
