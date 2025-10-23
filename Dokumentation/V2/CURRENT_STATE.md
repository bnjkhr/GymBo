# GymBo V2 - Aktueller Stand (2025-10-23)

**Status:** ✅ MVP PRODUCTION-READY! Exercise Reordering + Auto-Finish + Production Fixes  
**Architektur:** Clean Architecture (4 Layers) + iOS 17 @Observable  
**Design:** Workout Picker + ScrollView Active Workout + Drag & Drop Reordering

⚠️ **CRITICAL:** SwiftData Migration Support NICHT implementiert! Siehe [SWIFTDATA_MIGRATION_STRATEGY.md](SWIFTDATA_MIGRATION_STRATEGY.md)  
🔴 **Risk:** Schema Changes führen zu Datenverlust bei Production Users!

**Letzte Session (2025-10-23 - Session 6 - PRODUCTION-READY REORDERING):**
- ✅ Exercise Reordering Feature (Drag & Drop mit permanentem Speichern)
- ✅ ReorderExercisesSheet (isolierte Modal-View)
- ✅ Permanent Save Toggle (Reihenfolge dauerhaft speichern)
- ✅ Auto-Finish Exercise (wenn alle Sätze completed)
- ✅ **PRODUCTION-READY FIXES:**
  - StartSessionUseCase verwendet expliziten orderIndex
  - WorkoutMapper nutzt in-place updates
  - SessionMapper aktualisiert orderIndex korrekt
  - CompleteSetUseCase auto-finisht Übungen
- ✅ SwiftUI Observable Fix (Force UI update via nil assignment)
- ✅ MockWorkoutRepository updateExerciseOrder() Implementation

**Session 5 (2025-10-23 - WORKOUT REPOSITORY):**
- ✅ Workout Repository mit vollständiger Clean Architecture
- ✅ Workout Picker UI mit Favoriten-Support
- ✅ StartSessionUseCase lädt echte Workouts
- ✅ Progressive Overload mit lastUsed Values
- ✅ Workout Seed Data (Push/Pull/Legs)
- ✅ WorkoutStore (@Observable) für UI
- ✅ 13 neue Dateien, 7 geändert, ~1500 LOC

**Session 4 (2025-10-23):**
- ✅ Add Set Feature (Quick-Add Field + Plus Button)
- ✅ Delete Set Feature (Long-Press Context Menu)
- ✅ AddSetUseCase + RemoveSetUseCase mit Clean Architecture
- ✅ Regex Parser für Quick-Add Field ("100 x 8" Format)
- ✅ Business Rules (Cannot delete last set)
- ✅ Haptic Feedback (Success + Impact)

**Session 3 (2025-10-23):**
- ✅ "Update All Sets" Feature (Toggle in EditSetSheet)
- ✅ Alle incomplete Sets auf einmal aktualisieren
- ✅ Mark All Complete Bug Fix (UI Refresh)
- ✅ Workout Summary Persistence Fix
- ✅ Equipment Display in UI
- ✅ UpdateAllSetsUseCase mit Clean Architecture

**Session 2 (2025-10-23):**
- ✅ Exercise Names in UI (aus Datenbank geladen)
- ✅ Last Used Values beim Session Start (Progressive Overload!)
- ✅ Sofortiges UI Update nach Save (Forced Observable Update)
- ✅ Rounded Fonts entfernt (Standard System Font)
- ✅ Kompletter Progressive Overload Cycle funktioniert!

**Session 1 (2025-10-23):**
- ✅ Editable Weight/Reps mit Sheet-Based UI
- ✅ Exercise History Persistence (lastUsedWeight/Reps)
- ✅ Exercise Seeding (3 Test-Übungen)
- ✅ Kompletter End-to-End Workflow funktioniert

---

## 📊 Implementierungsstatus

### ✅ NEU IMPLEMENTIERT (Session 6 - 2025-10-23 - PRODUCTION-READY REORDERING)

**1. Exercise Reordering Feature (Full Implementation)**
- ✅ **ReorderExercisesSheet** - Isolierte Modal-View für Drag & Drop
  - Dedicated List mit `.onMove()` (verhindert Button-Auto-Trigger Bug)
  - Live Preview der neuen Reihenfolge
  - Toggle "Reihenfolge dauerhaft speichern"
  - "Fertig" / "Abbrechen" Buttons
  - Toolbar mit Reorder-Button (arrow.up.arrow.down Icon)
  
- ✅ **SessionStore.reorderExercises()** - Komplett überarbeitet
  - Neue Signatur: `reorderExercises(reorderedExercises: [DomainSessionExercise], savePermanently: Bool)`
  - Optimistic Updates für sofortiges UI Feedback
  - **Force SwiftUI Update** via `currentSession = nil` → `currentSession = updatedSession`
  - Conditional Persistence: Session-only ODER Workout Template
  
- ✅ **WorkoutRepository.updateExerciseOrder()** - Neue Methode für permanentes Speichern
  - Direct in-place update von `orderIndex` ohne Entity-Recreation
  - Verhindert "PersistentIdentifier remapped" Errors
  - Performance optimiert
  
- ✅ **ActiveWorkoutSheetView Updates**
  - Replaced List mit ScrollView + VStack (verhindert Drag-and-Drop Bug)
  - ReorderExercisesSheet als `.sheet()` Presentation
  - Reorder-Button in Toolbar
  - Sortiert nach orderIndex

