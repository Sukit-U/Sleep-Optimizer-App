# UI Guidelines

## 1. Overview

### Purpose

Describe the user interface structure and design guidelines for Sleep Optimizer.

### Design Goals

- Easy to understand
- Minimal learning curve
- Encourage healthy sleep habits
- Reduce unnecessary interactions

### Design Principles

- Keep screens simple.
- Show one primary task per screen.
- Minimize user input.
- Use consistent navigation.
- Display important information clearly.

---

## 2. Navigation Structure

Welcome (`/splash`) is the initial route. It does not auto-advance: the user
taps **Continue**, which saves `so.welcomeSeen` and calls
`pushReplacementNamed('/')`. Welcome is removed from the stack, so back from
Home does not return to it.

Home (`/`) is the root of the navigation stack and the container for the tab
bar.

```
Welcome (/splash)
  └─ Continue → Home (/)

Home (/)
  ├── Planner (/sleep-planner) → Suggested bedtimes (/suggested-bedtimes)
  ├── SQI (/sleep-quality) → result and recommendations (pushed with its result)
  ├── History (/history)
  └── Settings (/settings)
```

Tabs are pushes, not an `IndexedStack`: tapping a tab calls
`pushNamedAndRemoveUntil(route, (r) => r.isFirst)`. Home stays first in the
stack, so `BackButton()` on any tab returns to Home and tabs do not preserve
each other's state.

The SQI result screen is not a named route. `SleepQualityPage` pushes
`RecommendationPage` with the `SqiResult` it must display, so a name in
`AppRoutes` could only build it without a result. It is the page that shows the
score, the factor breakdown and the recommendations.

---

## 3. Screen Guidelines

### Welcome

Purpose

Get out of the way. There is no feature tour.

Components

- Moon mark (single `Icons.nightlight_round`, primary color, no container)
- Wordmark "Snoozefriend" (Karla 34)
- One sentence: how the app helps
- Disclaimer: "An educational tool, not a medical device."

Primary Actions

Continue (full-width primary button, 52 px tall, 14 px radius)

---

### Home

Purpose

Provide access to all major features.

Components

- Sleep Planner Card
- SQI Card
- History Card
- Settings Card

Primary Actions

- Open Planner
- Open SQI
- Open History
- Open Settings

---

### Sleep Planner

Purpose

Allow users to calculate bedtime.

Components

- Time Picker
- Daily Constraints
- Calculate Button
- Inputs
  - Wake-up Time
  - Daily Constraints
- Outputs
  - Suggested Bedtimes

Primary Actions

Calculate

---

### Planner Result

Purpose

Show recommended bedtime options.

Displayed Information

- Suggested bedtime
- Sleep duration
- Number of sleep cycles

Primary Actions

- Back to Home

---

### SQI

Purpose

Ask users about sleep behaviour.

Components

- Questionnaire
- Submit Button

Inputs

Questionnaire Answers

Primary Actions

Calculate

---

### SQI Result

Purpose

Allow users to see their calculated SQI score.

Components

- SQI Score
- Sleep Level
- Recommendations

Outputs

- SQI Score
- Sleep Level
- Recommendations

Primary Actions

- View Recommendations
- Save Result
- Return Home

---

### History

Purpose

Allows users to see recent SQI result.

Components

- History List
- SQI Score
- Date

Primary Actions

Display

---

### Settings

Purpose

Components

- Theme Switch
- About

Primary Actions

- Change Theme
- View About

---

## 4. UI Components

The shared widgets in `lib/shared/widgets/` are the component library. Add a
new one only when an existing widget cannot carry the content.

| Component | File | Job |
| --- | --- | --- |
| `TonightSuggestionCard` | `tonight_suggestion_card.dart` | Home's single call to action: open the planner |
| `HomeFeatureCard` | `home_feature_card.dart` | Two-up shortcuts to Planner and SQI |
| `LatestScoreSection` | `latest_score_section.dart` | Latest SQI score, or a prompt to start one |
| `BedtimeOptionCard` | `bedtime_option_card.dart` | One suggested bedtime with cycles and duration |
| `PlannerSaveButton` | `planner_save_button.dart` | Full-width save action with saved/saving states |
| `SQIQuestionCard` | `sqi_question_card.dart` | One question plus five rating chips |
| `HistorySleepPlanCard` | `history_sleep_plan_card.dart` | One saved plan |
| `SQIRecordCard` | `history_sqi_record_card.dart` | One saved assessment |
| `EmptyStateCard` | `empty_state_card.dart` | Empty list plus one action |
| `ErrorStateWidget` | `error_state_widget.dart` | Error message plus Retry |
| `SectionTitle` | `section_title.dart` | Section heading |
| `AppCard` | `app_card.dart` | Generic bordered surface |
| `showRecommendationSheet` | `recommendation_bottom_sheet.dart` | Recommendations for a saved record |

---

## 5. Design System

Values live in `lib/core/theme/app_colors.dart`, `app_typography.dart` and
`app_spacing.dart`. `app_theme.dart` maps them onto Material. Change the token,
not the screen.

### Theme

