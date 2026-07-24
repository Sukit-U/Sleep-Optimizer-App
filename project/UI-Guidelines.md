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

Welcome

↓

Home

├── Planner

├── SQI

├── History

└── Settings

---

## 3. Screen Guidelines

### Welcome

Purpose

Introduce the application.

Components

- Logo
- App Name

Primary Actions

Continue

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

Reusable Components

- Planner Card
- SQI Card
- Recommendation Card
- Score Card
- History Card
- Time Picker

---

## 5. Design System

Primary Theme

Dark

Secondary Theme

Light

Typography

- Heading
- Body
- Caption

Icons

Simple UI icons

Spacing

8-point grid

Corner Radius

Rounded corners

Shadow

Subtle shadow

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

Theme

Modern
Minimal
Calm

Feeling

Clean
Night-friendly
Comfortable

Mood

Relaxing
Trustworthy
Modern

Style Reference

Apple Health
Google Material 3

Primary Color

Blue

Accent Color

Purple

Background

Dark Gray

Cards

Rounded corners

Icons

Rounded outline icons

---

## 12. Future UI Improvements

- Animations
- Widgets
- Tablet layout
- Landscape mode