**2. Auto-Finish Exercise Feature**
- ✅ **CompleteSetUseCase - Auto-Finish Logic**
  ```swift
  // Auto-finish wenn alle Sätze completed
  let allSetsCompleted = exercise.sets.allSatisfy { $0.completed }
  if allSetsCompleted && !exercise.isFinished {
      exercise.isFinished = true
  }
  // Auto un-finish wenn Satz wieder abgehakt wird
  else if !allSetsCompleted && exercise.isFinished {
      exercise.isFinished = false
  }
  ```
  
- ✅ **UI Behavior**
  - Letzen Satz abhaken → Übung wird automatisch ausgeblendet
  - Abgehakten Satz wieder abhaken → Übung erscheint wieder
  - Eye-Toggle zeigt ausgeblendete Übungen
  - "Mark All Complete" Button funktioniert weiterhin (FinishExerciseUseCase)

**3. PRODUCTION-READY FIXES (Critical für Robustheit)**

**Fix 1: StartSessionUseCase - Expliziter orderIndex**
```swift
// VORHER (fragil - nutzte Array-Position):
for (index, workoutExercise) in workoutExercises.enumerated() {
    orderIndex: index  // ❌ Abhängig von Array-Reihenfolge
}

// NACHHER (robust - nutzt expliziten Wert):
for workoutExercise in workoutExercises {
    orderIndex: workoutExercise.orderIndex  // ✅ Explizit aus Template
}
```
**Vorteil:** Funktioniert auch wenn Workout-Array unsortiert ist

**Fix 2: WorkoutMapper - In-Place Updates**
```swift
// VORHER (ineffizient + gefährlich):
entity.exercises.removeAll()  // ❌ Löscht alle
entity.exercises = domain.exercises.map { toEntity($0) }  // ❌ Neu erstellen

// NACHHER (in-place + safe):
for domainExercise in domain.exercises {
    if let existing = entity.exercises.first(where: { $0.id == domainExercise.id }) {
        updateExerciseEntity(existing, from: domainExercise)  // ✅ Update
    } else {
        entity.exercises.append(toEntity(domainExercise))  // ✅ Nur neue
    }
}
entity.exercises.removeAll { !domainIds.contains($0.id) }  // ✅ Nur deleted
```
**Vorteile:**
- Erhält SwiftData-Beziehungen
- Keine "PersistentIdentifier remapped" Errors
- Performance optimiert
- Konsistent mit SessionMapper

**Fix 3: SessionMapper - orderIndex Updates**
```swift
private func updateExerciseEntity(_ entity: SessionExerciseEntity, from domain: DomainSessionExercise) {
    entity.exerciseId = domain.exerciseId
    entity.notes = domain.notes
    entity.restTimeToNext = domain.restTimeToNext
    entity.orderIndex = domain.orderIndex  // ✅ JETZT inkludiert!
    entity.isFinished = domain.isFinished
    // ... update sets
}
```
**Vorher:** orderIndex wurde beim Update ignoriert → Reorder nicht persistiert  
**Nachher:** orderIndex wird korrekt gespeichert

**4. Bug Fixes**
- ✅ **SwiftUI Observable Detection** - Force UI update via nil assignment
- ✅ **Button Auto-Trigger Bug** - List drag-and-drop triggerte Buttons automatisch
  - Root Cause: `DragAndDropBridge` in SwiftUI List
  - Fix: Reorder in separater Sheet mit isoliertem List
- ✅ **Exercise nicht ausgeblendet** - Auto-finish implementiert
- ✅ **MockWorkoutRepository** - updateExerciseOrder() Implementation für Tests

**5. Technical Improvements**
- ✅ Konsistente Mapper-Patterns (Session + Workout)
- ✅ Production-ready orderIndex Handling
- ✅ In-place updates überall
- ✅ Future-proof für Workout-Editor UI

---

### ✅ IMPLEMENTIERT (Session 5 - 2025-10-23 - WORKOUT REPOSITORY)

**1. Domain Layer - Workout Entities**
- ✅ Workout.swift - Workout Template Entity
  - ID, Name, Exercises, DefaultRestTime
  - Notes, CreatedAt, UpdatedAt, IsFavorite
  - Computed: exerciseCount, totalSets, estimatedDuration
- ✅ WorkoutExercise.swift - Exercise Template
  - ExerciseId, TargetSets, TargetReps, TargetWeight
  - RestTime, OrderIndex, Notes

**2. Domain Layer - Repository & Use Cases**
- ✅ WorkoutRepositoryProtocol
  - save, update, fetch, fetchAll, fetchFavorites, search, delete
  - MockWorkoutRepository für Tests
- ✅ GetAllWorkoutsUseCase
  - Lädt alle Workouts sortiert (Favoriten zuerst)
- ✅ GetWorkoutByIdUseCase
  - Lädt einzelnes Workout mit Validierung

**3. Data Layer - Repository & Mapper**
- ✅ SwiftDataWorkoutRepository
  - Vollständige CRUD Implementation
  - WorkoutEntity (bereits vorhanden) wird wiederverwendet
  - Favorites Filtering, Search
