# Functional Requirements

## 1. Overview

### Purpose

Describe what the system must do from the user's perspective.

### Scope

This document defines the functional capabilities of Sleep Optimizer and does not cover UI design or implementation details.

## 2. Functional Requirements

### FR-1 Sleep Planner

Purpose

Calculate recommended bedtimes.

Requirements

FR-1.1
The system shall allow users to enter a wake-up time.

FR-1.2
The system shall calculate bedtime options based on 90-minute sleep cycles.

FR-1.3
The system shall consider sleep latency.

FR-1.4
The system shall display multiple bedtime options.

FR-1.5
The system shall save the generated sleep plan.

### FR-2 Sleep Quality Score

Purpose

Evaluate users' sleep quality.

Requirements

FR-2.1
The system shall display the SQI questionnaire.

FR-2.2
The system shall require all questions before submission.

FR-2.3
The system shall calculate the SQI score.

FR-2.4
The system shall categorize sleep quality.

FR-2.5
The system shall generate personalized recommendations.

FR-2.6
The system shall save the SQI result.

### FR-3 Recommendation

Purpose

Provide personalized recommendations.

Requirements

FR-3.1
The system shall identify weak assessment factors.

FR-3.2
The system shall select recommendations.

FR-3.3
The system shall prioritize recommendations.

FR-3.4
The system shall display at most three recommendations.

### FR-4 History

Purpose

Allow users to review previous Sleep Plans and SQI records.

Requirements

FR-4.1
The system shall display previous sleep plans.

FR-4.2
The system shall display previous SQI results.

FR-4.3
The system shall display recommendation history.

FR-4.4
The system shall sort records by date.

### FR-5 Settings

Purpose

Allow users to customize the application.

Requirements

FR-5.1
The system shall allow users to switch themes.

FR-5.2
The system shall remember the selected theme.

FR-5.3
The system shall display application information in the About page.

### FR-6 Navigation

Purpose

Describe navigation requirements throughout the application.

Requirements

FR-6.1
The system shall provide navigation from Home to every feature.

FR-6.2
The system shall allow users to return using the Back button.

FR-6.3
The system shall preserve data when users navigate between screens.

### FR-7 Validation

Purpose

Ensure user inputs are valid before processing.

Requirements

FR-7.1
The system shall validate wake-up time.

FR-7.2
The system shall validate required questionnaire answers.

FR-7.3
The system shall display validation messages.

### FR-8 Error Handling

Purpose

Handle invalid input and unexpected situations gracefully.

Requirements

FR-8.1
The system shall display user-friendly error messages.

FR-8.2
The system shall prevent application crashes.

FR-8.3
The system shall recover gracefully from unexpected errors.

### FR-9 Data Persistence

Purpose

Store and retrieve application data.

Requirements

FR-9.1
The system shall save Sleep Plan records.

FR-9.2
The system shall save SQI records.

FR-9.3
The system shall retrieve previously saved Sleep Plans and SQI records.

FR-9.4
The system shall store user preferences.

### FR-10 Future Functional Requirements (Optional)

Purpose

Describe planned future capabilities that are outside the current project scope.

FR-10.1
Support adaptive recommendation optimization based on user behavior and sleep history.

FR-10.2
Support an AI sleep coach for personalized sleep guidance and education.

FR-10.3
Support wearable device integration for automatic sleep data collection.

FR-10.4
Support smart reminders and bedtime notifications based on the user's schedule.
