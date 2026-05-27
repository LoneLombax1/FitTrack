# FitTrack — Design Spec
**Date:** 2026-05-27  
**Status:** Approved

---

## Overview

A personal iOS workout tracking app. Supports structured gym sessions with progressive overload, mixed training weeks (gym + sport + competition + rest), 8-week program blocks, and Whoop integration for recovery-informed planning.

---

## Constraints

- **Platform:** iOS only, SwiftUI
- **Storage:** SwiftData, on-device, single device
- **No backend** — Whoop OAuth tokens stored in iOS Keychain (PKCE flow)
- **Personal use only** — no auth, no multi-user concerns

---

## Architecture

```
SwiftUI views
    └── SwiftData models (local persistence)
    └── WhoopService (OAuth2 PKCE + REST API client)
    └── ProgressionEngine (overload logic)
    └── FatigueEngine (muscle balance calculations)
```

---

## Data Model

### Program
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| name | String | e.g. "Push/Pull/Legs + Rugby" |
| startDate | Date | |
| durationWeeks | Int | Default 8 |
| isActive | Bool | Only one program active at a time |

### WeeklyScheduleSlot
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| program | Program | Relationship |
| dayOfWeek | Int | 1=Mon … 7=Sun |
| type | Enum | `.gym`, `.sport`, `.competition`, `.rest` |
| workoutTemplate | WorkoutTemplate? | Gym slots only |
| activityName | String? | Sport/competition slots |
| muscleGroups | [MuscleGroup] | Sport/competition slots — set once, used for fatigue |
| intensity | Enum | `.low`, `.moderate`, `.high` — for fatigue weighting |

### WorkoutTemplate
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| name | String | e.g. "Push Day" |
| exercises | [TemplateExercise] | Ordered |

### TemplateExercise
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| name | String | e.g. "Bench Press" |
| targetSets | Int | |
| targetReps | Int | |
| orderIndex | Int | |
| primaryMuscles | [MuscleGroup] | |
| secondaryMuscles | [MuscleGroup] | |

### TrainingSession
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| date | Date | |
| type | Enum | `.gym`, `.sport`, `.competition`, `.rest` |
| programId | UUID? | Nil for ad-hoc sessions |
| weekNumber | Int? | Nil for ad-hoc sessions |

### GymSession (extends TrainingSession)
| Field | Type | Notes |
|-------|------|-------|
| workoutTemplateId | UUID | |
| setLogs | [SetLog] | |
| durationMinutes | Int? | |

### SetLog
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| exerciseName | String | Denormalised for history stability |
| setNumber | Int | |
| targetReps | Int | Snapshotted at session start |
| repsCompleted | Int | |
| weight | Double | kg |
| completed | Bool | |

### ActivitySession (extends TrainingSession)
| Field | Type | Notes |
|-------|------|-------|
| activityName | String | e.g. "Rugby Training" |
| muscleGroups | [MuscleGroup] | |
| intensity | Enum | |

### WhoopCycleCache
| Field | Type | Notes |
|-------|------|-------|
| date | Date | Day key |
| recoveryScore | Int | 0–100 |
| strainScore | Double | 0.0–21.0 |
| fetchedAt | Date | For staleness checks |

### MuscleGroup (enum)
`chest`, `back`, `shoulders`, `biceps`, `triceps`, `legs`, `core`, `fullBody`

### WeighIn
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| date | Date | |
| bodyWeightKg | Double | |
| bodyFatPercent | Double? | Manual entry |

### ProgressPhoto
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| date | Date | |
| weighInId | UUID? | Optionally linked to a weigh-in |
| filePath | String | Stored in app's documents directory |
| notes | String? | |

### Goal
| Field | Type | Notes |
|-------|------|-------|
| id | UUID | |
| type | Enum | `.strength`, `.bodyComposition` |
| title | String | e.g. "Bench Press 100kg" |
| targetValue | Double | kg for both types |
| targetDate | Date? | Optional deadline |
| linkedExerciseName | String? | Strength goals only — matches SetLog.exerciseName |
| linkedMetric | Enum? | Body comp only: `.bodyWeight`, `.bodyFatPercent` |
| isAchieved | Bool | Set automatically when target met |
| achievedDate | Date? | |

---

## Navigation: 5-Tab Layout

| Tab | Purpose |
|-----|---------|
| **Today** | Recovery badge, today's scheduled session, quick start |
| **Program** | Weekly schedule grid, 8-week progress, edit program |
| **History** | Chronological session log, per-exercise charts |
| **Muscles** | 7-day fatigue per muscle group, suggestions |
| **Progress** | Weight trend, body fat %, progress photos, goals |

---

## Core Flows

