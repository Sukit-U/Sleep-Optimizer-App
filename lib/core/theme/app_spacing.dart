import 'package:flutter/material.dart';

/// App spacing system based on CompleteScreenSpecifications design system
/// Uses a consistent 4px base unit
class AppSpacing {
  AppSpacing._();

  // === BASE UNIT ===
  /// Base unit: 4px
  static const double unit = 4.0;

  // === SPACING SCALE ===
  /// Extra small - 4px
  static const double xs = 4.0;

  /// Small - 8px
  static const double sm = 8.0;

  /// Medium - 12px
  static const double md = 12.0;

  /// Default - 16px
  static const double defaultSpacing = 16.0;

  /// Large - 20px
  static const double lg = 20.0;

  /// Extra large - 24px
  static const double xl = 24.0;

  /// 2xl - 28px
  static const double xxl = 28.0;

  /// 3xl - 32px
  static const double xxxl = 32.0;

  /// 4xl - 40px
  static const double huge = 40.0;

  /// 5xl - 48px
  static const double massive = 48.0;

  // === SCREEN PADDING ===
  /// Horizontal padding for screens - 20px
  static const double px = 20.0;

  /// Vertical padding for screens - 16px
  static const double py = 16.0;

  /// Standard screen padding (horizontal + vertical combined)
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: px, vertical: py);

  /// Screen padding with safe area top
  static const EdgeInsets screenPaddingWithTop = EdgeInsets.only(left: px, right: px, top: py);

  // === COMPONENT SPACING ===
  /// Gap between elements in a container - 12px
  static const double gap = 12.0;

  /// Large gap - 16px
  static const double gapLg = 16.0;

  /// Small gap - 8px
  static const double gapSm = 8.0;

  // === CARD PADDING ===
  /// Standard card padding - 16px
  static const double cardPadding = 16.0;

  /// Card internal padding
  static const EdgeInsets cardPaddingAll = EdgeInsets.all(cardPadding);

  /// Card horizontal padding only
  static const EdgeInsets cardPaddingHorizontal = EdgeInsets.symmetric(horizontal: cardPadding);

  // === LIST SPACING ===
  /// Spacing between list items - 8px
  static const double listItemGap = 8.0;

  /// Spacing between sections - 24px
  static const double sectionGap = 24.0;

  // === BUTTON SPACING ===
  /// Button horizontal padding - 20px
  static const double buttonPaddingX = 20.0;

  /// Button vertical padding - 12px
  static const double buttonPaddingY = 12.0;

  /// Button internal padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: buttonPaddingX, vertical: buttonPaddingY);

  /// Icon button size - 40px (w-10, h-10)
  static const double iconButtonSize = 40.0;

  // === INPUT SPACING ===
  /// Input height - 56px (h-14)
  static const double inputHeight = 56.0;

  /// Input horizontal padding - 16px
  static const double inputPaddingX = 16.0;

  // === NAVIGATION SPACING ===
  /// Bottom nav height - 64px
  static const double bottomNavHeight = 64.0;

  /// Status bar area height - 48px
  static const double statusBarHeight = 48.0;

  /// App bar height - 56px
  static const double appBarHeight = 56.0;

  // === BORDER RADIUS ===
  /// Small radius - 8px
  static const double roundedSm = 8.0;

  /// Medium radius - 12px
  static const double roundedMd = 12.0;

  /// Large radius - 16px
  static const double roundedLg = 16.0;

  /// Extra large radius - 24px
  static const double roundedXl = 24.0;

  /// 3xl radius - 32px
  static const double rounded3xl = 32.0;

  /// Full radius (pills, circles) - 9999px
static const double roundedFull = 9999.0;
static const double rounded2xl = 48; // Add radius2xl
static const double xxs = 2; // Add xxs spacing

  /// Common BorderRadius values
  static final BorderRadius radiusSm = BorderRadius.circular(roundedSm);
  static final BorderRadius radiusMd = BorderRadius.circular(roundedMd);
  static final BorderRadius radiusLg = BorderRadius.circular(roundedLg);
  static final BorderRadius radiusXl = BorderRadius.circular(roundedXl);
  static final BorderRadius radius3xl = BorderRadius.circular(rounded3xl);
  static final BorderRadius radiusFull = BorderRadius.circular(roundedFull);
  static final BorderRadius radius2xl = BorderRadius.circular(rounded2xl);

  // === ICON SIZES ===
  /// Small icon - 16px
  static const double iconSm = 16.0;

  /// Default icon - 20px
  static const double iconMd = 20.0;

  /// Large icon - 24px
  static const double iconLg = 24.0;

  /// Extra large icon - 32px
  static const double iconXl = 32.0;

  /// XXL icon - 40px
  static const double iconXxl = 40.0;

  /// Splash screen icon - 64px
  static const double iconSplash = 64.0;

  // === ELEVATION / SHADOW ===
  /// Small shadow
  static const double elevationSm = 2.0;

  /// Medium shadow
  static const double elevationMd = 4.0;

  /// Large shadow
  static const double elevationLg = 8.0;

  /// Card shadow (subtle)
  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: elevationSm,
        offset: const Offset(0, 2),
      );

  /// Elevated shadow (buttons, dialogs)
  static BoxShadow get elevatedShadow => BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: elevationMd,
        offset: const Offset(0, 4),
      );
}