- ✅ WorkoutMapper
  - Bidirektionales Mapping: Workout ↔ WorkoutEntity
  - WorkoutExercise → WorkoutExerciseEntity Konvertierung
  - Sets werden aus targetSets generiert

**4. Presentation Layer - Store & UI**
- ✅ WorkoutStore (@Observable)
  - loadWorkouts, refresh, loadWorkout(id:)
  - Computed: favoriteWorkouts, regularWorkouts
  - Error handling & loading states
- ✅ HomeViewPlaceholder - Workout Picker
  - Liste aller Workouts mit Favoriten-Sektion
  - WorkoutRow Component (Icon, Name, Stats)
  - Continue Session View
  - Pull-to-refresh Support

**5. Infrastructure - Seed Data & DI**
- ✅ WorkoutSeedData
  - Push Day: Bankdrücken 4×8 @ 100kg ⭐
  - Pull Day: Lat Pulldown 3×10 @ 80kg
  - Leg Day: Kniebeugen 4×12 @ 60kg ⭐
- ✅ DependencyContainer Updates
  - makeWorkoutRepository()
  - makeGetAllWorkoutsUseCase(), makeGetWorkoutByIdUseCase()
  - makeWorkoutStore()
  - makeStartSessionUseCase() mit WorkoutRepository
- ✅ DependencyContainerEnvironmentKey
  - Environment-Support für DI Container

**6. StartSessionUseCase - Komplett überarbeitet**
- ✅ Lädt echte Workouts via WorkoutRepository
- ✅ convertToSessionExercises() implementiert
  - WorkoutExercise → SessionExercise Konvertierung
  - Progressive Overload: lastUsedWeight/Reps aus ExerciseEntity
  - Fallback zu Template-Werten wenn keine History
  - Dynamische Set-Anzahl aus Workout Template
- ✅ Keine Hardcoded Test-Data mehr

**7. Dokumentation für Phase 2**
- ✅ PROGRESSION_FEATURE_PLAN.md
  - Vollständige Spezifikation (~14h geschätzt)
  - Data Model Extensions (optional, backward compatible)
  - 3 Progression Strategien (Linear, Double, Wave)
  - Use Cases, Repositories, UI Components
  - Implementation Roadmap
- ✅ PROGRESSION_QUICK_REF.md
  - Quick Reference für Phase 2
  - TL;DR: Was existiert vs. was fehlt

### ✅ NEU IMPLEMENTIERT (Session 4 - 2025-10-23)

**1. Add Set Feature**
- ✅ Quick-Add TextField mit Regex Parser
  - Regex: `#"(\d+(?:\.\d+)?)\s*[xX×]\s*(\d+)"#`
  - Beispiel: "100 x 8" → 100.0kg, 8 reps
  - Leert sich automatisch nach Add
- ✅ Plus Button für schnelles Hinzufügen
  - Nutzt letzte Set-Werte als Default
  - Deaktiviert wenn kein letztes Set vorhanden
- ✅ AddSetUseCase implementiert (Clean Architecture)
  - Domain Layer: Use Case mit Business Logic
  - Fallback auf letzte Set-Werte wenn keine angegeben
  - Aktualisiert Exercise History (Progressive Overload)
  - Persistence via SessionRepository
- ✅ Haptic Success Feedback beim Hinzufügen

**2. Delete Set Feature**
- ✅ Long-Press Context Menu auf jedem Set
  - Zeigt "Satz löschen" mit Trash Icon
  - Destructive Role (rot eingefärbt)
- ✅ RemoveSetUseCase implementiert (Clean Architecture)
  - Business Rule: Minimum 1 Set pro Exercise
  - Validierung: Cannot remove last set
  - Proper Error Handling
- ✅ Haptic Impact Feedback beim Löschen
- ✅ UI disabled für letzten Satz

**3. Set Management Integration**
- ✅ SessionStore.addSet(exerciseId, weight, reps)
- ✅ SessionStore.removeSet(exerciseId, setId)
- ✅ DependencyContainer Factory Methods
  - makeAddSetUseCase()
  - makeRemoveSetUseCase()
- ✅ Forced Observable Updates für sofortiges UI Feedback
- ✅ Compiler Timeout Fix (exerciseCardView() extraction)

### ✅ NEU IMPLEMENTIERT (Session 3 - 2025-10-23)

**1. Update All Sets Feature**
- ✅ Toggle "Alle Sätze aktualisieren" in EditSetSheet
  - Orange Toggle (App Accent Color)
  - German UI Text: "Werte für alle verbleibenden Sätze übernehmen"
  - Aktualisiert nur incomplete Sets
- ✅ UpdateAllSetsUseCase implementiert (Clean Architecture)
  - Domain Layer: Use Case mit Validierung
  - Presentation Layer: SessionStore.updateAllSets()
  - UI Layer: Callbacks durch alle Komponenten
- ✅ Forced Observable Update für sofortiges UI Feedback
- ✅ Haptic Success Feedback
- ✅ Progressive Overload Integration (lastUsed* wird aktualisiert)

**2. Equipment Display**
- ✅ SessionStore.getExerciseEquipment() implementiert
- ✅ Equipment in CompactExerciseCard angezeigt
- ✅ Lädt asynchron wie Exercise Names