### Starting a Session
1. Today tab shows today's scheduled slot (gym/sport/competition/rest)
2. If gym: preview exercises with suggested weights and Whoop recovery banner
3. Tap "Start Session" → Active Session screen
4. Log each set: tap to confirm reps/weight, adjust inline if needed
5. Complete session → ProgressionEngine runs → weight suggestions updated

### Ad-hoc Session
- "+" button on Today tab → choose workout template or build from scratch
- Treated as an unscheduled gym session; still counts toward muscle fatigue and overload tracking

### Active Session Screen
- Exercise list, one card per exercise
- Each set row: target weight (suggested), reps field, completed toggle
- Whoop recovery score shown in header (green/yellow/red badge)
- Swipe to skip a set, long-press to edit exercise

---

## Progressive Overload Logic

Runs after every completed gym session, per exercise:

```
if all sets have repsCompleted >= targetReps:
    nextSuggestedWeight = lastWeight + 2.5kg
else:
    nextSuggestedWeight = lastWeight
```

Suggestion stored keyed by `(exerciseName, workoutTemplateId)`.

**Recovery modifier applied at session start (display only, not stored):**
- Recovery ≥75%: show overload target as-is
- Recovery 50–74%: show target with "moderate recovery" flag
- Recovery <50%: show –10% deload suggestion; overload target visible but de-emphasised

---

## Muscle Fatigue Engine

Rolling 7-day window. Each session contributes volume units per muscle group:

- Gym session: each exercise contributes `sets × reps` volume to its primary muscles (full) and secondary muscles (half)
- Sport/competition session: contributes a flat volume based on intensity (low=20, moderate=40, high=60) to tagged muscle groups
- Rest day: all muscle scores decay by 15%

Volume is used for the Muscles tab bar heights (relative comparison across muscle groups).

**Colour thresholds are day-based (simpler and more intuitive than volume thresholds for v1):**
- **Green** — any session hit this muscle in the last 4 days
- **Yellow** — last hit 5–7 days ago
- **Red** — not hit in 7+ days

Muscles tab shows a bar per muscle group with colour coding and a plain-English suggestion (e.g. "Biceps haven't been trained in 9 days").

---

## Whoop Integration

**Auth:** OAuth2 PKCE. User taps "Connect Whoop" in Settings → in-app `ASWebAuthenticationSession` → tokens stored in iOS Keychain.

**Data fetched:** `/v1/cycle` (recovery score, strain) on app open and Today tab refresh. Cached in `WhoopCycleCache` with a 30-minute staleness window.

**Touchpoints:**
1. **Today tab** — recovery badge (green/yellow/red), strain-so-far, intensity recommendation banner
2. **Session start** — weight suggestions adjusted by recovery
3. **Post-session** — show today's accumulated Whoop strain vs. expected

**Offline behaviour:** If Whoop fetch fails, show last cached score with a "last updated X ago" label. Overload suggestions still work without Whoop data.

---

## 8-Week Program Lifecycle

- Program tracks current week (derived from `startDate` + elapsed days)
- On the final day of week 8: "Program Complete" sheet surfaces
  - Summary: PRs hit, avg recovery score, muscle balance heatmap
  - **Generate next program**: pre-fills all exercises with accumulated weight targets; optionally adds 1 set to compound lifts
  - **Build from scratch**: blank program builder
- User can dismiss and extend the current program at any time

---

## Progress Tab

### Body Tracking
- **Weigh-in entry**: log body weight + optional body fat % — shown as a trend graph over time
- **Progress photos**: taken or imported from Photos library, stored in app documents directory, optionally linked to a weigh-in date
- Photos displayed as a chronological grid; tap to expand and compare two photos side-by-side

### Goals
Two goal types, both tracked automatically:

**Strength goal** (e.g. "Bench Press 100kg")
- Linked to an exercise name
- App watches SetLogs — when any set records `weight >= targetValue` with `repsCompleted >= 1`, goal is marked achieved
- Progress shown as: best weight to date vs. target, with a sparkline of recent sessions

**Body composition goal** (e.g. "Reach 85kg by Aug 2026")
- Linked to `.bodyWeight` or `.bodyFatPercent`
- Progress tracked against WeighIn history
- Trend line projected forward based on recent rate of change

Goals show on the Progress tab with a progress bar, current value, target value, and target date countdown. Achieved goals are archived but remain visible.

---

## Settings

- Connect / disconnect Whoop
- Default progressive overload increment (default 2.5kg)
- Program duration default (default 8 weeks)
- Deload threshold (default: recovery <50%)

---

## Out of Scope

- Apple Watch companion
- Social / sharing features
- Cloud backup (iCloud sync)
- Multiple users
- Exercise video library
