# App specification

- [App specification](#app-specification)
  - [1.Overview](#1overview)
    - [Purpose](#purpose)
    - [Target Users](#target-users)
    - [Core Value](#core-value)
  - [2.Problem Statement](#2problem-statement)
    - [Current situation](#current-situation)
    - [Problem](#problem)
    - [Impact](#impact)
  - [In Scope](#in-scope)
  - [Out of Scope](#out-of-scope)
  - [Target Users (Details)](#target-users-details)
    - [Primary Users](#primary-users)
    - [Age](#age)
    - [Occupation](#occupation)
    - [Goals](#goals)
    - [Pain Points](#pain-points)
  - [Core Features](#core-features)
    - [Sleep Planner](#sleep-planner)
    - [Sleep Quality Score (SQI)](#sleep-quality-score-sqi)
    - [History](#history)
    - [Settings](#settings)
    - [Available settings](#available-settings)
  - [Functional Overview](#functional-overview)
  - [Project Constraints](#project-constraints)
  - [Future Scope](#future-scope)
    - [AI Coach for sleeping quality](#ai-coach-for-sleeping-quality)
    - [Wearables](#wearables)
  - [System Workflow](#system-workflow)
    - [Sleep Planner Flow](#sleep-planner-flow)
    - [SQI Flow](#sqi-flow)
  - [Success Criteria](#success-criteria)
  - [Assumptions](#assumptions)
  - [Non-Functional Requirements](#non-functional-requirements)
    - [Performance](#performance)
    - [Usability](#usability)
    - [Compatibility](#compatibility)
    - [Privacy](#privacy)

## 1.Overview

### Purpose

The project's purpose is to help students make better sleep decisions and develop healthier sleep habits.

### Target Users

High school students who often experience insufficient sleep due to academic and daily-life constraints.

### Core Value

Helps students make better decisions about sleep within real-life constraints.

## 2.Problem Statement

### Current situation

High school students often face heavy academic workloads, homework, extracurricular activities, and supplementary classes. These commitments frequently cause them to return home late, leaving less time for adequate sleep.

### Problem

Even when students understand that sleep is important, they often struggle to manage their time well and maintain healthy sleep habits. Behaviors such as using a smartphone before bed, drinking caffeine, and feeling stressed can make the problem worse.

### Impact

- Reduced sleep quality.
- Daytime drowsiness.
- Reduced concentration.
- Lower academic performance.
- Long-term unhealthy sleep habits.
- Difficulty maintaining a consistent sleep schedule.

## In Scope

- Sleep Planner
- Sleep Quality Score (SQI)
- Personalized Recommendation
- History
- Settings

## Out of Scope

- Sleep Stage
- Medical Diagnosis
- Wearables
- Machine learning

## Target Users (Details)

### Primary Users

### Age

- 15–18 years old
- High school students

### Occupation

- High school student

### Goals

- Plan an appropriate bedtime based on their daily schedule.
- Improve sleep quality through healthier sleep habits.
- Wake up feeling more refreshed for school.

### Pain Points

- Heavy homework and school projects.
- Extra tutoring or cram school.
- Late arrival home.
- Poor time management.
- Excessive screen time before bed.
- Irregular sleep schedule.

## Core Features

### Sleep Planner

Helps users plan an appropriate bedtime based on their wake-up time and daily constraints.

### Sleep Quality Score (SQI)

- Evaluates sleep-related behaviors based on factors affecting sleep.
- Calculates a score based on users' responses to sleep-related behavior questions.
- Categorizes sleep quality into different levels.

### History

Helps users track SQI score trends and sleep plans to observe changes in daily sleep habits.

### Settings

Allows users to customize basic application settings and view application information.

### Available settings

- Theme
- About

## Functional Overview

Sleep Optimizer consists of four main functions that work together to help students improve their sleep habits.

- Sleep Planner helps users plan an appropriate bedtime based on their desired wake-up time and daily constraints.
- Sleep Quality Score (SQI) evaluates sleep-related behaviors and provides personalized recommendations.
- History allows users to review previous sleep plans and SQI results to monitor their progress over time.
- Settings allows users to customize the application theme and access application information.

## Project Constraints

- Educational Information Systems project.
- Three-member team.
- Expected duration: 2–4 months.
- Focus on simple and explainable features.
- No wearables.
- No machine learning.

## Future Scope

### AI Coach for sleeping quality

Description

An AI agent that reviews users' sleeping quality based on SQI score and questionnaire, and then recommend actions to improve sleep habits for improving sleep behaviour aside from SQI score.

Purpose

AI can help recommend for sleeping quality aside from SQI score.

### Wearables

Description

Integrate the application with wearable device APIs to obtain sleep-related data.

Purpose

Nowadays user also uses smart watch, smart ring , etc. to help them take care of their health.

## System Workflow

### Sleep Planner Flow

1. Welcome
2. Home
3. Sleep Planner
4. Planner Result
5. Home

### SQI Flow

1. Home
2. SQI
3. SQI Result
4. Recommendation
5. History

## Success Criteria

The application should enable users to:

- Plan an appropriate bedtime based on their desired wake-up time.
- Understand how daily behaviors affect sleep quality.
- Receive personalized recommendations for improving sleep habits.
- Track changes in sleep-related behaviors over time.
- Use the application with minimal effort through a simple and intuitive interface.

## Assumptions

- Users are willing to manually provide sleep-related information.
- Users answer the SQI questionnaire honestly.
- Users are expected to follow the recommendations provided by the application.
- A 90-minute sleep cycle is used as the planning reference.
- The application is intended for educational purposes only and does not provide medical advice.

## Non-Functional Requirements

### Performance

- The application should calculate results within 2 seconds.

### Usability

- The application should be easy to use with minimal learning.

### Compatibility

- Android first.

### Privacy

- User data should remain private and only be used within the application.