**3. Debug Improvements**
- ✅ Debug Logging für markAllSetsComplete()
  - Zeigt Exercise ID, Total Sets, Set Details
  - Hilft "0 sets marked complete" Bug zu diagnostizieren

### ✅ NEU IMPLEMENTIERT (Session 2 - 2025-10-23)

**1. Progressive Overload - Kompletter Cycle**
- ✅ Exercise Names in UI angezeigt (aus Datenbank geladen)
- ✅ ExerciseRepository.fetch(id:) implementiert
- ✅ SessionStore lädt Exercise Namen asynchron
- ✅ ActiveWorkoutSheetView zeigt echte Namen statt "Übung 1, 2, 3"
- ✅ Last Used Values beim Session Start
  - StartSessionUseCase lädt lastUsedWeight/Reps aus Exercise-DB
  - Sets starten mit letzten Werten statt Hardcoded Defaults
  - Automatischer Progressive Overload!

**2. UI/UX Verbesserungen**
- ✅ Sofortiges UI Update nach Save (nicht erst beim Abhaken)
  - Forced Observable Update (`currentSession = nil` → `currentSession = session`)
  - `.id()` modifier für CompactExerciseCard basierend auf Set-Werten
- ✅ Rounded Fonts entfernt
  - Alle `.design: .rounded` zu Standard System Font geändert
  - CompactSetRow, TimerSection, EditSetSheet

### ✅ NEU IMPLEMENTIERT (Session 1 - 2025-10-23)

**1. Editable Weight/Reps**
- ✅ Sheet-basierte Editing UI (statt inline TextFields)
- ✅ Tap auf Weight/Reps öffnet EditSetSheet
- ✅ Große, gut bedienbare TextFields mit Number Keyboard
- ✅ "Fertig" / "Abbrechen" Buttons
- ✅ Auto-Focus auf Weight-Feld
- ✅ `.presentationDetents([.height(280)])` für kompakte Sheet-Größe
- ✅ Validierung (weight > 0, reps > 0)
- ✅ Optimistic Updates für sofortiges UI-Feedback

**2. Exercise History Persistence**
- ✅ ExerciseRepositoryProtocol erstellt
- ✅ SwiftDataExerciseRepository implementiert
- ✅ UpdateSetUseCase aktualisiert ExerciseEntity.lastUsedWeight/Reps/Date
- ✅ Werte werden bei jedem Edit persistiert
- ✅ Bereit für Progressive Overload (nächstes Workout lädt letzte Werte)

**3. Exercise Database Seeding**
- ✅ ExerciseSeedData erstellt (3 Test-Übungen)
  - Bankdrücken (100kg x 8 reps)
  - Lat Pulldown (80kg x 10 reps)
  - Kniebeugen (60kg x 12 reps)
- ✅ Seed läuft beim ersten App-Start
- ✅ StartSessionUseCase lädt echte Exercise IDs aus Datenbank
- ✅ Keine "Exercise not found" Warnungen mehr

**4. Repository Erweiterungen**
- ✅ ExerciseRepository.findByName() für Exercise-Lookup
- ✅ ExerciseRepository.fetch(id:) für Exercise-Details
- ✅ ExerciseRepository.updateLastUsed() für History
- ✅ StartSessionUseCase nutzt findByName() + fetch() für Test-Data

### ✅ VORHER IMPLEMENTIERT (Funktioniert)

**1. Clean Architecture Foundation**
- ✅ Domain Layer (Entities, Use Cases, Repository Protocols)
- ✅ Data Layer (SwiftData Repositories, Mappers)
- ✅ Presentation Layer (Stores, Views)
- ✅ Infrastructure Layer (DependencyContainer, SeedData)

**2. Session Management**
- ✅ Start Session Use Case
- ✅ Complete Set Use Case
- ✅ End Session Use Case
- ✅ **Update Set Use Case** (NEU - Weight/Reps editing)
- ✅ Session Repository (SwiftData)
- ✅ Session Mapper (mit in-place updates)

**3. Active Workout UI**
- ✅ Timer Section (Rest + Duration Timer)
- ✅ ScrollView mit allen Übungen
- ✅ Compact Exercise Cards
- ✅ **Compact Set Rows mit Sheet-Editing** (NEU)
- ✅ Set Completion mit Haptic Feedback
- ✅ Eye-Icon Toggle (Show/Hide completed)
- ✅ Exercise Counter
- ✅ Workout Summary View

**4. State Management**
- ✅ SessionStore (@Observable)
- ✅ RestTimerStateManager
- ✅ DependencyContainer

**5. Persistence**
- ✅ SwiftData Schema (Session + Exercise Entities)
- ✅ Session Restoration
- ✅ **Exercise History Persistence** (NEU)
- ✅ In-Place Updates

---

## 🆕 Wichtigste Änderungen dieser Session

### 1. Sheet-Based Editing (statt inline TextFields)

**Problem mit inline TextFields:**
- "Invalid frame dimension" Crashes
- Komplexes Focus Management
- Frame-Berechnungsprobleme in ForEach

