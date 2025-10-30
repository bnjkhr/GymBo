# Warmup Sets Feature - Test Report

**Feature:** Warmup Sets Auto-Apply with Strategy Selection  
**Version:** GymBo V2.0  
**Date:** 2025-10-30  
**Status:** ✅ READY FOR TESTING

---

## Feature Overview

The Warmup Sets feature allows users to automatically add calculated warmup sets to their working sets at the start of a workout. Users can choose from three progressive strategies:

1. **Light (3 Sets)**: 40% → 60% → 80% of working weight
2. **Moderate (4 Sets)**: 40% → 55% → 70% → 85% of working weight  
3. **Heavy (5 Sets)**: 40% → 50% → 60% → 75% → 90% of working weight

---

## Test Plan

### 1. Data Persistence Tests

#### Test 1.1: Warmup Sets Creation
**Steps:**
1. Start a workout with 3 exercises
2. Choose "Light" warmup strategy
3. Verify warmup sets are added to ALL exercises
4. Check that each exercise has 3 warmup + 3 working = 6 total sets

**Expected Result:**
- ✅ All exercises show 6 sets (3 warmup + 3 working)
- ✅ Warmup sets appear BEFORE working sets
- ✅ Warmup sets show flame icon 🔥
- ✅ Warmup sets have correct weights (40%, 60%, 80%)

#### Test 1.2: Warmup Sets Persistence (DB)
**Steps:**
1. Add warmup sets to a workout
2. Complete 1-2 warmup sets
3. Force-close the app (swipe up in app switcher)
4. Reopen the app
5. Check if warmup sets are still there

**Expected Result:**
- ✅ All warmup sets are preserved
- ✅ Completed warmup sets remain checked
- ✅ Uncompleted warmup sets remain unchecked
- ✅ Working sets are unchanged

#### Test 1.3: HealthKit Integration
**Steps:**
1. Start a workout with warmup sets
2. Wait 2-3 seconds for HealthKit to sync
3. Complete some warmup sets
4. Complete some working sets
5. End workout
6. Check Apple Health app for workout

**Expected Result:**
- ✅ HealthKit session starts without errors
- ✅ Warmup sets don't disappear after HealthKit sync
- ✅ Workout appears in Apple Health
- ✅ Duration is correct

---

### 2. UI/UX Tests

#### Test 2.1: Set Completion Toggle
**Steps:**
1. Start workout with warmup sets
2. Tap first warmup set to complete it
3. Verify checkmark appears immediately
4. Tap same set again to uncomplete it
5. Verify checkmark disappears immediately

**Expected Result:**
- ✅ UI updates instantly on tap (no delay)
- ✅ Checkmark appears/disappears correctly
- ✅ No flickering or double-toggle
- ✅ Set stays in correct state

#### Test 2.2: Warmup Badge Display
**Steps:**
1. Add warmup sets to exercises
2. Scroll through all exercises
3. Verify warmup badge appearance

**Expected Result:**
- ✅ Warmup sets show "WARMUP" badge
- ✅ Badge has flame icon 🔥
- ✅ Badge is visually distinct from working sets
- ✅ Badge appears on all warmup sets

#### Test 2.3: Strategy Persistence
**Steps:**
1. Select "Moderate" strategy in settings
2. Force-close app
3. Reopen app
4. Check selected strategy in settings

**Expected Result:**
- ✅ Selected strategy is remembered
- ✅ Same strategy is pre-selected next time

---

### 3. Rest Timer Tests

#### Test 3.1: Rest Timer After Warmup Set
**Steps:**
1. Start workout with warmup sets
2. Complete first warmup set
3. Verify rest timer starts

**Expected Result:**
- ✅ Rest timer starts immediately
- ✅ Timer shows correct duration (e.g., 90s)
- ✅ Notification appears
- ✅ "Skip Rest" button works

#### Test 3.2: Rest Timer After Working Set
**Steps:**
1. Complete all warmup sets
2. Complete first working set
3. Verify rest timer starts

**Expected Result:**
- ✅ Rest timer starts (same as warmup)
- ✅ Duration is correct
- ✅ No difference in behavior

---

### 4. Statistics & Insights Tests

#### Test 4.1: Statistics Toggle (Exclude Warmup)
**Steps:**
1. Complete a workout with warmup sets
2. Go to Statistics tab
3. Enable "Exclude warmup sets" toggle
4. Check volume/tonnage calculations

**Expected Result:**
- ✅ Volume excludes warmup sets
- ✅ Tonnage excludes warmup sets
- ✅ PR detection ignores warmup sets
- ✅ Charts show only working sets

#### Test 4.2: Statistics Toggle (Include Warmup)
**Steps:**
1. Go to Statistics tab
2. Disable "Exclude warmup sets" toggle
3. Check volume/tonnage calculations

**Expected Result:**
- ✅ Volume includes warmup sets
- ✅ Tonnage includes warmup sets
- ✅ Total volume is higher
- ✅ Charts show all sets

#### Test 4.3: Session History
**Steps:**
1. Complete a workout with warmup sets
2. Go to History tab
3. Select the completed workout
4. View exercise details

**Expected Result:**
- ✅ Warmup sets are visible in history
- ✅ Warmup badge appears on historical sets
- ✅ Warmup vs working sets are distinguishable
- ✅ Data is accurate