Dark first. Light theme is supported and uses the same hues on cool paper, with
two deeper variants: `lightPrimary` for the action blue, because the moonlight
blue is only legible as a fill, and `lightAccent` for the teal, because the
moonlight teal is too pale to read as an icon on white. `ColorScheme.surface`
is the card color, not the page color.

### Color

| Role | Token | Dark | Light | Use |
| --- | --- | --- | --- | --- |
| Page | `background` | `#0B1220` | `#EDF1F7` | Scaffold only |
| Card | `card` / `surface` | `#141C2A` | `#FBFCFE` | Every card and sheet |
| Raised | `surfaceElevated` | `#1D2738` | — | Snackbars, layered surfaces |
| Border | `border` | `#283649` | `#D6DEE9` | Hairline, 1 px |
| Text | `foreground` | `#E7EDF6` | `#16202E` | Body and headings |
| Muted text | `mutedForeground` | `#8FA0B7` | `#5B6878` | Captions, metadata |
| Action | `primary` | `#7FA8E0` | `#2A5C9E` | Fills, active tab, one per screen |
| On action | `primaryForeground` / `lightPrimaryForeground` | `#0A1220` | `#F7FAFF` | Text and icons on the action fill |
| Accent | `accent` / `secondary` | `#7BBFC2` | `#3F8A8D` | Secondary emphasis, SQI identity; the light value is `lightAccent` |
| Success | `success` | `#74C49E` | `#74C49E` | Confirmed saves |
| Warning | `warning` | `#D6B36A` | `#D6B36A` | Unconfirmed state |
| Error | `destructive` | `#E18D95` | `#E18D95` | Failed actions |

Rules that keep the palette coherent:

- Moonlight blue is a fill. Put dark text on it; on the light background use
  `lightPrimary`, which is dark enough to read as small text.
- The teal obeys the same rule. `#7BBFC2` sits at about 2:1 against white, so
  anything teal on paper — icons included — uses `lightAccent`.
- Status colors are muted. No saturated green or red.
- Never introduce a new hue in a widget. If a screen needs one, add a token.

### Typography

| Role | Family | Size / weight |
| --- | --- | --- |
| Welcome wordmark | Karla | 34 / w600 |
| Screen heading | Karla | 28 / w600, −0.5 tracking |
| AppBar title | Karla | 20 / w600 |
| Section heading | Karla | 18 / w600 |
| Bedtime value | Karla | 32 / w600 |
| Body | Karla | 14–16 / w400, height 1.4–1.5 |
| Button | Karla | 15–16 / w600 |
| Caption | Karla | 12 / w400 |
| Nav label | Karla | 10 / w500–w600 |

One family for everything. Headings differ by size and weight, not by typeface,
so the largest text on a screen is as easy to read as the smallest. Headings stop
at w700; `displayLarge` is 48 / w700.

`AppTypography` names the same families the theme loads through `google_fonts`,
so a style taken from a token renders in the app's typeface. Do not fall back to
`GoogleFonts.*` inside a widget unless the widget needs a size the tokens lack.

### Spacing

8-point scale, 4 px half-step: 4, 8, 16, 24, 32, 48 (`AppSpacing.xs` …
`xxxl`). Screen padding is 16 px (`AppSpacing.md`) on every sub-screen; Home
uses 20 px because its cards sit two-up.

### Radius

| Value | Token | Use |
| --- | --- | --- |
| 24 | `radius2xl` | Cards, sheets |
| 14 | literal | Welcome button |
| 12 | literal / `radiusMd` | Buttons, inputs |
| 999 | `radiusFull` | Floating tab bar, chips |

### Elevation

Separation comes from surface color and a 1 px border, not shadow. The only
shadow in the app is the floating tab bar (`blurRadius: 24`, `offset: (0, 8)`).
Card shadows, glows and colored shadows are not part of this system.

### Layout

**Empty states.** The card hugs its content: `MainAxisSize.min`, centered in the
space left by the screen. Do not let an empty state stretch to fill an
`Expanded` — the border then draws a screen-sized box around two lines. One
action, on a 12 px radius like every other button.

**Sheets.** The sheet body is the page color (`scaffoldBackgroundColor`) and the
cards on it are `surface`, which is the same relationship every page uses. A
sheet painted in `surface` has nothing left to separate its own cards from, and
in light theme the white-on-white edge disappears. Padding is 16 px
(`AppSpacing.md`), like other screens.

---

## 6. UX Guidelines

Feedback

Show confirmation after calculation.

Validation

Highlight invalid input.

Loading

Display loading indicator.

Empty State

No history available.

Error State

Unable to calculate.

---

## 7. Accessibility

- Readable font size.
- Sufficient color contrast.
- Large touch targets.

---

## 8. Responsive Guidelines

- Optimized for portrait mode.
- Support common phone screen sizes.

---

## 9. Screen Priority

High Priority

- Welcome
- Home
- Sleep Planner
- Planner Result
- SQI
- SQI Result

Medium Priority

- History

Low Priority

- Settings

---

## 10. Component Behaviors

Time Picker

- Opens native time picker.
- Allows only one wake-up time.

Recommendation Card

- Displays title.
- Displays description.
- Displays suggested action.