**Neue Lösung:**
```swift
// CompactSetRow.swift
Button {
    if !set.completed {
        editingWeight = formatNumber(set.weight)
        editingReps = "\(set.reps)"
        showEditSheet = true  // ← Öffnet Sheet
    }
} label: {
    HStack(spacing: 4) {
        Text(formatNumber(set.weight))
            .font(.system(size: 28, weight: .bold))
        Text("kg")
            .font(.system(size: 16))
    }
}
.sheet(isPresented: $showEditSheet) {
    EditSetSheet(...)
}
```

**Vorteile:**
- ✅ Keine Crashes
- ✅ Bessere UX (fokussiertes Editing)
- ✅ Standard iOS Pattern
- ✅ Einfaches Keyboard Management
- ✅ Klare "Fertig" / "Abbrechen" Actions

### 2. Exercise History End-to-End

**Workflow:**
```
1. User ändert Gewicht 100kg → 105kg
   ↓
2. CompactSetRow → EditSetSheet
   ↓
3. "Fertig" → onUpdateWeight(105.0)
   ↓
4. ActiveWorkoutSheetView → sessionStore.updateSet()
   ↓
5. UpdateSetUseCase:
   - Speichert in Session (SessionRepository)
   - Aktualisiert ExerciseEntity (ExerciseRepository)
   ↓
6. ExerciseEntity.lastUsedWeight = 105.0
   ExerciseEntity.lastUsedDate = now()
   ↓
7. Nächstes Workout: Sets mit 105kg vorausgefüllt
```

**Console Output:**
```
✏️ Update weight: setId [...], newWeight 105.0
✏️ Updated local weight to 105.0
✅ Updated exercise Bankdrücken: lastWeight=105.0, lastReps=8
```

### 3. Exercise Seeding

**ExerciseSeedData.swift:**
```swift
static func seedIfNeeded(context: ModelContext) {
    let descriptor = FetchDescriptor<ExerciseEntity>()
    let existingCount = (try? context.fetchCount(descriptor)) ?? 0
    
    if existingCount > 0 {
        print("📊 Exercises already seeded")
        return
    }
    
    // Create 3 test exercises
    let exercises = [
        ExerciseEntity(
            name: "Bankdrücken",
            lastUsedWeight: 100.0,
            lastUsedReps: 8
        ),
        // ... Lat Pulldown, Kniebeugen
    ]
    
    for exercise in exercises {
        context.insert(exercise)
    }
    try context.save()
}
```

**Integration in GymBoApp.swift:**
```swift
@MainActor
private func performStartupTasks() async {
    // Seed exercises on first launch
    ExerciseSeedData.seedIfNeeded(context: container.mainContext)
    
    // Load active session
    await sessionStore.loadActiveSession()
}
```

---

## 🏗️ Projektstruktur (Updated)

```
GymBo/
├── Domain/
│   ├── Entities/
│   │   ├── WorkoutSession.swift
│   │   ├── SessionExercise.swift
│   │   └── SessionSet.swift
│   ├── UseCases/Session/
│   │   ├── StartSessionUseCase.swift
│   │   ├── CompleteSetUseCase.swift
│   │   ├── EndSessionUseCase.swift
│   │   ├── UpdateSetUseCase.swift
│   │   ├── UpdateAllSetsUseCase.swift
│   │   ├── AddSetUseCase.swift             # ← NEU (Session 4)
│   │   └── RemoveSetUseCase.swift          # ← NEU (Session 4)
│   └── RepositoryProtocols/
│       ├── SessionRepositoryProtocol.swift
│       └── ExerciseRepositoryProtocol.swift
│
├── Data/
│   ├── Repositories/
│   │   ├── SwiftDataSessionRepository.swift
│   │   └── SwiftDataExerciseRepository.swift # ← NEU
│   ├── Mappers/
│   │   └── SessionMapper.swift
│   └── SwiftDataEntities.swift              # ExerciseEntity mit lastUsed*
│
├── Presentation/
│   ├── Stores/
│   │   └── SessionStore.swift               # addSet(), removeSet() added
│   └── Views/ActiveWorkout/Components/
│       ├── CompactSetRow.swift              # ← Sheet-based editing
│       ├── CompactExerciseCard.swift        # ← Quick-Add + Context Menu
│       └── EditSetSheet.swift               # ← in CompactSetRow.swift
│
├── Infrastructure/
│   ├── DI/
│   │   └── DependencyContainer.swift        # ExerciseRepository added
│   └── SeedData/
│       └── ExerciseSeedData.swift           # ← NEU
│
└── GymBoApp.swift                           # Seed-Aufruf added
```

---

## 🔧 Technische Details (Updated)

### 1. AddSetUseCase (Session 4)

```swift
final class DefaultAddSetUseCase: AddSetUseCase {
    private let repository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol

    func execute(
        sessionId: UUID,
        exerciseId: UUID,
        weight: Double?,
        reps: Int?
    ) async throws -> DomainWorkoutSession {
        // 1. Fetch active session
        guard var session = try await repository.fetchActiveSession() else {
            throw AddSetError.sessionNotFound(sessionId)
        }

        // 2. Find exercise index
        guard let exerciseIndex = session.exercises.firstIndex(
            where: { $0.id == exerciseId }
        ) else {
            throw AddSetError.exerciseNotFound(exerciseId)
        }

        // 3. Determine weight and reps (fallback to last set's values)
        let lastSet = session.exercises[exerciseIndex].sets.last
        let finalWeight = weight ?? lastSet?.weight ?? 0.0
        let finalReps = reps ?? lastSet?.reps ?? 0

        // 4. Create new set
        let newSet = DomainSessionSet(
            weight: finalWeight,
            reps: finalReps,
            completed: false
        )

        // 5. Add set to exercise
        session.exercises[exerciseIndex].sets.append(newSet)

        // 6. Persist changes
        try await repository.update(session)

        // 7. Update exercise history
        try? await exerciseRepository.updateLastUsed(
            exerciseId: session.exercises[exerciseIndex].catalogExerciseId,
            weight: finalWeight,
            reps: finalReps,
            date: Date()
        )

        return session
    }
}
```

