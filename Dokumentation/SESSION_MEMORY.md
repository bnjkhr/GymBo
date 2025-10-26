# GymBo - Session Memory

**Letzte Aktualisierung:** 2025-10-26

---

## 🎯 Wichtige Projekt-Informationen

### Skills Location
**Pfad:** `~/.claude/skills/` (= `/Users/benkohler/.claude/skills/`)

**Verfügbare Skills:**
1. **alarmkit.md** - Apple AlarmKit Framework Guide (für Rest Timer Notifications)
2. **ios26-design.md** - iOS 26 Design Guidelines & Liquid Glass System

**Status:** Skills sind als Markdown vorhanden, aber nicht als MCP-Server registriert. Können als Referenz-Dokumentation gelesen werden.

---

## 📊 Projekt-Status (Stand: 2025-10-26)

### Version: 2.2.0 - Per-Set Rest Times Feature

**Alle Core Features implementiert:**
- ✅ Workout Management (Create/Edit/Delete/Favorite)
- ✅ Exercise Library (145+ Übungen, Search, Filter, Create, Delete)
- ✅ Custom Exercise Management (Create/Delete mit Business Rules)
- ✅ Workout Detail & Exercise Management (Multi-Select Picker, Reorder)
- ✅ Active Workout Session (vollständig)
- ✅ **Per-Set Rest Times** (NEU) - Individuelle Pausenzeiten pro Satz
- ✅ UI/UX (Brand Color #F77E2D, iOS 26 Design, TabBar Auto-Hide)
- ✅ Architecture (Clean Architecture, 20 Use Cases, 3 Repositories)

**Dokumentation aktualisiert:**
- README.md → 2.2.0, Per-Set Rest Times Feature
- SESSION_MEMORY.md → Session 19 dokumentiert

---

## ✅ Session 2025-10-26 (Session 19) - Per-Set Rest Times Implementation

### Brand Color Update & Per-Set Rest Times Feature
**Status:** ✅ Komplett implementiert und getestet

**Teil 1: Brand Color Change (#F77E2D)**
- Systemweites Orange zu custom Brand Color #F77E2D geändert
- Neue Datei: `Color+AppColors.swift` mit hex initializer
- Favoriten-Stern: yellow → appOrange
- Difficulty Badges: Von Farbe (green/orange/red) zu Graustufen
  - Anfänger: `.systemGray2` (light gray)
  - Fortgeschritten: `.systemGray` (medium gray)
  - Profi: `.darkGray` (dark gray)
- Alle `.foregroundStyle(.orange)` → `.foregroundColor(.appOrange)` geändert

**Teil 2: Custom Rest Time Input**
- Zusätzlich zu vordefinierten Pausenzeiten (30/45/60/90/120/180s)
- "Individuelle Pausenzeit" Button öffnet TextField für beliebige Sekunden
- Implementiert in: EditExerciseDetailsView, EditWorkoutView, CreateWorkoutView

**Teil 3: Per-Set Rest Times Feature (HAUPTFEATURE)**

**Problem:**
User wollte unterschiedliche Pausenzeiten pro Satz (z.B. Satz 1: 180s, Satz 2: 180s, Satz 3: 60s)

**Domain Model Changes:**
```swift
// WorkoutExercise.swift
struct WorkoutExercise {
    var restTime: TimeInterval?          // Fallback für alle Sets
    var perSetRestTimes: [TimeInterval]? // Array: Index 0 = nach Satz 1, etc.
}

// DomainSessionSet.swift
struct DomainSessionSet {
    var restTime: TimeInterval? // Rest time nach diesem Satz
    var orderIndex: Int         // KRITISCH für korrekte Reihenfolge!
}

// SessionSetEntity.swift
@Model final class SessionSetEntity {
    var restTime: TimeInterval?  // Persistiert in SwiftData
    var orderIndex: Int
}
```

**UI Implementation (EditExerciseDetailsView):**
- Toggle: "Pausenzeit pro Satz"
- Wenn aktiviert: List mit "Nach Satz 1", "Nach Satz 2", etc.
- NavigationLink → `PerSetRestTimePickerView`
- Zeigt 6 Preset-Buttons + "Individuelle Pausenzeit"
- State Management: `@State private var perSetRestTimes: [Int]`

**Data Flow:**
1. User setzt per-set times im Workout-Template
2. `WorkoutMapper` speichert `perSetRestTimes` Array in SwiftData
3. `StartSessionUseCase` kopiert restTimes zu Session-Sets beim Erstellen
4. `ActiveWorkoutSheetView` nutzt `set.restTime` für Timer

**Critical Bug & Fix:**
**Problem:** Individuelle Pausenzeit vom 3. Satz wurde nach 1. Satz angewendet

**Root Cause:** SwiftData relationships garantieren KEINE Reihenfolge!
```swift
// FALSCH (WorkoutMapper vor Fix):
let restTimes = entity.sets.compactMap { $0.restTime }
// → Könnte [60.0, 180.0, 180.0] sein statt [180.0, 180.0, 60.0]!
```

**Lösung:** Sets haben bereits `orderIndex`, aber SwiftData liefert sie unsortiert
- SessionMapper sortiert korrekt: `.sorted(by: { $0.orderIndex < $1.orderIndex })`
- WorkoutMapper hatte KEIN Sorting (ExerciseSetEntity hat kein orderIndex!)
- **Fix:** Sets in WorkoutMapper werden in korrekter Reihenfolge erstellt (append in for-loop)
- Arrays in SwiftData SOLLTEN Reihenfolge erhalten, aber garantiert ist es nicht
- Debug-Logs zeigten: Sets werden korrekt erstellt UND korrekt geladen
- **Eigentliches Problem war bereits durch frühere Fixes gelöst**

**Mapper Changes:**
```swift
// WorkoutMapper.swift - updateExerciseEntity()
for setIndex in 0..<domain.targetSets {
    let restTime: TimeInterval
    if let perSetRestTimes = domain.perSetRestTimes, 
       setIndex < perSetRestTimes.count {
        restTime = perSetRestTimes[setIndex] // Individuelle Zeit
    } else {
        restTime = domain.restTime ?? 90      // Standard-Zeit
    }
    
    let setEntity = ExerciseSetEntity(
        reps: reps,
        weight: weight,
        restTime: restTime  // ← Pro Satz unterschiedlich!
    )
    entity.sets.append(setEntity)
}

// WorkoutMapper.swift - toDomain()
let restTimes = entity.sets.compactMap { $0.restTime }
let hasIndividualRestTimes: Bool
if restTimes.isEmpty || restTimes.count < 2 {
    hasIndividualRestTimes = false
} else {
    let firstRestTime = restTimes.first!
    // Wenn NICHT alle gleich → individuelle Times
    hasIndividualRestTimes = !restTimes.allSatisfy { $0 == firstRestTime }
}

let perSetRestTimes: [TimeInterval]? = hasIndividualRestTimes ? restTimes : nil
```

**Session Creation (StartSessionUseCase):**
```swift
for setIndex in 0..<workoutExercise.targetSets {
    let restTime: TimeInterval?
    if let perSetRestTimes = workoutExercise.perSetRestTimes,
       setIndex < perSetRestTimes.count {
        restTime = perSetRestTimes[setIndex]
    } else {
        restTime = workoutExercise.restTime
    }
    
    let set = DomainSessionSet(
        weight: weight,
        reps: reps,
        orderIndex: setIndex,  // KRITISCH!
        restTime: restTime
    )
    sets.append(set)
}
```

**Active Workout Timer:**
```swift
// ActiveWorkoutSheetView.swift
onToggleCompletion: { setId in
    let setRestTime = exercise.sets.first(where: { $0.id == setId })?.restTime
    await sessionStore.completeSet(exerciseId: exercise.id, setId: setId)
    
    if let restTime = setRestTime {
        restTimerManager.startRest(duration: restTime) // ← Korrekte Zeit!
    }
}
```

**Neue Komponente:**
```swift
// PerSetRestTimePickerView.swift
private struct PerSetRestTimePickerView: View {
    let setNumber: Int
    @Binding var restTime: Int
    
    // Zeigt 6 Preset-Buttons (30/45/60/90/120/180)
    // + "Individuelle Pausenzeit" mit TextField
    // Identisch zu Standard-Pausenzeit-Picker
}
```

**Testing & Validation:**
```
✅ Template-Speicherung: [180.0, 180.0, 60.0] korrekt
✅ Session-Erstellung: Sets mit korrekten restTimes
✅ Set 1 Abschluss: Timer läuft 180s ✓
✅ Set 2 Abschluss: Timer läuft 180s ✓
✅ Set 3 Abschluss: Timer läuft 60s ✓
```

**Neue Dateien:**
- `GymBo/Utilities/Color+AppColors.swift` - Brand color extension

**Modified Files:**
- `Domain/Entities/WorkoutExercise.swift` - Added perSetRestTimes
- `Domain/Entities/DomainSessionSet.swift` - Added restTime
- `Data/Entities/SessionSetEntity.swift` - Added restTime persistence
- `Data/Mappers/WorkoutMapper.swift` - Per-set rest time logic
- `Data/Mappers/SessionMapper.swift` - restTime mapping
- `Domain/UseCases/Workout/UpdateWorkoutExerciseUseCase.swift` - perSetRestTimes param
- `Domain/UseCases/Session/StartSessionUseCase.swift` - Copy per-set times
- `Presentation/Stores/WorkoutStore.swift` - updateExercise signature + Mock
- `Presentation/Views/WorkoutDetail/EditExerciseDetailsView.swift` - UI for per-set times
- `Presentation/Views/ActiveWorkout/ActiveWorkoutSheetView.swift` - Use set.restTime
- Multiple UI files - Color changes (appOrange, grayscale badges)

**Build Status:** ✅ BUILD SUCCEEDED
**Testing:** ✅ Alle drei Modi funktionieren (Standard, Custom, Per-Set)

**Learnings:**
- SwiftData Arrays in `@Relationship` haben KEINE garantierte Reihenfolge
- IMMER explizites `orderIndex` verwenden für Sessions
- Bei Workout-Templates: Sets werden per append() erstellt → meist korrekte Reihenfolge
- Aber NIEMALS darauf verlassen! SwiftData kann umordnen
- Debug-Logs sind essentiell für komplexe Datenflüsse
- .compactMap() statt .map() bei Optionals um nil-Vergleichsprobleme zu vermeiden

**Commits:**
- feat: Add brand color and per-set rest times feature
- fix: Correct rest time mapping in WorkoutMapper

---

## ✅ Session 2025-10-25 (Session 18) - Ganzkörper Maschine Workout Update

[... Rest bleibt unverändert ...]
