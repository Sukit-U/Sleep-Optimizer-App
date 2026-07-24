# Data Model

## 1. Overview

### Purpose

Describe the information that the application stores and the relationships between different data entities.

### Scope

This document defines the application's logical data structure without describing database implementation details.

---

## 2. Entities

### User

Purpose

Stores information related to an application user.

Attributes

- User ID

Relationships

- A user can have multiple Sleep Plans.
- A user can have multiple SQI records.
- A user can have a history for recent SQI records.

---

### Sleep Plan

Purpose

Stores users' sleep planning results based on their desired wake-up time.

Attributes

- Wake-up time
- Suggested bedtimes (multiple)
- Sleep cycles
- Sleep duration
- Created date

Relationships

- Each Sleep Plan belongs to one user.
- One user can have multiple Sleep Plans.

---

### SQI Record

Purpose

Stores users' sleep quality assessment results.

Attributes

- SQI score
- Sleep quality level
- Questionnaire responses
- Created date

Relationships

- Each SQI record belongs to one user.
- Each SQI record may generate multiple recommendations.

---

### Recommendation

Purpose

Stores personalized recommendations based on users' SQI results.

Attributes

- Improvement needed factor.
- Users' action based on improvement needed factor.
- Recommendation title
- Description
- Action
- Priority

Relationships

- Each recommendation belongs to one SQI record.
- One SQI record may generate multiple recommendations.

---

### Settings

Purpose

Stores users' application preferences.

Attributes

- Theme

Relationships

- Each settings record belongs to one user.

---

## 3. Entity Relationships

User
├── Sleep Plan
├── SQI Record
│   └── Recommendation
└── Settings

---

## 4. Data Lifecycle

### 4.1 Sleep Plan

Create

When the user calculates a sleep plan.

Read

When the user opens Planner History.

Update

When the user recalculates.

Delete

When the user deletes the history.

### 4.2 SQI Record

Create

When the user answers the questionnaire.

Read

When the user opens SQI History.

Update

When the user re-answered questionnaire.

Delete

When the user deletes the history.

### 4.3 Recommendation

Create

When a new SQI record is generated.

Read

When the user opens the recommendation page.

Update

When the user re-answered questionnaire and the algorithm re-calculated SQI score.

Delete

When the user deletes the history.

### 4.4 Settings

Create

When the user customizes the theme.

Read

When the user opens Settings.

Update

When the user makes a change.

Delete

When the application data is reset.

---

## 5. Data Validation

Required fields

- Wake-up time is required.
- SQI responses are required.
- Theme must be one of the supported themes.

Optional fields

None.

Unique fields

None.

---

## 6. Assumptions

- Each SQI record belongs to one user.
- Each Sleep Plan belongs to one user.
- Settings are stored separately from sleep records.
- Recommendations are generated for each SQI record.
- Sleep plan is separated from SQI result.