### 2. RemoveSetUseCase (Session 4)

```swift
final class DefaultRemoveSetUseCase: RemoveSetUseCase {
    private let repository: SessionRepositoryProtocol

    func execute(
        sessionId: UUID,
        exerciseId: UUID,
        setId: UUID
    ) async throws -> DomainWorkoutSession {
        // 1. Fetch active session
        guard var session = try await repository.fetchActiveSession() else {
            throw RemoveSetError.sessionNotFound(sessionId)
        }

        // 2. Find exercise and set indices
        guard let exerciseIndex = session.exercises.firstIndex(
            where: { $0.id == exerciseId }
        ) else {
            throw RemoveSetError.exerciseNotFound(exerciseId)
        }

        guard let setIndex = session.exercises[exerciseIndex].sets.firstIndex(
            where: { $0.id == setId }
        ) else {
            throw RemoveSetError.setNotFound(setId)
        }

        // 3. Business rule: Cannot remove last set
        guard session.exercises[exerciseIndex].sets.count > 1 else {
            throw RemoveSetError.cannotRemoveLastSet
        }

        // 4. Remove set
        session.exercises[exerciseIndex].sets.remove(at: setIndex)

        // 5. Persist changes
        try await repository.update(session)

        return session
    }
}
```

### 3. Quick-Add Field Regex Parser

```swift
// In CompactExerciseCard.swift
private func parseSetInput(_ input: String) -> (weight: Double, reps: Int)? {
    // Regex: "100 x 8" or "100.5 × 12" or "80X10"
    let pattern = #"(\d+(?:\.\d+)?)\s*[xX×]\s*(\d+)"#

    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(
              in: input,
              range: NSRange(input.startIndex..., in: input)
          ),
          match.numberOfRanges == 3 else {
        return nil
    }

    // Extract weight (group 1)
    let weightRange = Range(match.range(at: 1), in: input)!
    let weightString = String(input[weightRange])

    // Extract reps (group 2)
    let repsRange = Range(match.range(at: 2), in: input)!
    let repsString = String(input[repsRange])

    guard let weight = Double(weightString),
          let reps = Int(repsString),
          weight > 0,
          reps > 0 else {
        return nil
    }

    return (weight, reps)
}
```

### 4. UpdateSetUseCase

```swift
final class DefaultUpdateSetUseCase: UpdateSetUseCase {
    private let repository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    
    func execute(
        sessionId: UUID,
        exerciseId: UUID,
        setId: UUID,
        weight: Double? = nil,
        reps: Int? = nil
    ) async throws -> DomainWorkoutSession {
        // 1. Update Session
        // ... (update set in session)
        try await repository.update(session)
        
        // 2. Update Exercise History
        let finalWeight = set.weight
        let finalReps = set.reps
        
        try? await exerciseRepository.updateLastUsed(
            exerciseId: catalogExerciseId,
            weight: finalWeight,
            reps: finalReps,
            date: Date()
        )
        
        return session
    }
}
```

### 5. ExerciseRepository

```swift
protocol ExerciseRepositoryProtocol {
    func updateLastUsed(
        exerciseId: UUID,
        weight: Double,
        reps: Int,
        date: Date
    ) async throws
    
    func findByName(_ name: String) async throws -> UUID?
}

// SwiftData Implementation
final class SwiftDataExerciseRepository: ExerciseRepositoryProtocol {
    func updateLastUsed(...) async throws {
        let descriptor = FetchDescriptor<ExerciseEntity>(
            predicate: #Predicate { $0.id == exerciseId }
        )
        
        guard let exercise = try modelContext.fetch(descriptor).first else {
            return // Silently ignore if not found
        }
        
        exercise.lastUsedWeight = weight
        exercise.lastUsedReps = reps
        exercise.lastUsedDate = date
        
        try modelContext.save()
    }
}
```

### 6. ExerciseEntity Schema

```swift
@Model
final class ExerciseEntity {
    var id: UUID
    var name: String
    
    // Exercise History (für Progressive Overload)
    var lastUsedWeight: Double?     // ← NEU persistiert
    var lastUsedReps: Int?          // ← NEU persistiert
    var lastUsedDate: Date?         // ← NEU persistiert
    var lastUsedSetCount: Int?
    var lastUsedRestTime: TimeInterval?
    
    // ... muscleGroups, equipment, etc.
}
```

---

## 🐛 Behobene Bugs (diese Session)

### ~~6. TextField Crashes (Invalid frame dimension)~~ ✅ GEFIXT
**Problem:** Inline TextFields verursachten Frame-Berechnungsfehler  
**Versuche:**
- `.fixedSize()` statt `.frame(minWidth:)` → Crash
- Toolbar an verschiedenen Stellen → Crash
- Focus Management mit onChange → Crash  

