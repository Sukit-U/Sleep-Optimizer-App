import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// App theme configuration based on CompleteScreenSpecifications design system
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
        onSecondary: AppColors.foreground,
        secondaryContainer: AppColors.accentDark,
        onSecondaryContainer: AppColors.foreground,
        
        tertiary: AppColors.accent,
        onTertiary: AppColors.foreground,
        
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        
        surface: AppColors.background,
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
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.background,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h1.copyWith(
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.navLabel,
        unselectedLabelStyle: AppTypography.navLabel,
      ),
      
      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.navLabel.copyWith(color: AppColors.primary);
          }
          return AppTypography.navLabel.copyWith(color: AppColors.mutedForeground);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: AppSpacing.iconMd);
          }
          return const IconThemeData(color: AppColors.mutedForeground, size: AppSpacing.iconMd);
        }),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusXl,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: AppSpacing.buttonPadding,
          minimumSize: const Size(0, AppSpacing.inputHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusXl,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          padding: AppSpacing.buttonPadding,
          minimumSize: const Size(0, AppSpacing.inputHeight),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusXl,
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: AppSpacing.buttonPadding,
          textStyle: AppTypography.button,
        ),
      ),
      
      // Icon Buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.foreground,
          minimumSize: const Size(AppSpacing.iconButtonSize, AppSpacing.iconButtonSize),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusFull,
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
          borderRadius: AppSpacing.radiusXl,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusXl,
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusXl,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusXl,
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusXl,
          borderSide: const BorderSide(color: AppColors.destructive, width: 2),
        ),
        labelStyle: AppTypography.label.copyWith(color: AppColors.mutedForeground),
        hintStyle: AppTypography.body.copyWith(color: AppColors.mutedForeground),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.destructive),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
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
            return AppColors.primary.withOpacity(0.5);
          }
          return AppColors.muted;
        }),
      ),
      
      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.muted,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x298479F5),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.muted,
        circularTrackColor: AppColors.muted,
      ),
      
      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.muted,
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.foreground),
        actionTextColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusMd,
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusXl,
        ),
        titleTextStyle: AppTypography.h2.copyWith(color: AppColors.foreground),
        contentTextStyle: AppTypography.body.copyWith(color: AppColors.mutedForeground),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.defaultSpacing),
        tileColor: Colors.transparent,
        textColor: AppColors.foreground,
        iconColor: AppColors.mutedForeground,
        titleTextStyle: AppTypography.body.copyWith(color: AppColors.foreground),
        subtitleTextStyle: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.foreground),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.foreground),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.foreground),
        headlineLarge: AppTypography.h1.copyWith(color: AppColors.foreground),
        headlineMedium: AppTypography.h2.copyWith(color: AppColors.foreground),
        headlineSmall: AppTypography.h3.copyWith(color: AppColors.foreground),
        titleLarge: AppTypography.h3.copyWith(color: AppColors.foreground),
        titleMedium: AppTypography.h4.copyWith(color: AppColors.foreground),
        titleSmall: AppTypography.label.copyWith(color: AppColors.foreground),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.foreground),
        bodyMedium: AppTypography.body.copyWith(color: AppColors.foreground),
        bodySmall: AppTypography.caption.copyWith(color: AppColors.mutedForeground),
        labelLarge: AppTypography.button.copyWith(color: AppColors.foreground),
        labelMedium: AppTypography.labelSmall.copyWith(color: AppColors.foreground),
        labelSmall: AppTypography.small.copyWith(color: AppColors.mutedForeground),
      ),
    );
  }

  // === LIGHT THEME (Future support) ===
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.accent,
        onSecondary: AppColors.foreground,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightForeground,
        surfaceContainerHighest: AppColors.lightMuted,
        onSurfaceVariant: AppColors.mutedForeground,
        outline: AppColors.lightBorder,
      ),
      
      scaffoldBackgroundColor: AppColors.lightBackground,
      
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightForeground,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusXl,
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          elevation: 0,
          padding: AppSpacing.buttonPadding,
          minimumSize: const Size(0, AppSpacing.inputHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusXl,
          ),
        ),
      ),
    );
  }
}