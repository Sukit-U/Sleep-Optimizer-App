import 'package:flutter/material.dart';

/// App color palette: a cool night sky rather than a warm room.
///
/// The dark theme is the default. Surfaces are deep blue-black, actions are
/// moonlight blue, and status colors are muted rather than saturated. The action
/// color is a fill: put dark text on it, and use the light theme's deeper
/// [lightPrimary] instead of it for small text on paper.
class AppColors {
  AppColors._();

  // === PRIMARY COLORS ===
  /// Moonlight blue - #7FA8E0
  static const Color primary = Color(0xFF7FA8E0);
  static const Color primaryLight = Color(0xFFA3C4F0);
  static const Color primaryDark = Color(0xFF5A82B8);

  /// Text on primary (deep night, not pure black)
  static const Color primaryForeground = Color(0xFF0A1220);

  // === ACCENT COLORS ===
  /// Cool horizon teal - #7BBFC2 (status, secondary emphasis)
  static const Color accent = Color(0xFF7BBFC2);
  static const Color secondary = Color(0xFF7BBFC2); // Material alias for accent
  static const Color accentLight = Color(0xFFA2D8DA);
  static const Color accentDark = Color(0xFF4E8D90);

  // === BACKGROUND COLORS ===
  /// Deep night blue - #0B1220
  static const Color background = Color(0xFF0B1220);

  /// Card/Surface background - #141C2A
  static const Color card = Color(0xFF141C2A);
  static const Color surface = Color(0xFF141C2A);
  static const Color surfaceElevated = Color(0xFF1D2738);

  // === FOREGROUND COLORS ===
  /// Primary text, cool off-white - #E7EDF6
  static const Color foreground = Color(0xFFE7EDF6);

  /// Muted foreground - #8FA0B7
  static const Color mutedForeground = Color(0xFF8FA0B7);

  // === MUTED COLORS ===
  /// Muted fill for tracks and dividers
  static const Color muted = Color(0xFF1A2333);
  static const Color mutedBackground = Color(0xFF0F1724);

  // === BORDER COLORS ===
  /// Hairline border - #283649
  static const Color border = Color(0xFF283649);

  // === STATUS COLORS ===
  static const Color success = Color(0xFF74C49E);
  static const Color successForeground = Color(0xFF08170F);

  static const Color warning = Color(0xFFD6B36A);
  static const Color warningForeground = Color(0xFF17120A);

  /// Cool rose, not fire-engine red
  static const Color destructive = Color(0xFFE18D95);
  static const Color destructiveForeground = Color(0xFF1E0F12);

  // === SHADOW COLORS ===
  /// Shadows are restrained: separation comes from surface color and borders.
  static const Color shadow = Color(0x33000000);

  // === INPUT COLORS ===
  static const Color inputBackground = Color(0xFF0F1725);
  static const Color inputBorder = Color(0xFF283649);
  static const Color inputFocusBorder = primary;

  // === OVERLAY COLORS ===
  static const Color overlay = Color(0x99000000);
  static const Color overlayLight = Color(0x40000000);

  // === LIGHT THEME VARIANTS ===
  /// Cool paper, not pure white
  static const Color lightBackground = Color(0xFFEDF1F7);
  static const Color lightForeground = Color(0xFF16202E);
  static const Color lightCard = Color(0xFFFBFCFE);
  static const Color lightBorder = Color(0xFFD6DEE9);
  static const Color lightMuted = Color(0xFFE6EBF3);

  static const Color lightMutedForeground = Color(0xFF5B6878);

  /// Accent for paper: the moonlight teal is too pale for icons on white.
  static const Color lightAccent = Color(0xFF3F8A8D);

  /// Deeper action blue for paper: [primary] is too pale for small text there.
  static const Color lightPrimary = Color(0xFF2A5C9E);
  static const Color lightPrimaryForeground = Color(0xFFF7FAFF);

  static const Color lightOnSecondary = Color(0xFF101821);
}
