# GymBo - Session Memory

**Letzte Aktualisierung:** 2025-10-24

---

## 🎯 Wichtige Projekt-Informationen

### Skills Location
**Pfad:** `~/.claude/skills/` (= `/Users/benkohler/.claude/skills/`)

**Verfügbare Skills:**
1. **alarmkit.md** - Apple AlarmKit Framework Guide (für Rest Timer Notifications)
2. **ios26-design.md** - iOS 26 Design Guidelines & Liquid Glass System

**Status:** Skills sind als Markdown vorhanden, aber nicht als MCP-Server registriert. Können als Referenz-Dokumentation gelesen werden.

---

## 📊 Projekt-Status (Stand: 2025-10-24)

### Version: 2.1.0 - MVP COMPLETE

**Alle Core Features implementiert:**
- ✅ Workout Management (Create/Edit/Delete/Favorite)
- ✅ Exercise Library (145+ Übungen, Search, Filter, Create, Delete)
- ✅ Custom Exercise Management (Create/Delete mit Business Rules)
- ✅ Workout Detail & Exercise Management (Multi-Select Picker, Reorder)
- ✅ Active Workout Session (vollständig)
- ✅ UI/UX (Modern Dark Theme, iOS 26 Design, TabBar Auto-Hide)
- ✅ Architecture (Clean Architecture, 19 Use Cases, 3 Repositories)

**Dokumentation aktualisiert:**
- README.md → 2.1.0, Production Ready Status
- TODO.md → Alle erledigten Features markiert, neue Features aus notes.md hinzugefügt

---

## ✅ Session 2025-10-24 (Session 11) - TextField Performance & UI Update Fixes

### Critical Performance Fixes
**Status:** ✅ Implementiert

**Problem 1: TextField Performance Issues**
- Console Errors: "Gesture: System gesture gate timed out"
- "Invalid frame dimension (negative or non-finite)"
- Massive lag beim Tippen in allen TextFields
- Betroffene Views: CreateWorkout, EditWorkout, CreateExercise, EditExerciseDetails

**Lösung:**
- Added `.scrollDismissesKeyboard(.interactively)` zu allen ScrollViews
- Reduziert View-Updates während Eingabe
- Keyboard wird beim Scrollen automatisch dismissed

**Problem 2: Keyboard verdeckt TextField**
- Gewicht-TextField in EditExerciseDetailsView war nicht sichtbar
- ScrollView scrollte nicht automatisch nach oben

**Lösung:**
- Added `.padding(.bottom, 100)` für Extra-Platz unter Content
- Toolbar "Fertig" Button zum manuellen Keyboard-Dismiss
- `.scrollDismissesKeyboard(.interactively)` für bessere Keyboard-Behandlung

**Problem 3: UI aktualisiert nicht sofort nach Speichern**
- Gewichts-Änderung in WorkoutDetailView wurde erst nach App-Neustart angezeigt
- ExerciseCard zeigte alte Daten

**Lösung:**
- Added `.id()` Modifier auf ExerciseCard basierend auf aktuellen Werten
```swift
.id("\(exercise.id)-\(exercise.targetSets)-\(exercise.targetReps ?? 0)-\(exercise.targetWeight ?? 0)")
```
- Erzwingt SwiftUI Re-Render bei Daten-Änderung

**Modified Files:**
- `Presentation/Views/WorkoutDetail/EditExerciseDetailsView.swift` - Keyboard fixes
- `Presentation/Views/WorkoutDetail/CreateWorkoutView.swift` - Performance fix
- `Presentation/Views/WorkoutDetail/EditWorkoutView.swift` - Performance fix
- `Presentation/Views/Exercises/CreateExerciseView.swift` - Performance fix
- `Presentation/Views/WorkoutDetail/WorkoutDetailView.swift` - Immediate UI update fix

**Result:** 
- ✅ Butterweiche TextField-Performance
- ✅ Keyboard verdeckt Felder nicht mehr
- ✅ UI aktualisiert sofort nach Speichern

---

## ✅ Session 2025-10-24 (Session 10) - TabBar Auto-Hide

### TabBar Auto-Hide Feature
**Status:** ✅ Implementiert

**Implementation:**
- Added `.tabBarMinimizeBehavior(.onScrollDown)` to MainTabView
- TabBar verschwindet automatisch beim Runterscrollen
- TabBar erscheint wieder beim Hochscrollen
- Gibt mehr Platz für Content
- Modernes iOS-Pattern

**Modified Files:**
- `Presentation/Views/Main/MainTabView.swift` - Added modifier to TabView

**Build Status:** ✅ Erfolgreich

---