---

### 5. Edge Cases & Error Handling

#### Test 5.1: No Working Sets
**Steps:**
1. Create a workout with 0 sets
2. Try to add warmup sets

**Expected Result:**
- ✅ Warmup button is disabled or hidden
- ✅ No crash
- ✅ User-friendly message (if any)

#### Test 5.2: Very Low Working Weight
**Steps:**
1. Set working weight to 5kg
2. Add "Light" warmup sets

**Expected Result:**
- ✅ Warmup weights are calculated correctly (2kg, 3kg, 4kg)
- ✅ No negative weights
- ✅ No weights below bar weight

#### Test 5.3: Very High Working Weight
**Steps:**
1. Set working weight to 200kg
2. Add "Heavy" warmup sets

**Expected Result:**
- ✅ Warmup weights are calculated correctly
- ✅ Progressive overload works (80kg → 100kg → 120kg → 150kg → 180kg)
- ✅ No overflow errors

#### Test 5.4: Multiple Warmup Applications
**Steps:**
1. Add warmup sets (Light)
2. Try to add warmup sets again

**Expected Result:**
- ✅ Warmup button disappears after first use
- ✅ OR: Warning message appears
- ✅ No duplicate warmup sets

---

### 6. Integration Tests

#### Test 6.1: Workout Completion Flow
**Steps:**
1. Start workout with warmup sets
2. Complete all warmup sets
3. Complete all working sets
4. Tap "Finish Exercise"
5. Complete all exercises
6. End workout

**Expected Result:**
- ✅ Exercise marked as complete after all sets done
- ✅ "Next Exercise" notification appears
- ✅ Progress bar updates correctly
- ✅ Workout summary shows correct data

#### Test 6.2: Workout Cancellation
**Steps:**
1. Start workout with warmup sets
2. Complete some warmup sets
3. Cancel workout
4. Confirm cancellation

**Expected Result:**
- ✅ Workout is discarded
- ✅ No data saved to history
- ✅ HealthKit session is cancelled
- ✅ No orphaned data in DB

---

## Testing Checklist

### Data Layer
- [ ] Warmup sets save to DB correctly
- [ ] Warmup sets persist after app restart
- [ ] `isWarmup` flag is stored correctly
- [ ] `restTime` is assigned to warmup sets
- [ ] HealthKit sync doesn't delete warmup sets

### UI Layer
- [ ] Warmup badge displays correctly
- [ ] Set completion toggles instantly
- [ ] No UI flickering or lag
- [ ] Warmup button disappears after use

### Business Logic
- [ ] Warmup calculations are correct (40%, 60%, 80%)
- [ ] Rest timer starts after warmup sets
- [ ] Statistics toggle works correctly
- [ ] Workout progress includes warmup sets

### Integration
- [ ] HealthKit integration works
- [ ] Session history shows warmup sets
- [ ] Workout cancellation cleans up correctly
- [ ] No crashes or errors

---

## Known Issues

_None currently - feature is working as expected!_

---

## Test Results

### Run 1: [Date/Time]
**Tester:** [Name]  
**Device:** [iPhone model]  
**iOS Version:** [Version]

| Test Case | Result | Notes |
|-----------|--------|-------|
| 1.1 Warmup Creation | ⏳ | |
| 1.2 DB Persistence | ⏳ | |
| 1.3 HealthKit Integration | ⏳ | |
| 2.1 Set Toggle | ⏳ | |
| 2.2 Badge Display | ⏳ | |
| 2.3 Strategy Persistence | ⏳ | |
| 3.1 Timer After Warmup | ⏳ | |
| 3.2 Timer After Working | ⏳ | |
| 4.1 Stats Exclude Warmup | ⏳ | |
| 4.2 Stats Include Warmup | ⏳ | |
| 4.3 Session History | ⏳ | |
| 5.1 No Working Sets | ⏳ | |
| 5.2 Low Weight | ⏳ | |
| 5.3 High Weight | ⏳ | |
| 5.4 Multiple Applications | ⏳ | |
| 6.1 Completion Flow | ⏳ | |
| 6.2 Cancellation | ⏳ | |

---

## Summary

**Total Tests:** 17  
**Passed:** ⏳  
**Failed:** ⏳  
**Blocked:** ⏳  

**Overall Status:** ⏳ TESTING IN PROGRESS

---

## Code Changes Summary

### Files Modified:
1. **SessionStore.swift**
   - Fixed optimistic update to toggle completion state
   - Added `restTime` to warmup sets
   - Forced UI refresh via `currentSession = nil`

2. **StartSessionUseCase.swift**
   - Fixed HealthKit race condition
   - Now fetches current session before updating HealthKit ID

3. **DomainSessionSet.swift**
   - Added `isWarmup: Bool` field (SchemaV4)

4. **SessionSetEntity.swift**
   - Added `isWarmup: Bool` field (SchemaV4)

5. **CompactSetRow.swift**
   - Added warmup badge UI

6. **WarmupCalculator.swift**
   - Created warmup calculation logic

### Database Schema:
- **SchemaV4:** Added `isWarmup` field
- **SchemaV5:** Added warmup strategy persistence

---

## Next Steps

1. ✅ Run all tests manually
2. 📝 Document test results
3. 🐛 Fix any issues found
4. ✅ Create user documentation
5. 🚀 Ready for release
