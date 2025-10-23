# GymBo V2 - Aktueller Stand (2025-10-23)

**Status:** ✅ MVP FUNKTIONSFÄHIG + Progressive Overload komplett
**Architektur:** Clean Architecture (4 Layers) + iOS 17 @Observable
**Design:** ScrollView-basiertes Active Workout + Sheet-basiertes Editing

**Letzte Session (2025-10-23 - Session 2):**
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
│   │   └── UpdateSetUseCase.swift          # ← NEU
│   └── RepositoryProtocols/
│       ├── SessionRepositoryProtocol.swift
│       └── ExerciseRepositoryProtocol.swift # ← NEU
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
│   │   └── SessionStore.swift               # updateSet() hinzugefügt
│   └── Views/ActiveWorkout/Components/
│       ├── CompactSetRow.swift              # ← Sheet-based editing
│       └── EditSetSheet.swift               # ← NEU (in CompactSetRow.swift)
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

### 1. UpdateSetUseCase

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

### 2. ExerciseRepository

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

### 3. ExerciseEntity Schema

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

### 3. Workout Repository
**Status:** 🔴 FEHLT  
**Benötigt:** Richtige Workout Templates statt Test-Data

### 4. Add/Remove Sets während Session
**Status:** 🔴 FEHLT  
**UI:** Quick-Add Feld vorhanden  
**Benötigt:** `AddSetUseCase`, `RemoveSetUseCase`

### 5. Reorder Exercises/Sets
**Status:** 🔴 FEHLT  
**UI:** Buttons vorhanden  
**Benötigt:** Drag & Drop + `ReorderUseCase`

### 6. Workout History & Statistics
**Status:** 🔴 FEHLT

### 7. Tests
**Status:** 🔴 FEHLT

---

## 📋 Nächste Schritte (Empfehlung)

### Quick Wins (30-60 Min)

1. **"Mark All Complete" Button implementieren (30 Min)**
   - Button ist vorhanden, funktioniert noch nicht
   - Alle Sets einer Übung auf einmal abhaken
   - Praktisch für schnellen Workout-Abschluss

2. **Equipment in UI anzeigen (15 Min)**
   - Wie Exercise Name, aber Equipment-Type
   - "Barbell", "Cable", "Bodyweight" etc.
   - Zusätzliche Info in CompactExerciseCard

### Mittelfristig (4-8 Stunden)

3. **Add/Remove Sets (2-3 Stunden)**
   - AddSetUseCase implementieren
   - Quick-Add TextField mit Regex Parser verbinden
   - RemoveSetUseCase + Swipe-to-Delete

4. **Reordering (2-3 Stunden)**
   - `.onMove` für Exercises
   - `.onMove` für Sets  
   - ReorderUseCase

5. **Workout Repository (2-3 Stunden)**
   - WorkoutEntity & Repository
   - Workout Picker in HomeView
   - Echte Templates statt Test-Data

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

---

## 🚀 Current State Summary

**Was jetzt funktioniert (End-to-End):**

1. ✅ **App Start** → Seeds 3 Exercises (first launch only)
2. ✅ **Start Workout** → Lädt Exercise IDs aus DB
3. ✅ **Tap Weight/Reps** → Sheet öffnet sich
4. ✅ **Edit Values** → Große, gut bedienbare TextFields
5. ✅ **Save** → Speichert in Session + Exercise History
6. ✅ **Exercise History** → lastUsedWeight/Reps/Date persistiert
7. ✅ **Progressive Overload Ready** → Nächstes Workout kann Werte laden

**Nächster logischer Schritt:**
- Exercise Names in UI anzeigen
- Last Used Values beim Session Start laden
- → Kompletter Progressive Overload Cycle funktioniert!

---

## 📚 Verwandte Dokumentation

- `TECHNICAL_CONCEPT_V2.md` - Architektur-Specs
- `UX_CONCEPT_V2.md` - UX/UI Design
- `TODO.md` - Priorisierte Aufgaben
- `README.md` - Projekt-Übersicht

---

**Letzte Aktualisierung:** 2025-10-23 (Session 2 Ende)
**Status:** ✅ Progressive Overload komplett funktionsfähig!
**Nächste Session:** Mark All Complete + Equipment Display