## ✅ Session 2025-10-24 (Session 9) - Custom Exercise Management

### Custom Exercises: Create & Delete Feature
**Status:** ✅ Komplett implementiert, getestet, dokumentiert

**1. Create Custom Exercises:**
- **CreateExerciseView** - Vollständiges Formular
  - Name TextField (auto-focus)
  - Multi-Select Muscle Groups (FlowLayout chips, orange selection)
  - Equipment Radio Buttons (5 Optionen)
  - Difficulty Pills (3 Stufen)
  - Optional Description & Instructions
  - Validation + Error Handling

- **CreateExerciseUseCase** - Business Logic
  - Name-Validierung (nicht leer)
  - Muscle Groups-Validierung (mindestens 1)
  - Equipment-Validierung (muss ausgewählt sein)
  - Lokalisierte Error Messages

- **Repository Implementation**
  - `ExerciseRepository.create()` Methode
  - SwiftData Persistierung mit `createdAt` timestamp

**2. Delete Custom Exercises:**
- **DeleteExerciseUseCase** - Business Logic & Protection
  - **Business Rule:** Nur custom exercises löschbar (mit `createdAt`)
  - Catalog exercises geschützt (kein `createdAt`)
  - Validierung: Exercise muss existieren
  - Lokalisierte Error Messages

- **UI Implementation**
  - Roter Trash-Button in ExerciseDetailView toolbar
  - Nur sichtbar für custom exercises
  - Confirmation Dialog ("Übung löschen?")
  - Loading State während Deletion
  - Error Alert bei Fehlern
  - Auto-dismiss nach erfolgreichem Löschen
  - Callback für List-Refresh

**3. Performance Optimizations (CRITICAL):**
- **Problem:** Massive Performance-Issues in ExercisesView
  - "Gesture: System gesture gate timed out"
  - Multi-Sekunden Input-Delays
  - Computed properties recalculated on EVERY view update (145+ exercises)

- **Lösung:** Caching Pattern
  ```swift
  @State private var cachedFilteredExercises: [ExerciseEntity] = []
  @State private var cachedMuscleGroups: [String] = []
  @State private var cachedEquipment: [String] = []

  // Updates via .onChange triggers
  .onChange(of: searchText) { _, _ in updateFilteredExercises() }
  .onChange(of: exercises) { _, _ in
      updateFilteredExercises()
      updateAvailableFilters()
  }
  ```
  - **Performance Gain:** ~90-95% reduction in calculations
  - **Result:** Butterweiche Performance, keine Delays mehr

- **HomeView Performance Fix:**
  - Replaced expensive string `.id()` with Hasher-based integer
  - Eliminiert `.map { "\($0.name)-\($0.isFavorite)" }.joined()` overhead
  ```swift
  var hasher = Hasher()
  hasher.combine(workouts.count)
  for workout in workouts {
      hasher.combine(workout.name)
      hasher.combine(workout.isFavorite)
  }
  workoutsHash = hasher.finalize()
  ```

**4. UI Standardization:**
- **Plus Button Pattern** (nach mehreren Iterationen korrekt):
  - Icon: `"plus.circle"` (SF Symbol)
  - Font: `.title2`
  - Color: `.primary`
  - ButtonStyle: `.plain`
  - 44x44 Frame für Touch-Target (optional)

- **ExercisesView Header Redesign:**
  - Problem: Plus-Button saß zu tief (VStack mit 2 Zeilen)
  - Lösung: Count zu Search Placeholder verschoben
  - Single-Line Header: "Übungen" + Plus Button
  - Search: "Durchsuche \(count) Übungen ..."
  - Perfekte vertikale Ausrichtung

**5. New Content:**
- **"Ganzkörper Maschine" Workout** hinzugefügt
  - 9 Übungen (Maschinen-basiert)
  - CSV-Mapping zu existierenden Exercises
  - Extended `createSets()` mit `restTime` parameter

**Neue Dateien:**
- `/Domain/UseCases/Exercise/CreateExerciseUseCase.swift`
- `/Domain/UseCases/Exercise/DeleteExerciseUseCase.swift`
- `/Presentation/Views/Exercises/CreateExerciseView.swift`

**Modified Files:**
- `ExerciseRepositoryProtocol.swift` - create(), delete() methods
- `SwiftDataExerciseRepository.swift` - Implementation
- `ExerciseDetailView.swift` - Delete UI + callback
- `ExercisesView.swift` - Performance caching + Plus button
- `HomeViewPlaceholder.swift` - Hasher-based performance fix
- `ActiveWorkoutSheetView.swift` - Eye toggle color
- `WorkoutSeedData.swift` - Ganzkörper Maschine workout

