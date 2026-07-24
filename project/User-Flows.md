# User Flows

## 1. Overview

### Purpose

Describe how users interact with the application to achieve each major function.

### Scope

This document covers the user interaction flow for all core features of Sleep Optimizer.

---

## 2. Main Navigation

Welcome

↓

Home (Main menu)

├── Sleep Planner

├── Sleep Quality Score (SQI)

├── History

└── Settings

---

## 3. Sleep Planner Flow

### 3.1 Goal

Allow users to plan an appropriate bedtime.

### 3.2 Preconditions

- User has entered the application.
- User is on the Home page.

### 3.3 Main Flow

1. User opens Home.
2. User selects Sleep Planner.
3. User enters wake-up time.
4. User optionally selects daily constraints.
5. User presses Calculate.
6. System calculates sleep cycles.
7. System displays multiple suggested bedtimes.
8. User returns to Home.

### 3.4 Alternative Flows

Wake-up time is empty.

↓

Display validation message.

↓

Stay on current page.

User cancels.

↓

Return Home.

### 3.5 Postconditions

The calculated sleep plan is available for later viewing.

---

## 4. Sleep Quality Score (SQI) Flow

### 4.1 Goal

Evaluate sleep quality.

### 4.2 Preconditions

- User has entered the application.
- User is on the Home page.

### 4.3 Main Flow

1. User opens Home.
2. User selects SQI Score.
3. User answers the questionnaire.
4. User submits.
5. System calculates SQI score.
6. System displays SQI score.
7. System displays recommendation.
8. User returns to Home.

### 4.4 Alternative Flows

One or more required questions are unanswered.

↓

Display validation message.

↓

Stay on the current page.

User cancels.

↓

Return Home.

### 4.5 Postconditions

The SQI result and recommendations are saved to History.

---

## 5. History Flow

### 5.1 Goal

Allow users to review previous sleep records.

### 5.2 Main Flow

1. User opens Home.
2. User selects History.
3. User selects a history record.
4. User views sleep plan details.
5. User views SQI result and recommendations.
6. User returns to Home.

---

## 6. Settings Flow

### 6.1 Goal

Allow users to customize application preferences.

### 6.2 Main Flow

1. User opens Home.
2. User selects Settings.
3. User changes Theme.
4. User saves.
5. User returns to Home.

---

## 7. Error Flows

Missing wake-up time

↓

Display validation message

Incomplete SQI questionnaire

↓

Display validation message

Unexpected error

↓

Display friendly message

Invalid wake-up time

↓

Display validation message

↓

Stay on current page

---

## 8. Navigation Summary

Welcome

↓

Home

├── Planner

│      ↓

│   Result

│      ↓

│   Home

│

├── SQI

│      ↓

│   Result

│      ↓

│ Recommendation

│      ↓

│ Home

│

├── History

│      ↓

│ Home

│

└── Settings

       ↓

     Home
