# Design System

## 1. Overview
Design tokens live in `lib/core/theme/` (`AppColors`, `AppTypography`, `AppSpacing`, `AppTheme`).

---

## 2. Typography (`AppTypography` & `AppTheme`)

- **Font Family**: **`Kanit`** (`fontFamilyHeader = 'Kanit'`, `fontFamilyBody = 'Kanit'`, fallbacks `['Kanit', 'Segoe UI', 'sans-serif']`).
- **Bundled Font Assets** (`pubspec.yaml`): `Kanit-Regular.ttf` (400), `Kanit-Medium.ttf` (500), `Kanit-SemiBold.ttf` (600), `Kanit-Bold.ttf` (700).
- **Monospace**: `AppTypography.mono` uses `'monospace'` (11 px, w500, letterSpacing 0.02, height 1.4).

### Scale (`AppTypography`)
- `displayLarge`: 48 / w700 (w600 in `AppTheme`)
- `displayMedium`: 36 / w700 (w600 in `AppTheme`)
- `displaySmall`: 32 / w700 (w600 in `AppTheme`)
- `h1`: 20 / w700 (w600 in `AppTheme`)
- `h2`: 18 / w600
- `h3`: 16 / w600
- `h4`: 15 / w600
- `h5`: 14 / w600
- `bodyLarge`: 16 / w400
- `body`: 14 / w400
- `bodyMedium`: 14 / w500
- `button`: 14 / w600
- `label`: 14 / w500
- `labelSmall`: 12 / w500 (w600 in `AppTheme`)
- `caption` / `captionMuted`: 12 / w400
- `small`: 11 / w500 (w400 in `AppTheme`)
- `navLabel`: 10 / w500
- `tabLabel`: 12 / w600

---

## 3. Color System (`AppColors`)

### Brand & Accent
- `primary`: `#7FA8E0` (`primaryLight`: `#A3C4F0`, `primaryDark`: `#5A82B8`, `primaryForeground`: `#0A1220`)
- `accent` / `secondary`: `#7BBFC2` (`accentLight`: `#A2D8DA`, `accentDark`: `#4E8D90`)

### Dark Theme (Default)
- `background`: `#0B1220`
- `card` / `surface`: `#141C2A`
- `surfaceElevated`: `#1D2738`
- `foreground`: `#E7EDF6`
- `mutedForeground`: `#8FA0B7`
- `muted`: `#1A2333`, `mutedBackground`: `#0F1724`
- `border` / `inputBorder`: `#283649`
- `inputBackground`: `#0F1725`

### Light Theme
- `lightBackground`: `#EDF1F7`
- `lightCard`: `#FBFCFE`
- `lightForeground`: `#16202E`
- `lightMutedForeground`: `#5B6878`
- `lightMuted`: `#E6EBF3`
- `lightBorder`: `#D6DEE9`
- `lightPrimary`: `#2A5C9E` (`lightPrimaryForeground`: `#F7FAFF`)
- `lightAccent`: `#3F8A8D`

### Status Colors
- `success`: `#74C49E` (`successForeground`: `#08170F`)
- `warning`: `#D6B36A` (`warningForeground`: `#17120A`)
- `destructive`: `#E18D95` (`destructiveForeground`: `#1E0F12`)

---

## 4. Spacing & Radii (`AppSpacing`)

- **Spacing**: `xs = 4.0`, `sm = 8.0`, `md = 16.0`, `lg = 24.0`, `xl = 32.0`, `xxl = 40.0`, `xxxl = 48.0`.
- **Radii**: `radiusNone = 0`, `radiusXs = 4`, `radiusSm = 8`, `radiusMd = 12`, `radius = 16`, `radiusLg = 20`, `radiusXl = 24`, `radius2xl = 24`, `radius3xl = 28`, `radiusFull = 999`.
  - `cardRadius = 24`, `suggestionCardRadius = 28`, `buttonRadius / pillRadius = 999`.

---

## 5. Navigation & Component Tokens

- **Bottom Navigation**: Active in `HomePage` as a 5-tab floating pill bar (`radiusFull`, `colors.surface`, 1 px `colors.outline`, shadow blur 24, offset `(0, 8)`).
- **Reusable Widgets** (`lib/shared/widgets/`): `AppCard`, `BedtimeOptionCard`, `EmptyStateCard`, `ErrorStateWidget`, `HistorySleepPlanCard`, `HistorySQIRecordCard`, `HomeFeatureCard`, `LatestScoreSection`, `PlannerSaveButton`, `RecommendationBottomSheet`, `SectionTitle`, `SQIQuestionCard`, `TonightSuggestionCard`.
