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
      // Note: For gradient background, we'll use a decorator in the Scaffold itself
      // The theme provides the colors, but the gradient is applied in the widget tree
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.sora(
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
        backgroundColor: Colors.transparent, // Floating pill style will be custom, so transparent here.
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: AppTypography.navLabel.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: AppTypography.navLabel.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedForeground,
        ),
      ),

      // Navigation Bar (Material 3) - this is for larger screens, we'll focus on BottomNavigationBar for mobile
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: AppTypography.navLabel.fontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: AppTypography.navLabel.fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          );
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
          borderRadius: BorderRadius.circular(AppSpacing.radius2xl), // Using radius-2xl = 24px
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

// Elevated Buttons
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.primaryForeground,
    elevation: 0, // Lovable design has subtle shadow, handled by custom widget if needed
    padding: EdgeInsets.all(AppSpacing.buttonPadding),
    minimumSize: const Size(0, AppSpacing.inputHeight),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
    ),
    textStyle: GoogleFonts.sora(
      fontSize: AppTypography.button.fontSize,
      fontWeight: FontWeight.w600,
    ),
  ),
),

// Outlined Buttons (btn-ghost in Lovable uses border)
outlinedButtonTheme: OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.foreground,
    padding: EdgeInsets.all(AppSpacing.buttonPadding),
    minimumSize: const Size(0, AppSpacing.inputHeight),
    side: const BorderSide(color: AppColors.border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill), // Pill-shaped
    ),
    textStyle: GoogleFonts.sora(
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
    textStyle: GoogleFonts.sora(
      fontSize: AppTypography.button.fontSize,
      fontWeight: FontWeight.w600,
    ),
  ),
),

// Icon Buttons
iconButtonTheme: IconButtonThemeData(
  style: IconButton.styleFrom(
    foregroundColor: AppColors.foreground,
    minimumSize: const Size(AppSpacing.iconButtonSize, AppSpacing.iconButtonSize),
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
    borderRadius: BorderRadius.circular(AppSpacing.radiusXl), // rounded-xl for inputs
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
  labelStyle: GoogleFonts.inter(
    fontSize: AppTypography.label.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedForeground,
  ),
  hintStyle: GoogleFonts.inter(
    fontSize: AppTypography.body.fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  ),
  errorStyle: GoogleFonts.inter(
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
  overlayColor: Color(0x296E9EF5), // Using the new primary color for overlay
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
  contentTextStyle: GoogleFonts.inter(
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
  titleTextStyle: GoogleFonts.sora(
    fontSize: AppTypography.h2.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  contentTextStyle: GoogleFonts.inter(
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
  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.defaultSpacing),
  tileColor: Colors.transparent,
  textColor: AppColors.foreground,
  iconColor: AppColors.mutedForeground,
  titleTextStyle: GoogleFonts.inter(
    fontSize: AppTypography.body.fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
  ),
  subtitleTextStyle: GoogleFonts.inter(
    fontSize: AppTypography.caption.fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  ),
),

// Text Theme
textTheme: TextTheme(
  displayLarge: GoogleFonts.sora(
    fontSize: AppTypography.displayLarge.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  displayMedium: GoogleFonts.sora(
    fontSize: AppTypography.displayMedium.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  displaySmall: GoogleFonts.sora(
    fontSize: AppTypography.displaySmall.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  headlineLarge: GoogleFonts.sora(
    fontSize: AppTypography.h1.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  headlineMedium: GoogleFonts.sora(
    fontSize: AppTypography.h2.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  headlineSmall: GoogleFonts.sora(
    fontSize: AppTypography.h3.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  titleLarge: GoogleFonts.sora(
    fontSize: AppTypography.h3.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  titleMedium: GoogleFonts.sora(
    fontSize: AppTypography.h4.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  titleSmall: GoogleFonts.inter(
    fontSize: AppTypography.label.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  bodyLarge: GoogleFonts.inter(
    fontSize: AppTypography.bodyLarge.fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
  ),
  bodyMedium: GoogleFonts.inter(
    fontSize: AppTypography.body.fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
  ),
  bodySmall: GoogleFonts.inter(
    fontSize: AppTypography.caption.fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  ),
  labelLarge: GoogleFonts.sora(
    fontSize: AppTypography.button.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  labelMedium: GoogleFonts.inter(
    fontSize: AppTypography.labelSmall.fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  ),
  labelSmall: GoogleFonts.inter(
    fontSize: AppTypography.small.fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
  ),
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
        titleTextStyle: GoogleFonts.sora(
          fontSize: AppTypography.h1.fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),

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
    textStyle: GoogleFonts.sora(
            fontSize: AppTypography.button.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
