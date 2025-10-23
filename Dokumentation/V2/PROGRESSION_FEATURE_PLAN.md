# GymBo V2 - Progression Feature Plan (Phase 2)

**Status:** 📋 PLANNED - Not yet implemented  
**Created:** 2025-10-23  
**Last Updated:** 2025-10-23  
**Dependencies:** Workout Repository (Phase 1)

---

## 📋 Executive Summary

This document outlines the **Automatic Progression** feature for GymBo V2. This feature will analyze user workout history, personal records, and profile data to automatically suggest weight/rep progressions based on proven training methodologies.

**Phase 1 (Current):** Manual progression using `lastUsedWeight/Reps` from ExerciseEntity  
**Phase 2 (This Plan):** Automatic progression suggestions based on training history and goals

---

## 🎯 Feature Goals

### User Stories

1. **As a user**, I want the app to suggest when to increase weight, so I don't have to track progression manually
2. **As a user**, I want different progression strategies (linear, double progression), so I can match my training style
3. **As a user**, I want the app to learn from my failed sets, so it doesn't over-progress me
4. **As a user**, I want to see my progression history, so I can visualize my strength gains

### Success Metrics

- ✅ User can select progression strategy per workout
- ✅ App suggests weight/rep increases based on last 3-5 sessions
- ✅ App tracks progression events (increases, deloads, plateaus)
- ✅ User sees progression timeline in workout history

---

## 📊 Current Data Model (Phase 1)

### What Already Exists

#### 1. **ExerciseEntity** - Last Used Tracking
```swift
@Model
final class ExerciseEntity {
    var lastUsedWeight: Double?     // ✅ Last weight used
    var lastUsedReps: Int?          // ✅ Last reps completed
    var lastUsedDate: Date?         // ✅ When last used
    var lastUsedSetCount: Int?      // ✅ How many sets
    var lastUsedRestTime: TimeInterval?
}
```

#### 2. **ExerciseRecordEntity** - Personal Records
```swift
@Model
final class ExerciseRecordEntity {
    // Max Weight Record
    var maxWeight: Double
    var maxWeightReps: Int
    var maxWeightDate: Date
    
    // Max Reps Record
    var maxReps: Int
    var maxRepsWeight: Double
    var maxRepsDate: Date
    
    // Estimated 1RM
    var bestEstimatedOneRepMax: Double  // ✅ 1RM calculation!
    var bestOneRepMaxWeight: Double
    var bestOneRepMaxReps: Int
    var bestOneRepMaxDate: Date
}
```

#### 3. **UserProfileEntity** - User Context
```swift
@Model
final class UserProfileEntity {
    var goalRaw: String              // "strength", "hypertrophy", "endurance"
    var experienceRaw: String        // "beginner", "intermediate", "advanced"
    var equipmentRaw: String         // Available equipment
    var preferredDurationRaw: Int    // Workout duration preference
    var weight: Double?              // User bodyweight (for relative strength)
}
```

#### 4. **WorkoutSessionEntity** - Complete History
```swift
@Model
final class WorkoutSessionEntity {
    var workoutId: UUID
    var startDate: Date
    var endDate: Date?
    var state: String  // "active", "completed", "paused"
    
    // All exercises + sets with weight/reps/completed
    @Relationship var exercises: [SessionExerciseEntity]
}
```

**Analysis:** ✅ We already capture all raw data needed for progression algorithms!

---

## 🆕 Required Data Model Extensions (Phase 2)

### 1. WorkoutEntity - Progression Strategy

**Location:** `GymBo/SwiftDataEntities.swift`

```swift
@Model
final class WorkoutEntity {
    // ... existing fields ...
    
    // 🆕 PHASE 2 - Progression Settings
    /// Progression strategy for this workout template
    /// Values: nil (manual), "linear", "double_progression", "wave_loading"
    var progressionStrategyRaw: String? = nil
    
    /// Default target rep range minimum (e.g., 8 for 8-12 range)
    var defaultTargetRepsMin: Int? = nil
    
    /// Default target rep range maximum (e.g., 12 for 8-12 range)
    var defaultTargetRepsMax: Int? = nil
    
    /// Serialized JSON for strategy-specific parameters
    /// Example: {"deloadWeeks": 4, "incrementKg": 2.5}
    var progressionParametersJSON: Data? = nil
}
```

**Migration:** These fields are optional → backward compatible, no migration needed!

---

### 2. WorkoutExerciseEntity - Per-Exercise Progression

**Location:** `GymBo/SwiftDataEntities.swift`

```swift
@Model
final class WorkoutExerciseEntity {
    // ... existing fields ...
    
    // 🆕 PHASE 2 - Exercise-Specific Progression
    /// Override target reps for this specific exercise (nil = use workout default)
    var targetRepsMin: Int? = nil
    var targetRepsMax: Int? = nil
    
    /// How much to increase weight when progressing (e.g., 2.5kg)
    var progressionIncrement: Double? = nil
    
    /// Disable auto-progression for this exercise (user wants manual control)
    var autoProgressionDisabled: Bool = false
}
```

**Use Case:**
- Most exercises use workout default (8-12 reps, +2.5kg)
- But user wants Deadlifts to be 5 reps, +5kg increments
- Override per exercise without changing whole workout