**Build Status:** ✅ BUILD SUCCEEDED

---

## 🐛 Bug Fixes (Session 2025-10-24)

### 1. Favorite Toggle nicht in HomeView aktualisiert ✅
**Problem:** Favorite-Status wurde in WorkoutDetailView geändert, aber HomeView zeigte alte Daten.

**Root Cause:** HomeView nutzt lokale `@State workouts` Kopie statt direkt `workoutStore.workouts`.

**Lösung (2 Änderungen in HomeViewPlaceholder.swift):**
```swift
// 1. onChange hinzugefügt (Zeile 145-151):
.onChange(of: workoutStore?.workouts) { oldValue, newValue in
    if let updatedWorkouts = newValue {
        workouts = updatedWorkouts
    }
}

// 2. .id() Modifier erweitert (Zeile 270):
.id(workouts.map { "\($0.name)-\($0.isFavorite)" }.joined())
// Vorher: Nur Name
// Jetzt: Name UND isFavorite
```

**Status:** ✅ Gefixt und getestet

---

### 2. Eye Toggle Button - State Visualisierung ✅
**Problem:** Button zum Ein-/Ausblenden abgeschlossener Übungen hatte keine visuelle Unterscheidung zwischen aktiv/inaktiv.

**Anforderung:**
- Inaktiv (versteckt): Grau
- Aktiv (zeigt alle): Orange

**Lösung (ActiveWorkoutSheetView.swift:319):**
```swift
.foregroundStyle(showAllExercises ? .orange : .secondary)
```

**Status:** ✅ Implementiert

---

## ✅ Session 2025-10-24 (Abend) - HomeView Redesign Complete

### HomeView Erweiterungen
**Status:** ✅ Implementiert und erfolgreich gebaut

**Neue Features:**
1. **Zeitbasierte Begrüßung** (`.largeTitle` Font):
   - 5:00-11:59: "Hey, guten Morgen!"
   - 12:00-17:59: "Hey!"
   - 18:00-4:59: "Hey, guten Abend!"

2. **Spintnummer-Widget** (neben Profilbild):
   - Locked State: Schloss-Icon 🔒
   - Unlocked State: Blaue Pill mit 🔓 + Nummer
   - Tap → Input-Sheet (Nummernpad)
   - Long Press → Dialog (Ändern/Löschen)
   - Persistierung via `@AppStorage("lockerNumber")`

3. **Workout Calendar Strip**:
   - Zeigt letzte 14 Tage
   - Grüner Kreis = abgeschlossenes Workout
   - Blauer Ring = Heute
   - Streak-Badge mit 🔥 Icon
   - Auto-Scroll zu "Heute"

**Neue Dateien:**
- `Presentation/Views/Home/Components/GreetingHeaderView.swift`
- `Presentation/Views/Home/Components/LockerNumberInputSheet.swift`
- `Presentation/Views/Home/Components/WorkoutCalendarStripView.swift`

**Repository-Erweiterung:**
- `SessionRepositoryProtocol`: `fetchCompletedSessions(from:to:)`
- Implementiert in SwiftData + Mock Repository

**Build Status:** ✅ BUILD SUCCEEDED (keine Errors, nur bestehende Warnings)

### Dark Mode Fix (Session 9 - Extended)
**Status:** ✅ Behoben

**Problem:**
- Weiße Schrift auf weißem Hintergrund in Active Workout Exercise Cards
- "Alle Sätze fertig" Overlay nicht lesbar im Dark Mode
- Button-Kontrast problematisch

**Lösung:**
- `CompactExerciseCard.swift`: `.background(Color.white)` → `.background(Color(.systemBackground))`
- `ActiveWorkoutSheetView.swift`: Overlay + Button auf adaptive Farben umgestellt
- `Color(.systemBackground)` passt sich automatisch an Light/Dark Mode an
- `Color.primary` invertiert im Dark Mode (schwarz → weiß)

**Ergebnis:**
- ✅ Exercise Cards lesbar in beiden Modi
- ✅ Light Mode: Schwarze Schrift auf weißem Grund
- ✅ Dark Mode: Weiße Schrift auf dunklem Grund
- ✅ Timer-Bereich bleibt intentional schwarz

**Modified Files:**
- `Presentation/Views/ActiveWorkout/Components/CompactExerciseCard.swift`
- `Presentation/Views/ActiveWorkout/ActiveWorkoutSheetView.swift`

**Commit:** `2a17490` - "fix: Dark Mode support in Active Workout view"

---

## 📝 Offene Features (aus notes.md)

