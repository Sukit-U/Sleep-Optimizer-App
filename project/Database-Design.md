# Database Design

## 1. Overview

### Purpose

Describe how application data is organized and stored.

### Scope

This document describes the logical database structure for Sleep Optimizer. It does not describe implementation code.

---

## 2. Database Technology

### Platform

Firebase Firestore

### Database Type

NoSQL Document Database

---

## 3. Collections

### users

Purpose

Store user information.

Fields

- userId (String)
- theme (String)

---

### sleepPlans

Purpose

Store calculated sleep planning results.

Fields

- planId (String)
- userId (String)
- wakeUpTime (Timestamp)
- createdAt (Timestamp)
- sleepCycles (Integer)
- suggestedBedtimes (Array&lt;String&gt;)

---

### sqiRecords

Purpose

Store SQI assessment results.

Fields

- recordId (String)
- userId (String)
- sqiScore (Integer)
- sleepQualityLevel (String)
- questionnaireResponses (Map)
- createdAt (Timestamp)

---

### recommendations

Purpose

Store generated recommendations.

Fields

- recommendationId ('String')
- userId (String) — owner of the parent SQI record
- recordId (String)
- factor (String)
- title (String)
- description (String)
- action (String)
- priority (String)
- createdAt (Timestamp)

---

### settings

Purpose

Store user preferences.

Fields

- userId (String)
- theme (String)

---

## 4. Relationships

User (1)
├── Sleep Plans (Many)
├── SQI Records (Many)
│    └── Recommendations (Many)
└── Settings (1)

---

## 5. Data Flow

Sleep Planner

User Input

↓

Calculation

↓

Sleep Plan

↓

Firestore

---

SQI

Questionnaire

↓

SQI Calculation

├── SQI Record
└── Recommendations

↓

Firestore

---

## 6. Data Validation

- userId is required.
- Wake-up time is required.
- Questionnaire responses are required.
- Theme must be valid.

---

## 7. Assumptions

- Each user has one settings record.
- Sleep Plans are independent from SQI records.
- Recommendations belong to one SQI record.
- A recommendation inherits that record's owner (`userId`); the rules only let
  the owner read it, and the app query filters by `userId` as well.

---

## 8. Future Improvements

- User authentication
- Cloud synchronization
- Multiple devices
- Offline support