---

### 3. WorkoutSessionEntity - Session Feedback

**Location:** `GymBo/SwiftDataEntities.swift`

```swift
@Model
final class WorkoutSessionEntity {
    // ... existing fields ...
    
    // 🆕 PHASE 2 - Feedback for Learning
    /// User's perceived difficulty (1-10 RPE scale)
    /// RPE 10 = max effort, RPE 7 = comfortable
    var perceivedDifficulty: Int? = nil
    
    /// Notes about the session (optional)
    var sessionNotes: String? = nil
    
    /// Did user complete all planned sets successfully?
    var completedSuccessfully: Bool? = nil
}
```

**Future Use:** If user rates RPE 9-10 → algorithm suggests deload next week

---

### 4. ProgressionEventEntity - New Entity

**Location:** `GymBo/SwiftDataEntities.swift`

```swift
// 🆕 PHASE 2 - Track all progression events
@Model
final class ProgressionEventEntity {
    @Attribute(.unique) var id: UUID
    
    /// Which exercise was progressed
    var exerciseId: UUID
    var exerciseName: String  // Denormalized for easy display
    
    /// When did this progression happen
    var date: Date
    
    /// Type of progression event
    /// Values: "weight_increase", "reps_increase", "deload", "plateau"
    var eventType: String
    
    /// Old values (before progression)
    var oldWeight: Double
    var oldReps: Int
    var oldSetCount: Int?
    
    /// New values (after progression)
    var newWeight: Double
    var newReps: Int
    var newSetCount: Int?
    
    /// Why did this progression happen?
    /// Examples:
    /// - "Completed all sets at target reps for 2 consecutive workouts"
    /// - "User manually increased weight"
    /// - "Auto-deload after 3 failed sessions"
    var reason: String?
    
    /// Was this automatic or manual?
    var wasAutomatic: Bool
    
    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        date: Date = Date(),
        eventType: String,
        oldWeight: Double,
        oldReps: Int,
        oldSetCount: Int? = nil,
        newWeight: Double,
        newReps: Int,
        newSetCount: Int? = nil,
        reason: String? = nil,
        wasAutomatic: Bool
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.date = date
        self.eventType = eventType
        self.oldWeight = oldWeight
        self.oldReps = oldReps
        self.oldSetCount = oldSetCount
        self.newWeight = newWeight
        self.newReps = newReps
        self.newSetCount = newSetCount
        self.reason = reason
        self.wasAutomatic = wasAutomatic
    }
}
```

**Use Cases:**
- Display progression timeline: "You increased Bench Press by 10kg in 4 weeks!"
- Debug why app suggested a specific progression
- Export progression data for analytics

---

## 🧠 Progression Algorithms

See full implementation details in the file for:
- Linear Progression (Beginner-Friendly)
- Double Progression (Hypertrophy)
- Wave Loading (Advanced)

---

## 🚀 Implementation Roadmap

### Step 1: Data Model Extensions (1 hour)
- [ ] Add progression fields to WorkoutEntity
- [ ] Add progression fields to WorkoutExerciseEntity
- [ ] Create ProgressionEventEntity
- [ ] Add feedback fields to WorkoutSessionEntity

### Step 2: Repository Layer (2 hours)
- [ ] Create ExerciseRecordRepositoryProtocol
- [ ] Implement SwiftDataExerciseRecordRepository
- [ ] Create ProgressionEventRepositoryProtocol
- [ ] Implement SwiftDataProgressionEventRepository

### Step 3: Domain Layer - Strategies (3 hours)
- [ ] Create ProgressionStrategy protocol
- [ ] Implement LinearProgressionStrategy
- [ ] Implement DoubleProgressionStrategy
- [ ] Unit tests for each strategy

### Step 4: Use Cases (2 hours)
- [ ] SuggestProgressionUseCase
- [ ] RecordProgressionEventUseCase
- [ ] GetProgressionHistoryUseCase

### Step 5-7: UI & Testing (6 hours)
- [ ] ProgressionStore and UI components
- [ ] Integration testing
- [ ] User acceptance testing

**Total Estimated Time: ~14 hours**

---

## 🎯 Success Criteria

**Phase 2 is complete when:**

1. ✅ User can enable/disable auto-progression per workout
2. ✅ App suggests progression based on last 3-5 sessions
3. ✅ User can accept/decline suggestions
4. ✅ Progression events are logged to database
5. ✅ User can view progression history timeline
6. ✅ Personal records are automatically updated
7. ✅ All features have unit tests (>80% coverage)

---

## 📝 Key Integration Points with Phase 1

**No Breaking Changes Required!**

1. WorkoutEntity extensions are **optional fields** (nil = manual mode)
2. ExerciseEntity.lastUsed* already exists and working
3. SessionStore just needs to call new Use Cases
4. User can opt-in per workout

---

For complete algorithm details, UI mockups, and code examples, see sections above.

**Related Documentation:**
- `TECHNICAL_CONCEPT_V2.md` - Architecture details
- `CURRENT_STATE.md` - Current implementation status
- `TODO.md` - Prioritized task list
