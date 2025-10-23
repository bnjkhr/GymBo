# Mock Data Tracker

**⚠️ KRITISCH: Keine Produktiv-App mit Mock-Daten!**

Dieses Dokument trackt alle Stellen, wo Mock-Daten verwendet werden und müssen durch echte Daten ersetzt werden.

---

## 📋 Status Overview

| Bereich | Status | Priorität | Notizen |
|---------|--------|-----------|---------|
| Exercise Names | ✅ REAL | - | Lädt aus ExerciseRepository |
| Workout List | ✅ REAL | - | Lädt aus WorkoutRepository |
| Session Data | ✅ REAL | - | Lädt aus SessionRepository |
| SwiftUI Previews | ✅ OK | - | Mock-Daten nur in #if DEBUG |

---

## ✅ Bereits mit echten Daten

### 1. Exercise Names (Session 7)
**Status:** ✅ PRODUKTIV  
**Location:** `ActiveWorkoutSheetView.swift`  
**Implementation:**
```swift
private func loadExerciseNames() async {
    for exercise in session.exercises {
        let name = await sessionStore.getExerciseName(for: exercise.exerciseId)
        exerciseNames[exercise.exerciseId] = name
    }
}
```
**Datenquelle:** `SwiftDataExerciseRepository` → 145 echte Übungen aus CSV

---

### 2. Workout List (Session 7)
**Status:** ✅ PRODUKTIV  
**Location:** `HomeViewPlaceholder.swift`  
**Implementation:**
```swift
await workoutStore.loadWorkouts()
// Lädt über GetAllWorkoutsUseCase → SwiftDataWorkoutRepository
```
**Datenquelle:** `SwiftDataWorkoutRepository` → WorkoutSeedData (4 Test-Workouts beim ersten Start)

---

### 3. Session Data (Session 4+)
**Status:** ✅ PRODUKTIV  
**Location:** `SessionStore.swift`  
**Implementation:**
```swift
await sessionStore.startSession(workoutId: workout.id)
// Lädt über StartSessionUseCase → SwiftDataSessionRepository
```
**Datenquelle:** `SwiftDataSessionRepository` → Persistent Storage

---

## 🔧 Mock-Daten NUR in Previews (OK)

### SwiftUI Preview Helpers
**Status:** ✅ OK (nur für Development)  
**Locations:**
- `WorkoutStore.swift` → `#if DEBUG` Block
  - `MockGetAllWorkoutsUseCase`
  - `MockGetWorkoutByIdUseCase`
  - `MockToggleFavoriteUseCase`
- `SessionStore.swift` → `static var preview`
- Diverse Preview Extensions in Domain Entities

**Regel:** Mock-Daten in `#if DEBUG` Blöcken sind OK für:
- SwiftUI Previews
- Unit Tests
- UI Development

**WICHTIG:** Diese werden NICHT im Production Build kompiliert!

---

## 🚨 Zu prüfen bei neuen Features

**Checklist vor jedem Commit:**
- [ ] Verwendet das Feature Mock-Daten?
- [ ] Wenn ja: Ist es nur in `#if DEBUG`?
- [ ] Lädt das Feature Daten aus echten Repositories?
- [ ] Sind die Repositories mit SwiftData verbunden?

**Wenn Mock-Daten außerhalb von `#if DEBUG` gefunden werden:**
1. In dieses Dokument eintragen
2. Issue erstellen: "Replace Mock Data: [Feature Name]"
3. Priorität festlegen
4. Bei nächster Gelegenheit ersetzen

---

## 📊 Test-Daten vs. Mock-Daten

### Test-Daten (WorkoutSeedData, ExerciseSeedData)
**Status:** ✅ OK  
**Zweck:** 
- Erste App-Nutzung hat sinnvolle Beispiel-Daten
- User kann sofort loslegen
- Werden in echte Datenbank geseedet

**Location:** `/Infrastructure/SeedData/`
- `ExerciseSeedData.swift` - 145 echte Übungen
- `WorkoutSeedData.swift` - 4 Beispiel-Workouts

**Regel:** Seed-Daten sind OK für:
- Onboarding neuer User
- Demo-Zwecke
- Testing in Development

---

## 🎯 Nächste Schritte

**Wenn neue Features entwickelt werden:**
1. **IMMER** Repository-Pattern verwenden
2. **NIEMALS** Hardcoded-Daten in Production Code
3. Mock-Daten nur in `#if DEBUG` Blöcken
4. Neue Mock-Daten in diesem Dokument tracken

**Vor Production Release:**
- [ ] Alle Einträge in "Zu prüfen" durchgehen
- [ ] Sicherstellen: Keine Mock-Daten außerhalb `#if DEBUG`
- [ ] Seed-Daten überprüfen (sind sie sinnvoll?)

---

**Letzte Aktualisierung:** 2025-10-23  
**Status:** ✅ Alle Production-Features nutzen echte Daten
