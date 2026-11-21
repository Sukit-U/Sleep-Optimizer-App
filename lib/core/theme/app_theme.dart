import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// App theme configuration based on Lovable design system
/// Provides dark theme as default with light theme option
class AppTheme {
  AppTheme._();

  // === DARK THEME (Default) ===
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.primaryForeground,

        secondary: AppColors.accent,
        onSecondary: AppColors.primaryForeground,
        secondaryContainer: AppColors.accentDark,
        onSecondaryContainer: AppColors.primaryForeground,

        tertiary: AppColors.accent,
        onTertiary: AppColors.primaryForeground,

        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,

        surface: AppColors.card,
        onSurface: AppColors.foreground,

        surfaceContainerHighest: AppColors.muted,
        onSurfaceVariant: AppColors.mutedForeground,

        outline: AppColors.border,
        outlineVariant: AppColors.border,

        shadow: AppColors.shadow,
        scrim: AppColors.overlay,

        inverseSurface: AppColors.foreground,
        onInverseSurface: AppColors.background,
        inversePrimary: AppColors.primaryDark,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.h1.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.foreground,
          size: AppSpacing.iconLg,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.karla(
          fontSize: AppTypography.navLabel.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: GoogleFonts.karla(
          fontSize: AppTypography.navLabel.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedForeground,
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.karla(
              fontSize: AppTypography.navLabel.fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.karla(
            fontSize: AppTypography.navLabel.fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: AppSpacing.iconMd,
            );
          }
          return const IconThemeData(
            color: AppColors.mutedForeground,
            size: AppSpacing.iconMd,
          );
        }),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chips (SQI ratings): selection is a moonlight-blue fill with dark text.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.muted,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.mutedBackground,
        labelStyle: GoogleFonts.karla(
          fontSize: 14,
          color: AppColors.foreground,
        ),
        secondaryLabelStyle: GoogleFonts.karla(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryForeground,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: EdgeInsets.all(AppSpacing.buttonPadding),
          minimumSize: const Size(0, AppSpacing.inputHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          textStyle: GoogleFonts.karla(
            fontSize: AppTypography.button.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          padding: EdgeInsets.all(AppSpacing.buttonPadding),
          minimumSize: const Size(0, AppSpacing.inputHeight),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          textStyle: GoogleFonts.karla(
            fontSize: AppTypography.button.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: EdgeInsets.all(AppSpacing.buttonPadding),
          textStyle: GoogleFonts.karla(
            fontSize: AppTypography.button.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.foreground,
          minimumSize: const Size(
            AppSpacing.iconButtonSize,
            AppSpacing.iconButtonSize,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.defaultSpacing,
          vertical: AppSpacing.defaultSpacing,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.destructive, width: 2),
        ),
        labelStyle: GoogleFonts.karla(
          fontSize: AppTypography.label.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedForeground,
        ),
        hintStyle: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedForeground,
        ),
        errorStyle: GoogleFonts.karla(
          fontSize: AppTypography.caption.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.destructive,
        ),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.primaryForeground),
        side: const BorderSide(color: AppColors.border, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.mutedForeground;
        }),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.mutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return AppColors.muted;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.muted,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.16),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.muted,
        circularTrackColor: AppColors.muted,
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.foreground,
        ),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.h2.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        contentTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedForeground,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        modalBackgroundColor: AppColors.card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.roundedXl),
            topRight: Radius.circular(AppSpacing.roundedXl),
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.defaultSpacing,
        ),
        tileColor: Colors.transparent,
        textColor: AppColors.foreground,
        iconColor: AppColors.mutedForeground,
        titleTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.foreground,
        ),
        subtitleTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.caption.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedForeground,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.karla(
          fontSize: AppTypography.displayLarge.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        displayMedium: GoogleFonts.karla(
          fontSize: AppTypography.displayMedium.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        displaySmall: GoogleFonts.karla(
          fontSize: AppTypography.displaySmall.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        headlineLarge: GoogleFonts.karla(
          fontSize: AppTypography.h1.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        headlineMedium: GoogleFonts.karla(
          fontSize: AppTypography.h2.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        headlineSmall: GoogleFonts.karla(
          fontSize: AppTypography.h3.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        titleLarge: GoogleFonts.karla(
          fontSize: AppTypography.h3.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        titleMedium: GoogleFonts.karla(
          fontSize: AppTypography.h4.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        titleSmall: GoogleFonts.karla(
          fontSize: AppTypography.label.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        bodyLarge: GoogleFonts.karla(
          fontSize: AppTypography.bodyLarge.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.foreground,
        ),
        bodyMedium: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.foreground,
        ),
        bodySmall: GoogleFonts.karla(
          fontSize: AppTypography.caption.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedForeground,
        ),
        labelLarge: GoogleFonts.karla(
          fontSize: AppTypography.button.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        labelMedium: GoogleFonts.karla(
          fontSize: AppTypography.labelSmall.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        labelSmall: GoogleFonts.karla(
          fontSize: AppTypography.small.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }

  // === LIGHT THEME ===
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightPrimaryForeground,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.lightForeground,

        secondary: AppColors.lightAccent,
        onSecondary: AppColors.lightOnSecondary,
        secondaryContainer: AppColors.accentLight,
        onSecondaryContainer: AppColors.lightForeground,

        tertiary: AppColors.lightAccent,
        onTertiary: AppColors.lightForeground,

        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,

        surface: AppColors.lightCard,
        onSurface: AppColors.lightForeground,

        surfaceContainerHighest: AppColors.lightMuted,
        onSurfaceVariant: AppColors.lightMutedForeground,

        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightBorder,

        shadow: AppColors.shadow,
        scrim: AppColors.overlayLight,

        inverseSurface: AppColors.background,
        onInverseSurface: AppColors.foreground,
        inversePrimary: AppColors.primaryLight,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.h1.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.lightForeground,
          size: AppSpacing.iconLg,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.karla(
          fontSize: AppTypography.navLabel.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightPrimary,
        ),
        unselectedLabelStyle: GoogleFonts.karla(
          fontSize: AppTypography.navLabel.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightMutedForeground,
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightBackground,
        indicatorColor: AppColors.lightPrimary.withValues(alpha: 0.15),
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.karla(
              fontSize: AppTypography.navLabel.fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.lightPrimary,
            );
          }
          return GoogleFonts.karla(
            fontSize: AppTypography.navLabel.fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.lightMutedForeground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.lightPrimary,
              size: AppSpacing.iconMd,
            );
          }
          return const IconThemeData(
            color: AppColors.lightMutedForeground,
            size: AppSpacing.iconMd,
          );
        }),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightMuted,
        selectedColor: AppColors.lightPrimary,
        disabledColor: AppColors.lightMuted,
        labelStyle: GoogleFonts.karla(
          fontSize: 14,
          color: AppColors.lightForeground,
        ),
        secondaryLabelStyle: GoogleFonts.karla(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.lightPrimaryForeground,
        ),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightPrimaryForeground,
          elevation: 0,
          padding: EdgeInsets.all(AppSpacing.buttonPadding),
          minimumSize: const Size(0, AppSpacing.inputHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          textStyle: GoogleFonts.karla(
            fontSize: AppTypography.button.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightForeground,
          padding: EdgeInsets.all(AppSpacing.buttonPadding),
          minimumSize: const Size(0, AppSpacing.inputHeight),
          side: const BorderSide(color: AppColors.lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          textStyle: GoogleFonts.karla(
            fontSize: AppTypography.button.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          padding: EdgeInsets.all(AppSpacing.buttonPadding),
          textStyle: GoogleFonts.karla(
            fontSize: AppTypography.button.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Icon Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.lightForeground,
          minimumSize: const Size(
            AppSpacing.iconButtonSize,
            AppSpacing.iconButtonSize,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.lightPrimaryForeground,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.defaultSpacing,
          vertical: AppSpacing.defaultSpacing,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.destructive, width: 2),
        ),
        labelStyle: GoogleFonts.karla(
          fontSize: AppTypography.label.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightMutedForeground,
        ),
        hintStyle: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightMutedForeground,
        ),
        errorStyle: GoogleFonts.karla(
          fontSize: AppTypography.caption.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.destructive,
        ),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.lightPrimaryForeground),
        side: const BorderSide(color: AppColors.lightBorder, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightPrimary;
          }
          return AppColors.lightMutedForeground;
        }),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightPrimary;
          }
          return AppColors.lightMutedForeground;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightPrimary.withValues(alpha: 0.5);
          }
          return AppColors.lightMuted;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.lightPrimary,
        inactiveTrackColor: AppColors.lightMuted,
        thumbColor: AppColors.lightPrimary,
        overlayColor: AppColors.lightPrimary.withValues(alpha: 0.16),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lightPrimary,
        linearTrackColor: AppColors.lightMuted,
        circularTrackColor: AppColors.lightMuted,
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightForeground,
        contentTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightBackground,
        ),
        actionTextColor: AppColors.lightPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.h2.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        contentTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightMutedForeground,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightCard,
        modalBackgroundColor: AppColors.lightCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.roundedXl),
            topRight: Radius.circular(AppSpacing.roundedXl),
          ),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.defaultSpacing,
        ),
        tileColor: Colors.transparent,
        textColor: AppColors.lightForeground,
        iconColor: AppColors.lightMutedForeground,
        titleTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightForeground,
        ),
        subtitleTextStyle: GoogleFonts.karla(
          fontSize: AppTypography.caption.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightMutedForeground,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.karla(
          fontSize: AppTypography.displayLarge.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        displayMedium: GoogleFonts.karla(
          fontSize: AppTypography.displayMedium.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        displaySmall: GoogleFonts.karla(
          fontSize: AppTypography.displaySmall.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        headlineLarge: GoogleFonts.karla(
          fontSize: AppTypography.h1.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        headlineMedium: GoogleFonts.karla(
          fontSize: AppTypography.h2.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        headlineSmall: GoogleFonts.karla(
          fontSize: AppTypography.h3.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        titleLarge: GoogleFonts.karla(
          fontSize: AppTypography.h3.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        titleMedium: GoogleFonts.karla(
          fontSize: AppTypography.h4.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        titleSmall: GoogleFonts.karla(
          fontSize: AppTypography.label.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        bodyLarge: GoogleFonts.karla(
          fontSize: AppTypography.bodyLarge.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightForeground,
        ),
        bodyMedium: GoogleFonts.karla(
          fontSize: AppTypography.body.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightForeground,
        ),
        bodySmall: GoogleFonts.karla(
          fontSize: AppTypography.caption.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightMutedForeground,
        ),
        labelLarge: GoogleFonts.karla(
          fontSize: AppTypography.button.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        labelMedium: GoogleFonts.karla(
          fontSize: AppTypography.labelSmall.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        labelSmall: GoogleFonts.karla(
          fontSize: AppTypography.small.fontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.lightMutedForeground,
        ),
      ),
    );
  }
}
