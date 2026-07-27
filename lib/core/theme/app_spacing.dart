import 'package:flutter/material.dart';

/// App spacing and sizing constants based on CompleteScreenSpecifications design system
/// Uses 8-point grid system with 1rem = 16px base
class AppSpacing {
  AppSpacing._();

  // === BASE UNITS ===
  /// Base unit: 4px (half of 8-point grid)
  static const double base = 4.0;
  /// Small unit: 8px (1 unit of 8-point grid)
  static const double small = 8.0;
  /// Medium unit: 16px (2 units of 8-point grid) - this is 1rem
  static const double medium = 16.0;
  /// Large unit: 24px (3 units of 8-point grid)
  static const double xLarge = 32.0;

  // === RADIUS VALUES ===
  /// Base radius: 0 (none) - but we'll use 4px as minimal for consistency
  static const double radiusNone = 0.0;
  /// Extra small radius: 4px (0.25rem)
  static const double radiusXs = 4.0;
  /// Small radius: 8px (0.5rem)
  static const double radiusSm = 8.0;
  /// Medium radius: 12px (0.75rem) - original value, but we'll update to match design
  /// However, per design system we want base radius = 16px (1rem)
  static const double radiusMd = 12.0; // Keeping for backward compatibility if needed
  /// Base radius: 16px (1rem) - as per design system
  static const double radius = 16.0;
  /// Large radius: 20px (1.25rem)
  static const double radiusLg = 20.0;
  /// Extra large radius: 24px (1.5rem) - for card-surface (radius-2xl)
  static const double radiusXl = 24.0;
  /// 2xl radius: 24px (1.5rem) - same as radiusXl for clarity
  static const double radius2xl = 24.0;
  /// 3xl radius: 28px (1.75rem) - for suggestion card
  static const double radius3xl = 28.0;
  /// Full radius (pill): 999px
  static const double radiusFull = 999.0;

  // === SPECIFIC COMPONENT RADII ===
  /// Card surface radius (radius-2xl) = 24px
  static const double cardRadius = radius2xl;
  /// Suggestion card radius (radius-3xl) = 28px
  static const double suggestionCardRadius = radius3xl;
  /// Button pill radius
  static const double buttonRadius = radiusFull;
  /// Pill button radius
  static const double pillRadius = radiusFull;

  // === SIZES ===
  /// Icon sizes
  static const double iconSizeSs = 12.0;
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 28.0;
  static const double iconSizeXl = 32.0;
  static const double iconSizeXxl = 36.0;

  /// Avatar sizes
  static const double avatarSizeXs = 20.0;
  static const double avatarSizeSm = 24.0;
  static const double avatarSizeMd = 28.0;
  static const double avatarSizeLg = 32.0;
  static const double avatarSizeXl = 36.0;
  static const double avatarSizeXxl = 40.0;

  // === SPACING (Padding/Margin) ===
  /// Spacing values following 8-point grid
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 40.0;

  // === ADDITIONAL SPACING VALUES ===
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;

  // === SPECIFIC COMPONENT SIZES ===
  /// App icon size (96x96) for welcome screen
  static const double appIconSize = 96.0;
  /// Moon icon size in app icon (44px)
  static const double moonIconSize = 44.0;
  /// Sparkle icon size in app icon (16px)
  static const double sparkleIconSize = 16.0;

  // === BUTTON HEIGHTS ===
  /// Standard button height
  static const double buttonHeight = 48.0;
  /// Pill button height
  static const double pillButtonHeight = 48.0;

  // === ICON CONTAINER SIZES ===
  /// Icon container size for feature rows (40x40)
  static const double iconContainerSize = 40.0;
  /// Inner icon size in feature rows (20x20)
  static const double innerIconSize = 20.0;
  /// Icon container size for splash screen (96x96)
  static const double iconSplashContainer = 96.0;
  /// Icon container size for medium icons (40x40)
  static const double iconMdContainer = 40.0;

  // === TEXT SIZES (in pixels, will be converted to sp in theme) ===
  /// Text sizes matching Tailwind's text sizes
  static const double textSizeXs = 12.0;   // text-xs
  static const double textSizeSm = 14.0;   // text-sm
  static const double textSizeBase = 16.0; // text-base
  static const double textSizeLg = 18.0;   // text-lg
  static const double textSizeXl = 20.0;   // text-xl
  static const double textSize2xl = 24.0;  // text-2xl
  static const double textSize3xl = 30.0;  // text-3xl
  static const double textSize4xl = 36.0;  // text-4xl
  static const double textSize5xl = 48.0;  // text-5xl
  static const double textSize6xl = 60.0;  // text-6xl

  // === LINE HEIGHTS ===
  /// Line heights as multiples (unitless)
  static const double lineHeightNone = 1.0;
  static const double lineHeightTight = 1.25;
  static const double lineHeightSnug = 1.375;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.625;
  static const double lineHeightLoose = 2.0;

  // === LETTER SPACING ===
  /// Letter spacing values (in em)
  static const double letterSpacingTighter = -0.05;
  static const double letterSpacingTight = -0.025;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.025;
  static const double letterSpacingWider = 0.05;
  static const double letterSpacingWidest = 0.1;

  // === BACKWARD COMPATIBILITY ALIASES ===
  // These are temporary aliases for the old getter names to avoid breaking existing code.
  // We will remove them as we update each screen.

  static const double px = 8.0;
  static const double py = 8.0;
  static const double huge = 24.0;
  static const double defaultSpacing = 16.0;
  static const double elevationSm = 2.0;
  static const double iconSm = 20.0;   // same as iconSizeSm
  static const double iconMd = 24.0;   // same as iconSizeMd
  static const double iconLg = 28.0;   // same as iconSizeLg
  static const double iconXl = 32.0;   // same as iconSizeXl
  static const double iconXxl = 36.0;  // same as iconSizeXxl
  static const double iconXxxl = 40.0; // additional
  static const double iconButtonSize = 40.0; // same as iconContainerSize
  static const double inputHeight = 48.0;   // same as buttonHeight
  static const double buttonPadding = 16.0; // same as spacingMd
  static const double radiusPill = 999.0;   // same as radiusFull
  static const double roundedXl = 20.0;   // same as radiusLg
  static const double roundedLg = 20.0;   // same as radiusLg
  static const double roundedMd = 12.0;   // same as radiusMd
  static const double roundedSm = 8.0;    // same as radiusSm
  static const double roundedXs = 4.0;    // same as radiusXs
  static const double roundedFull = 999.0; // same as radiusFull
  static const double cardShadow = 4.0;   // elevation
  static const double bottomNavHeight = 64.0; // typical bottom navigation height
}