**Finale Lösung:** Komplett anderer Ansatz
- Sheet-based Editing statt inline TextFields
- Keine Frame-Berechnungen in ForEach
- Separate EditSetSheet View
- Standard iOS Pattern

**Status:** ✅ FUNKTIONIERT perfekt

### ~~7. Exercise not found Warnings~~ ✅ GEFIXT
**Problem:** `⚠️ Exercise not found: F5BEEF6D-...`  
**Ursache:** StartSessionUseCase verwendete random UUIDs  
**Fix:**
- Exercise Database Seeding implementiert
- StartSessionUseCase lädt echte IDs via `findByName()`
- UpdateSetUseCase findet jetzt die Exercises

**Status:** ✅ FUNKTIONIERT

---

## ⏳ Was FEHLT noch (TODO)

### 1. ~~Exercise Names in UI~~ ✅ ERLEDIGT
**Status:** ✅ KOMPLETT
**Implementiert:** ActiveWorkoutSheetView lädt Namen via SessionStore.getExerciseName()

### 2. ~~Load Last Used Values on Session Start~~ ✅ ERLEDIGT
**Status:** ✅ KOMPLETT
**Implementiert:** StartSessionUseCase nutzt lastUsedWeight/Reps aus Exercise-DB

### 3. ~~Update All Sets Feature~~ ✅ ERLEDIGT
**Status:** ✅ KOMPLETT
**Implementiert:** UpdateAllSetsUseCase + Toggle in EditSetSheet

### 4. ~~Equipment Display~~ ✅ ERLEDIGT
**Status:** ✅ KOMPLETT
**Implementiert:** SessionStore.getExerciseEquipment() + UI Integration

### 5. ~~Mark All Complete Bug~~ ✅ ERLEDIGT
**Status:** ✅ GEFIXT (Session 3)
**Problem:** UI zeigte keine grünen Haken nach Mark All Complete
**Fix:** Forced Observable Update mit fresh session fetch

### 6. ~~Add/Remove Sets während Session~~ ✅ ERLEDIGT
**Status:** ✅ KOMPLETT (Session 4)
**Implementiert:**
- AddSetUseCase + RemoveSetUseCase
- Quick-Add Field mit Regex Parser
- Plus Button mit Last-Set Fallback
- Long-Press Context Menu für Delete
- Business Rules (Cannot delete last set)

### 7. ~~Workout Repository~~ ✅ ERLEDIGT
**Status:** ✅ KOMPLETT (Session 5)
**Implementiert:**
- Vollständige Clean Architecture (Domain → Data → Presentation)
- WorkoutRepositoryProtocol + SwiftDataWorkoutRepository
- GetAllWorkoutsUseCase + GetWorkoutByIdUseCase
- WorkoutStore + Workout Picker UI
- Workout Seed Data (Push/Pull/Legs)
- StartSessionUseCase lädt echte Workouts
- Progressive Overload mit lastUsed Values

### 8. ~~Progression Features (Phase 2)~~ 📋 DOKUMENTIERT
**Status:** 📋 Vollständig geplant (PROGRESSION_FEATURE_PLAN.md)
**Geschätzt:** ~14 Stunden Implementation
**Enthält:**
- Data Model Extensions (optional, backward compatible)
- 3 Progression Strategien (Linear, Double, Wave Loading)
- Use Cases: SuggestProgressionUseCase, RecordProgressionEventUseCase
- UI: Progression Banner, Settings, Timeline
- ProgressionEventEntity für History Tracking

### 9. Reorder Exercises/Sets
**Status:** 🔴 FEHLT
**UI:** Buttons vorhanden
**Benötigt:** Drag & Drop + `ReorderUseCase`

### 10. Workout History & Statistics
**Status:** 🔴 FEHLT

### 11. Tests
**Status:** 🔴 FEHLT

---

## 📋 Nächste Schritte (Empfehlung)

### Quick Wins (30-60 Min)

1. **~~"Mark All Complete" Button~~ ✅ ERLEDIGT (Session 3)**
   - ✅ Bug gefixt (UI Refresh mit forced Observable update)
   - ✅ Workout Summary Persistence gefixt
   - ✅ Workout Complete Message implementiert

2. **~~Equipment in UI anzeigen~~ ✅ ERLEDIGT (Session 3)**
   - ✅ SessionStore.getExerciseEquipment()
   - ✅ CompactExerciseCard zeigt Equipment
   - ✅ Asynchrones Laden wie Exercise Names

3. **~~Add/Remove Sets~~ ✅ ERLEDIGT (Session 4)**
   - ✅ AddSetUseCase implementiert
   - ✅ Quick-Add TextField mit Regex Parser ("100 x 8")
   - ✅ RemoveSetUseCase + Long-Press Context Menu
   - ✅ Business Rules (Cannot delete last set)

### Mittelfristig (4-8 Stunden)

4. **~~Workout Repository~~ ✅ ERLEDIGT (Session 5)**
   - ✅ Clean Architecture komplett implementiert
   - ✅ Workout Picker in HomeView
   - ✅ Echte Templates (Push/Pull/Legs)
   - ✅ Progressive Overload funktioniert