History Card

- Opens detailed history.

---

## 11. Visual Style

### The idea

A night sky seen from bed, not a wellness startup. Cool, low-glare surfaces under
a moonlight-blue action, one per screen; the bedtime itself is the largest thing
on the page.

### What that rules out

- Gradients of any kind, including ambient background orbs.
- Glows and colored shadows on buttons or cards.
- Sparkle icons (`Icons.auto_awesome`) used as decoration.
- An icon inside a tinted rounded square on every row. Icons sit plain on the
  surface unless the container carries meaning.
- Tracked capitals above headings, and colored dots beside labels.
- Emoji in headings.
- Pill-shaped everything. Pills are for the tab bar and chips; buttons and
  inputs use 12 px radii.
- Fully rounded 24 px cards stacked with an icon, a title and a one-line
  marketing sentence, repeated three times.

### What to do instead

- Lead with the number or time a person came for: bedtime, score, wake time.
- Write plainly and in second person. State what the screen does, not how good
  it is.
- Use borders, spacing and type weight for hierarchy before color.
- Keep one primary action per screen; everything else is a text action.
- Icons come from Material Icons only. `lucide_icons` does not build on this SDK.

---

## 12. Future UI Improvements

- Animations
- Widgets
- Tablet layout
- Landscape mode

---

## 13. Known Deviations

Places where the code does not yet match these guidelines. Fix the cause, not
the symptom, and delete the row once it is closed.

### Fixed

| Deviation | Resolution |
| --- | --- |
| Settings showed the title twice (AppBar plus body heading) | Body heading removed; AppBar owns the title |
| Screen padding varied: Settings, History, Recommendation and Welcome used 8 px while SQI used 16 px | Sub-screens moved to `AppSpacing.md` (16 px); Welcome uses `AppSpacing.lg` (24 px) as a full-screen intro |
| Bottom-nav labels were hard-coded at 11 px | Use `AppTypography.navLabel.fontSize` (10 px) |
| Home heading said "Dashboard" while the tab says "Home" | Heading is now "Home" |
| Home heading carried a 🌙 emoji | Removed; typography carries the identity |
| Welcome was a three-row feature tour over gradient orbs | Wordmark, one sentence, Continue, disclaimer. `_AmbientOrb`, `_FeatureRow` and the feature data were deleted with it |
| Floating tab bar used a 16 px backdrop blur and a 60 px shadow | Solid surface, 1 px border, 24 px shadow at `(0, 8)` |
| Cards used translucent fills, drop shadows and tinted icon squares | Solid surface, hairline border, plain icons. Card shadows and the last sparkle icons are gone |
| Palette was periwinkle blue and purple on a blue-black page | Cool night-sky blues on a moonlight-blue action, with `ColorScheme.surface` mapped to the card color; the light theme uses `lightPrimary` and `lightAccent` so small text and icons keep their contrast |
| Type was Sora for headings and Inter for body | Karla for every style; headings stop at w700 and differ by size and weight, not by family |
| Sleep Planner printed its name twice: the AppBar title plus a 12 px eyebrow above the heading | Eyebrow removed; the AppBar names the screen and the heading asks the question |
| SQI and history icons on paper were a 2:1 wash and read as blank space | Light theme maps `secondary` and `tertiary` to `lightAccent` |
| The floating tab bar kept highlighting the tab the user had just left, because the index was state written on tap | `_currentIndex` is read from the current route, so the bar follows the screen that is actually on top |
| Cards lost their shadow in the redesign and gained no edge, leaving them to float on the page | Every card that had relied on a shadow now carries the 1 px `colors.outline` border |
| History's empty state was a bordered card stretched over the whole list area | `EmptyStateCard` centers itself and sizes to its content; its action uses `AppSpacing.radiusMd` (12 px) |
| The recommendations sheet used 8 px padding and, in light theme, white cards on a white sheet | 16 px padding, and the sheet body uses the page color so its cards sit on it like every other card |
| `AppRoutes.recommendation` was registered in the router but nothing pushed it, and a named push could not pass the result the page needs | Constant and router case removed; the SQI flow pushes the page directly with its `SqiResult` |
| Settings showed a **Retry** text action while the sync card read "Connected" | Retry renders only when the connection is not ready and not already connecting |

### Open

| Deviation | Impact | What it needs |
| --- | --- | --- |
| Sleep Planner uses literal `24` / `20` / `16` padding values | Spacing drifts from the 8-point scale when the scale changes | Replace with `AppSpacing` tokens |
| Home uses 20 px horizontal padding, other screens 16 px | Intentional for the two-up cards; keep unless the layout changes | Documented, no action |
| History's AppBar title uses `AppTypography.h1` (w700) while Settings relies on the app bar theme (w600) | Two titles on sibling screens carry different weights | Pass the same token, or drop the page-level override |
| Recommendation uses an inline header instead of an AppBar | Back affordance differs from other sub-screens | Accept as a deliberate variant or migrate to `AppBar` |
| `lucide_icons` does not build on the current Flutter/Dart SDK | Icon set is limited to Material Icons | Not a UI defect; revisit only when the package is compatible |
