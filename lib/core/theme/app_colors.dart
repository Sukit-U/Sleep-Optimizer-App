import 'package:flutter/material.dart';

/// App color palette based on CompleteScreenSpecifications design system
/// Dark theme with purple accent (#8479F5) and teal accent (#4fc3b8)
class AppColors {
  AppColors._();

  // === PRIMARY COLORS ===
  /// Primary purple accent - #8479F5
  static const Color primary = Color(0xFF8479F5);
  static const Color primaryLight = Color(0xFFA89CF5);
  static const Color primaryDark = Color(0xFF6B5FD9);
  
  /// Primary foreground (text on primary)
  static const Color primaryForeground = Color(0xFFFAFAFA);

  // === ACCENT COLORS ===
  /// Teal accent - #4fc3b8
  static const Color accent = Color(0xFF4FC3B8);
  static const Color secondary = Color(0xFF4FC3B8); // Alias for accent (Material Design compatibility)
  static const Color accentLight = Color(0xFF7DD3CB);
  static const Color accentDark = Color(0xFF3BA89F);

  // === BACKGROUND COLORS ===
  /// Dark background - #1a1a1a (oklch 0.145)
  static const Color background = Color(0xFF1A1A1A);
  static const Color backgroundLight = Color(0xFF242424);
  
  /// Card background (same as background for dark theme)
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardLight = Color(0xFF242424);

  // === FOREGROUND COLORS ===
  /// Primary text color - #fafafa
  static const Color foreground = Color(0xFFFAFAFA);
  static const Color foregroundMuted = Color(0xFFB0B0B0);

  // === MUTED COLORS ===
  /// Muted background - oklch 0.269
  static const Color muted = Color(0xFF333333);
  static const Color mutedLight = Color(0xFF404040);
  
/// Muted foreground - oklch 0.708
  static const Color mutedForeground = Color(0xFFB0B0B0);
  /// Muted background - for progress bars, etc.
  static const Color mutedBackground = Color(0xFF2A2A2A);

  // === BORDER COLORS ===
  /// Border color - oklch 0.269
  static const Color border = Color(0xFF404040);
  static const Color borderLight = Color(0xFF505050);

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

  /// Info - Blue
  static const Color info = Color(0xFF60A5FA);
  static const Color infoForeground = Color(0xFFFFFFFF);

  // === CHART COLORS ===
  static const Color chart1 = Color(0xFF8479F5); // Purple
  static const Color chart2 = Color(0xFF4FC3B8); // Teal
  static const Color chart3 = Color(0xFF4ADE80); // Green
  static const Color chart4 = Color(0xFFFBBF24); // Yellow
  static const Color chart5 = Color(0xFF60A5FA); // Blue

  // === GRADIENT COLORS ===
  /// Splash screen gradient
  static const Color gradientStart = Color(0xFF1A1A2E);
  static const Color gradientEnd = Color(0xFF16213E);

  /// Primary glow effect
  static const Color primaryGlow = Color(0xFF8479F5);
  
  /// Moon glow effect
  static const Color moonGlow = Color(0xFF8479F5);

  // === SHADOW COLORS ===
  static const Color shadow = Color(0x40000000);
  static const Color shadowLight = Color(0x20000000);

  // === INPUT COLORS ===
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color inputBorder = Color(0xFF404040);
  static const Color inputFocusBorder = primary;

  // === OVERLAY COLORS ===
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);

  // === RING COLOR ===
  static const Color ring = Color(0xFF6B6B6B);

  // === LIGHT THEME VARIANTS ===
  // For future light theme support
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(0xFF1A1A1A);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightMuted = Color(0xFFF5F5F5);
}