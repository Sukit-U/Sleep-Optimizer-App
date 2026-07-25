import 'package:flutter/material.dart';

/// App typography system based on CompleteScreenSpecifications design system
/// Uses Nunito for headers and DM Sans for body text
class AppTypography {
  AppTypography._();

  // === FONT FAMILIES ===
  // Note: Add these fonts to pubspec.yaml and download from Google Fonts
  static const String fontFamilyHeader = 'Nunito';
  static const String fontFamilyBody = 'DM Sans';
  
  // Fallback to system fonts if custom fonts not loaded
  static const List<String> fontFamilyHeaderFallback = ['Nunito', 'Segoe UI', 'sans-serif'];
  static const List<String> fontFamilyBodyFallback = ['DM Sans', 'Segoe UI', 'sans-serif'];

  // === DISPLAY STYLES (Large numbers, scores) ===
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilyHeader,
    fontFamilyFallback: fontFamilyHeaderFallback,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamilyHeader,
    fontFamilyFallback: fontFamilyHeaderFallback,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamilyHeader,
    fontFamilyFallback: fontFamilyHeaderFallback,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.25,
  );

  // === HEADING STYLES ===
  /// Screen titles - 20px, bold
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamilyHeader,
    fontFamilyFallback: fontFamilyHeaderFallback,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 1.3,
  );

  /// Section headers - 18px, semibold
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamilyHeader,
    fontFamilyFallback: fontFamilyHeaderFallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.35,
  );

  /// Subsection headers - 16px, semibold
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamilyHeader,
    fontFamilyFallback: fontFamilyHeaderFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Card titles - 15px, semibold
  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  // === BODY STYLES ===
  /// Primary body text - 14px, regular
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.01,
    height: 1.5,
  );

  /// Regular body text - 14px, regular
  static const TextStyle body = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.01,
    height: 1.5,
  );

  /// Secondary body text - 14px, medium
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01,
    height: 1.5,
  );

  // === LABEL STYLES ===
  /// Button text - 14px, semibold
  static const TextStyle button = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02,
    height: 1.2,
  );

  /// Input labels - 14px, medium
  static const TextStyle label = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.01,
    height: 1.4,
  );

  /// Small labels - 12px, medium
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02,
    height: 1.4,
  );

  // === CAPTION STYLES ===
  /// Secondary text, captions - 12px, regular
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.02,
    height: 1.4,
  );

  /// Secondary text, muted - 12px, regular
  static const TextStyle captionMuted = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.02,
    height: 1.4,
  );

  // === SMALL STYLES ===
  /// Smallest text, badges - 11px, medium
  static const TextStyle small = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.03,
    height: 1.4,
  );

  /// Monospace text (version numbers, etc.)
  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02,
    height: 1.4,
  );

  // === NAVIGATION STYLES ===
  /// Bottom nav labels - 10px, medium
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02,
    height: 1.2,
  );

  /// Tab labels - 12px, semibold
  static const TextStyle tabLabel = TextStyle(
    fontFamily: fontFamilyBody,
    fontFamilyFallback: fontFamilyBodyFallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.03,
    height: 1.2,
  );
}