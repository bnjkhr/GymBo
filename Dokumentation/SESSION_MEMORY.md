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
- ✅ Exercise Library (145+ Übungen, Search, Filter)
- ✅ Workout Detail & Exercise Management (Multi-Select Picker, Reorder)
- ✅ Active Workout Session (vollständig)
- ✅ UI/UX (Modern Dark Theme, iOS 26 Design)
- ✅ Architecture (Clean Architecture, 17 Use Cases, 3 Repositories)

**Dokumentation aktualisiert:**
- README.md → 2.1.0, Production Ready Status
- TODO.md → Alle erledigten Features markiert, neue Features aus notes.md hinzugefügt

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
- `/Domain/` - 17 Use Cases, Entities, Protocols
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

**Zuletzt bearbeitet:** 2025-10-24 (Abend - Extended)
**Session-Dauer:** ~3.5 Stunden
**Features:** HomeView Redesign mit Begrüßung, Spintnummer, Calendar Strip
**Bug Fixes:** Dark Mode Lesbarkeit in Active Workout (weiß auf weiß → adaptive Farben)
**Neue Komponenten:** 3 neue Views, 1 Repository-Erweiterung
**Dokumentation:** SESSION_MEMORY.md, TODO.md, CURRENT_STATE.md aktualisiert
