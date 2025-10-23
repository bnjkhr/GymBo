# Progression Feature - Quick Reference

**For detailed plan, see:** `PROGRESSION_FEATURE_PLAN.md`

## 📋 TL;DR

**Goal:** Auto-suggest weight/rep increases based on workout history  
**Status:** Planned for Phase 2 (after Workout Repository)  
**Estimated Time:** ~14 hours total

---

## ✅ What Already Exists (Phase 1)

1. **ExerciseEntity**: `lastUsedWeight`, `lastUsedReps`, `lastUsedDate` ✅
2. **ExerciseRecordEntity**: Personal records + 1RM calculations ✅
3. **UserProfileEntity**: Goals, experience, preferences ✅
4. **WorkoutSessionEntity**: Complete workout history ✅

**Result:** All raw data for progression algorithms is already captured! 🎉

---

## 🆕 What Needs to be Added (Phase 2)

### Minimal Data Model Extensions

**WorkoutEntity:**
```swift
var progressionStrategyRaw: String? = nil  // "linear", "double_progression"
var defaultTargetRepsMin: Int? = nil       // e.g., 8
var defaultTargetRepsMax: Int? = nil       // e.g., 12
```

**WorkoutExerciseEntity:**
```swift
var progressionIncrement: Double? = nil    // e.g., 2.5kg
var autoProgressionDisabled: Bool = false
```

**New Entity: ProgressionEventEntity**
- Tracks all progression events (weight increases, deloads, etc.)
- Used for timeline/history display

---

## 🧠 Progression Strategies

### 1. Linear Progression
- All sets completed → +2.5kg next workout
- Failed 2x → Deload -10%
- Best for: Beginners, compound lifts

### 2. Double Progression
- Start at 8 reps → increase to 12 reps
- Hit 12 reps all sets → +5kg, back to 8 reps
- Best for: Intermediate, hypertrophy

### 3. Wave Loading (Advanced)
- Heavy/Medium/Light weekly rotation
- Best for: Advanced lifters, periodization

---

## 🏗️ Implementation Order

1. **Data Model** (1h) - Add optional fields to entities
2. **Repository Layer** (2h) - ProgressionEvent + ExerciseRecord repos
3. **Domain Strategies** (3h) - Linear/Double Progression algorithms
4. **Use Cases** (2h) - Suggest/Record/History
5. **UI** (4h) - Suggestion banner, settings, timeline
6. **Testing** (2h) - Unit tests + E2E

---

## 🔗 Integration with Phase 1

**No breaking changes!**
- New fields are optional (nil = manual mode)
- User opts-in per workout
- Existing manual progression still works

---

## 📍 Current Focus

**Phase 1 (Now):** Implement Workout Repository  
**Phase 2 (Later):** Add Progression features using this plan

---

**Next Steps:**
1. Complete Workout Repository implementation
2. Review this plan before starting Phase 2
3. Implement progression features step-by-step

**Questions?** Check `PROGRESSION_FEATURE_PLAN.md` for details.
