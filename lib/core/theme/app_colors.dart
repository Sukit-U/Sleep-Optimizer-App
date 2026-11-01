import 'package:flutter/material.dart';

/// App color palette based on CompleteScreenSpecifications design system
/// Dark theme with periwinkle blue primary (#6E9EF5) and muted purple accent (#C47FD9)
class AppColors {
  AppColors._();

  // === PRIMARY COLORS ===
  /// Primary periwinkle blue - #6E9EF5 (oklch 0.7 0.16 245)
  static const Color primary = Color(0xFF6E9EF5);
  static const Color primaryLight = Color(0xFF87B4F7);
  static const Color primaryDark = Color(0xFF587DD9);

  /// Primary foreground (text on primary)
  static const Color primaryForeground = Color(0xFFFAFAFA);

  // === ACCENT COLORS ===
  /// Muted purple accent - #C47FD9 (oklch 0.68 0.18 300)
  static const Color accent = Color(0xFFC47FD9);
  static const Color secondary = Color(0xFFC47FD9); // Alias for accent (Material Design compatibility)
  static const Color accentLight = Color(0xFFD694E4);
  static const Color accentDark = Color(0xFFA664BB);

  // === BACKGROUND COLORS ===
  /// Dark background - #252830 (oklch 0.18 0.008 260)
  static const Color background = Color(0xFF252830);
  static const Color backgroundLight = Color(0xFF30333D); // This is the new card/surface color

  /// Card/Surface background - #30333D (oklch 0.235 0.01 260)
  static const Color card = Color(0xFF30333D);
  static const Color surface = Color(0xFF30333D);
  static const Color surfaceElevated = Color(0xFF3B3E4A); // Slightly lighter for elevated surfaces

  // === FOREGROUND COLORS ===
  /// Primary text color - #fafafa
  static const Color foreground = Color(0xFFFAFAFA);
  /// Muted foreground - #AEB2BE (oklch 0.74 0.02 260)
  static const Color mutedForeground = Color(0xFFAEB2BE);

  // === MUTED COLORS ===
  /// Muted background - for progress bars, etc.
  static const Color muted = Color(0xFF333333); // Keep as a general muted, though design might specify a background for it.
  static const Color mutedLight = Color(0xFF404040); // Keep for consistency if needed.
  static const Color mutedBackground = Color(0xFF2A2A2A); // Keep for consistency if needed.

  // === BORDER COLORS ===
  /// Border color - #454850 (oklch 0.32 0.012 260)
  static const Color border = Color(0xFF454850);
  static const Color borderLight = Color(0xFF505058);

  // === STATUS COLORS ===
  /// Success - Green
  static const Color success = Color(0xFF4ADE80);
  static const Color successForeground = Color(0xFFFFFFFF);

  /// Warning - Orange/Yellow
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningForeground = Color(0xFF1A1A1A);

  /// Error/Destructive - Red
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFFFFFF);

  /// Info - Blue (often same as primary for informational purposes)
  static const Color info = Color(0xFF60A5FA);
  static const Color infoForeground = Color(0xFFFFFFFF);

  // === CHART COLORS ===
  static const Color chart1 = Color(0xFF6E9EF5); // Primary Blue
  static const Color chart2 = Color(0xFFC47FD9); // Accent Purple
  static const Color chart3 = Color(0xFF4ADE80); // Success Green
  static const Color chart4 = Color(0xFFFBBF24); // Warning Yellow
  static const Color chart5 = Color(0xFF60A5FA); // Info Blue

  // === GRADIENT COLORS ===
  /// Ambient orb purple for background
  static const Color orbPurple = Color(0xFF6E9EF5); // Primary color for orb effect
  /// Ambient orb blue for background
  static const Color orbBlue = Color(0xFFC47FD9); // Accent color for orb effect

  // === Primary glow effect
  static const Color primaryGlow = Color(0xFF6E9EF5);
   
  /// Moon icon color
  static const Color moon = Color(0xFFFAFAFA); // White for Moon icon
  /// Star icon color
  static const Color star = Color(0xFFFBBF24); // Yellow for Star/Sparkle icon

  // === SHADOW COLORS ===
  static const Color shadow = Color(0x40000000);
  static const Color shadowLight = Color(0x20000000);

  // === INPUT COLORS ===
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color inputBorder = Color(0xFF454850); // Use new border color
  static const Color inputFocusBorder = primary;

  // === OVERLAY COLORS ===
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // === RING COLOR ===
  static const Color ring = Color(0xFF6E9EF5); // Use primary for ring as per Lovable

  // === LIGHT THEME VARIANTS ===
  // For future light theme support
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(0xFF1A1A1A);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightMuted = Color(0xFFF5F5F5);
  /// Light muted foreground - medium gray for light theme
  static const Color lightMutedForeground = Color(0xFF6B7280);
  /// Light on-secondary - dark text on purple accent
  static const Color lightOnSecondary = Color(0xFF1A1A1A);
}