5. **Reordering (2-3 Stunden)**
   - `.onMove` für Exercises
   - `.onMove` für Sets  
   - ReorderUseCase

6. **Progression Features - Phase 2 (~14 Stunden)**
   - Siehe PROGRESSION_FEATURE_PLAN.md
   - Data Model Extensions
   - Progression Strategies Implementation
   - UI Components (Banner, Settings, Timeline)

---

## 🎓 Lessons Learned (Updated)

### 5. SwiftUI TextField in ForEach ist problematisch
**Problem:** Inline TextFields in ForEach → Frame-Crashes  
**Lösung:** Sheet-based Editing Pattern
- Separate View für Editing
- Keine Frame-Berechnungen im Loop
- Bessere UX durch fokussierte UI

### 6. Progressive Overload braucht Exercise History
**Wichtig:** ExerciseEntity.lastUsed* ist fundamental
- Nutzer will sehen: "Letztes Mal: 100kg x 8"
- Nächstes Training: Automatisch vorausgefüllt
- Foundation für Progression Tracking

### 7. Database Seeding ist essential für Development
**Warum:** Ohne Seed-Data sind IDs random
- Exercise History funktioniert nicht
- Testing ist schwierig
- UX leidet (keine Namen, keine History)

### 8. Clean Architecture zahlt sich aus
**Learnings aus Session 5:**
- Workout Repository in 3-4h implementiert (durch klare Layer)
- Keine Breaking Changes (optional fields, backward compatible)
- Wiederverwendung von WorkoutEntity (bereits vorhanden)
- Testing: MockRepositories funktionieren perfekt
- Dependency Injection macht alles einfach austauschbar

---

## 🚀 Current State Summary

**Was jetzt funktioniert (End-to-End):**

1. ✅ **App Start** → Seeds 3 Exercises + 4 Workouts (first launch)
2. ✅ **Workout Picker** → Liste mit Favoriten (Push/Pull/Legs/TEST)
3. ✅ **Start Workout** → Lädt echtes Workout Template aus DB
4. ✅ **Exercise Names** → Echte Namen aus Workout
5. ✅ **Progressive Overload** → Sets starten mit letzten Werten
6. ✅ **Exercise Reordering** → Drag & Drop mit permanentem Speichern
   - Reorder-Button in Toolbar öffnet Sheet
   - Toggle "Reihenfolge dauerhaft speichern"
   - Session-only ODER Workout Template Update
7. ✅ **Tap Weight/Reps** → Sheet öffnet sich
8. ✅ **Edit Values** → Große, gut bedienbare TextFields
9. ✅ **Update All Sets** → Toggle für alle incomplete Sets
10. ✅ **Add Set** → Quick-Add Field ("100 x 8") + Plus Button
11. ✅ **Delete Set** → Long-Press Context Menu
12. ✅ **Auto-Finish Exercise** → Automatisch ausgeblendet nach letztem Satz
13. ✅ **Mark All Complete** → Alle Sets auf einmal abhaken (FinishExerciseUseCase)
14. ✅ **Workout Complete** → Summary Sheet mit Statistiken
15. ✅ **Exercise History** → lastUsedWeight/Reps/Date persistiert
16. ✅ **Nächstes Training** → Selbes Workout, neue Progressive Overload Values!

**Komplettes Set Management:**
- ✅ Edit Set (Sheet-based UI)
- ✅ Update All Sets (Toggle)
- ✅ Add Set (Quick-Add + Plus Button)
- ✅ Delete Set (Context Menu)
- ✅ Mark All Complete (Batch operation)
- ✅ Auto-Finish (when all sets completed)

**Exercise Management:**
- ✅ Exercise Reordering (Session-only + Permanent Save)
- ✅ Auto-Hide finished exercises
- ✅ Eye-Toggle (Show/Hide finished)
- ✅ Production-ready orderIndex handling

**Workout Management:**
- ✅ Workout Repository (Clean Architecture)
- ✅ Workout Picker UI mit Favoriten
- ✅ 4 Seed Workouts (Push/Pull/Legs/TEST Multi Exercise)
- ✅ Real Workout Loading in StartSessionUseCase
- ✅ Progressive Overload Integration
- ✅ Permanent Reorder Save zu Workout Template

---

## 📚 Verwandte Dokumentation

- `TECHNICAL_CONCEPT_V2.md` - Architektur-Specs
- `UX_CONCEPT_V2.md` - UX/UI Design
- `TODO.md` - Priorisierte Aufgaben + Phase 2 Sektion
- `README.md` - Projekt-Übersicht
- `PROGRESSION_FEATURE_PLAN.md` - ⭐ Phase 2 Spec (Auto-Progression, ~14h)
- `PROGRESSION_QUICK_REF.md` - ⭐ Phase 2 Quick Reference
- `SESSION_SUMMARY_2025_10_23.md` - Session 5 Detailed Summary

---

**Letzte Aktualisierung:** 2025-10-23 (Session 5 Ende)
**Status:** ✅ WORKOUT REPOSITORY KOMPLETT! Real Workouts + Progressive Overload + Complete Set Management!
**Nächste Session:** Reordering, Progression Features (Phase 2), oder Workout History & Statistics