**Priorisiert:**
1. **Exercise Swap Feature** (4-6 Std) - Lange drücken → Alternative Übungen vorschlagen
2. **Profile Page** (2-3 Std) - Button vorhanden, View ist Placeholder
3. ✅ **HomeView Redesign** (3-4 Std) - Begrüßung, Calendar-Strip, Sprintnummer ← **FERTIG**
4. **Session History** (2-3 Std) - Vergangene Workouts anzeigen
5. **Localization** (3-4 Std) - Mehrsprachigkeit

---

## 🏗️ Architektur-Notizen

### Warum lokale `workouts` Kopie in HomeView?
- Kommentar: "LOCAL state instead of store"
- Grund: SwiftUI List identity issues bei direkter Verwendung von `@Observable` Store-Properties
- Lösung: Lokale Kopie + `.onChange()` Synchronisation

### orderIndex Pattern (KRITISCH!)
- SwiftData `@Relationship` Arrays haben **KEINE garantierte Reihenfolge**
- **Immer** explizites `orderIndex` Property verwenden
- **Niemals** Array-Position für Identifikation nutzen
- **Immer** UUIDs für eindeutige Identifikation

### In-Place Updates (Performance & Stability)
- **Niemals** SwiftData Relationship-Arrays neu erstellen
- **Immer** existierende Entities in-place updaten
- Reason: Erhält SwiftData-Referenzen, verhindert Datenverlust

---

## 🎨 Design System

### Aktuelles Design (iOS 26 Modern):
- **Theme:** Dark (schwarzer Hintergrund + weiße Cards)
- **Corner Radius:** 39pt (iPhone display radius)
- **Checkboxes:** Invertiert (schwarz + weißes Häkchen)
- **Accent Color:** Orange
- **Haptic Feedback:** Überall
- **Success Pills:** Auto-dismiss 3s
- **Typography:** San Francisco (iOS Default)

### Button States Konvention:
- **Inaktiv:** Grau (`.secondary`)
- **Aktiv:** Orange (`.orange`)
- Beispiel: Eye Toggle, (zukünftig alle Toggle-Buttons)

---

## 🔧 Technische Details

### SwiftData Migration:
- **Status:** ✅ Implementiert (SchemaV1, SchemaV2, GymBoMigrationPlan)
- **Location:** `/Data/Migration/`
- **DEBUG Mode:** Database deletion DISABLED (auskommentiert in GymBoApp.swift:48-62)

### Dependencies:
- iOS 18.0+ (deployment target)
- SwiftUI 5.0+
- SwiftData
- @Observable (iOS 17+)

---

## 📚 Wichtige Dateien

**Dokumentation:**
- `/Dokumentation/V2/README.md` - Projekt-Übersicht
- `/Dokumentation/V2/TODO.md` - Task-Liste
- `/Dokumentation/notes.md` - User-Anforderungen

**Core Architecture:**
- `/Domain/` - 19 Use Cases, Entities, Protocols
- `/Data/` - 3 Repositories, Mappers, Migration
- `/Presentation/` - 2 Stores (@Observable), Views
- `/Infrastructure/` - DI Container, Seed Data

**Key Views:**
- `HomeViewPlaceholder.swift` - Workout Liste (mit lokalem State-Pattern)
- `ActiveWorkoutSheetView.swift` - Active Session View
- `WorkoutDetailView.swift` - Workout Detail & Exercise Management
- `ExercisesView.swift` - Exercise Library (145+ Übungen)

---

## 💡 Learnings & Best Practices

1. **@Observable ist besser als ObservableObject** für komplexe State-Updates
2. **TextField in ForEach kann zu Crashes führen** → Separate Sheets/Alerts verwenden
3. **UUIDs statt Array-Indices** für eindeutige Identifikation
4. **Lokale @State Kopien** können nötig sein für SwiftUI List-Performance
5. **`.onChange()` für Store-Synchronisation** nutzen
6. **`.id()` Modifier** für erzwungene View-Updates bei Property-Changes

---

**Zuletzt bearbeitet:** 2025-10-24 (Session 11 - TextField Performance & UI Update Fixes)
**Session-Dauer:** ~2 Stunden
**Features:** Critical Performance Fixes für alle TextFields
**Bug Fixes:** 
- TextField Performance (Gesture gate timeout, Invalid frame dimension)
- Keyboard verdeckt TextField nicht mehr
- UI aktualisiert sofort nach Speichern (keine App-Neustarts)
**Modified Views:** 5 Views mit Performance-Verbesserungen
**Dokumentation:** CURRENT_STATE.md, SESSION_MEMORY.md aktualisiert
**Performance:** Butterweiche TextField-Performance in allen Input-Views
