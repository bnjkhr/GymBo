# GymBo V2 - Current State

**Last Updated:** 2025-10-24  
**Session:** 6

---

## 📋 Overview

GymBo V2 ist eine iOS Fitness-Tracking-App basierend auf **Clean Architecture** mit SwiftData-Persistierung. Die App ermöglicht das Erstellen von Workout-Templates, das Tracking von Live-Workouts mit Timer-Funktionalität und detaillierte Übungsverwaltung.

---

## ✅ Completed Features

### **Phase 1: Foundation & Data Layer** ✅
- Clean Architecture Setup (Domain, Data, Presentation, Infrastructure)
- SwiftData Integration mit Schema-Versionierung
- Repository Pattern Implementation
- Use Case Layer
- Dependency Injection Container
- Sample Data Seeding (Workouts & Übungen)

### **Phase 2: Exercise Management** ✅
- Exercise Picker mit Search & Filter
- Add Exercise to Workout
- Success Pill Notifications
- Swipe-to-Delete für Übungen
- Drag & Drop Reordering
- Exercise Details Editing mit Form
- Time-Based Exercise Support (Wiederholungen ODER Zeit)
- Exercise Counter im Timer (z.B. "2/7")

### **Phase 3: Active Workout Features** ✅
- Complete Workout Flow (Start → Track → Complete → Summary)
- Rest Timer mit Persistence
- Set Completion Tracking
- Exercise Progress Visualization
- Workout Summary mit Statistiken
- Mark All Complete Feature
- Intelligente Notifications:
  - "Nächste Übung" nach abgeschlossener Übung
  - "Workout done! 💪🏼" nach letzter Übung
- Success Pill in ActiveWorkoutSheetView (sichtbar über allem)

### **Phase 4: UI Redesign (Session 6)** ✅
- **Modern Dark Theme**: Schwarzer Hintergrund mit weißen Cards
- **Kompakte Exercise Cards**: 39pt corner radius (iPhone Display Radius)
- **Optimierte Checkboxen**: Quadratisch, invertiert (schwarz mit weißem Haken)
- **Cleaner Header**: Ohne Dot-Indikator und 3-Dot-Menu
- **Verbesserte Buttons**: Grau statt blau, einheitliches Design
- **Timer Section**: Schwarzer Hintergrund bis zum oberen Rand
- **Skip Button**: Forward-Icon statt Text
- **Navigation**: Checkmark-Icon für Show/Hide Completed
- **Reorder**: Nur noch in Card-Footer (↕), nicht mehr im Header
- **Verbesserte Typografie**: Größerer Exercise Name (24pt)
- **Optimiertes Spacing**: 24pt Padding für bessere Lesbarkeit
- **Subtile Notizen-Field**: Ohne Hintergrund, dezent

---

## 🏗️ Architecture

### **Clean Architecture Layers**

```
┌─────────────────────────────────────────────┐
│            Presentation Layer               │
│  (Views, Stores, ViewModels, Components)   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│             Domain Layer                    │
│   (Entities, Use Cases, Repository Protocols)│
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│              Data Layer                     │
│  (Repositories, Entities, Mappers, Schemas) │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│         Infrastructure Layer                │
│     (SwiftData, Persistence, Services)      │
└─────────────────────────────────────────────┘
```

### **Key Design Patterns**
- **Repository Pattern**: Abstrahiert Datenzugriff
- **Use Case Pattern**: Kapselt Business Logic
- **Dependency Injection**: Lose Kopplung via DependencyContainer
- **Mapper Pattern**: Trennung Domain ↔ Data Entities
- **@Observable**: iOS 17+ State Management (statt @Published)

---

## 📁 Project Structure

```
GymBo/
├── Domain/
│   ├── Entities/
│   │   ├── WorkoutExercise.swift (targetReps?: Int?, targetTime?: TimeInterval?)
│   │   ├── WorkoutSession.swift (workoutName?: String?)
│   │   └── SessionExercise.swift
│   ├── UseCases/
│   │   ├── Workout/
│   │   │   ├── UpdateWorkoutExerciseUseCase.swift (supports time & reps)
│   │   │   └── AddExerciseToWorkoutUseCase.swift
│   │   └── Session/
│   │       ├── StartSessionUseCase.swift
│   │       └── CompleteSetUseCase.swift
│   └── RepositoryProtocols/
├── Data/
│   ├── Entities/
│   │   └── WorkoutSessionEntity.swift (workoutName field added)
│   ├── Repositories/
│   ├── Mappers/
│   │   ├── SessionMapper.swift (workoutName mapping)
│   │   └── WorkoutMapper.swift (time/reps handling)
│   └── Migration/
│       ├── SchemaV1.swift
│       └── SchemaV2.swift (exerciseId field)
├── Presentation/
│   ├── Views/
│   │   ├── WorkoutDetail/
│   │   │   ├── EditExerciseDetailsView.swift (Zeit/Wiederholungen Toggles)
│   │   │   └── WorkoutDetailView.swift
│   │   └── ActiveWorkout/
│   │       ├── ActiveWorkoutSheetView.swift (Dark Theme, Success Pill Overlay)
│   │       └── Components/
│   │           ├── CompactExerciseCard.swift (Redesigned, 39pt corners)
│   │           ├── CompactSetRow.swift (Square checkboxes, inverted style)
│   │           └── TimerSection.swift (Exercise Counter, Skip icon)
│   ├── Stores/
│   │   ├── SessionStore.swift (Smart Notifications)
│   │   └── WorkoutStore.swift
│   ├── Components/
│   │   └── SuccessPill.swift
│   └── Services/
│       └── RestTimerStateManager.swift
└── SwiftDataEntities.swift
```

---

## 🎯 Key Features Detail

### **Modern Dark UI Design (Session 6)**

**Color Scheme:**
- Background: Solid Black
- Cards: White mit 39pt corner radius
- Text: Primary (black) on white cards
- Buttons: Gray (secondary)
- Checkboxes: Inverted (black fill with white checkmark when completed)

**Layout Principles:**
- 24pt horizontal padding (mehr Abstand vom Rand)
- 12pt top padding für erste Card
- 8pt spacing zwischen Cards
- Nahtlose schwarze Fläche von Timer bis Cards

**Typography:**
- Exercise Name: 24pt semibold
- Weight/Reps: 28pt bold
- Unit Labels: 12pt gray
- Equipment: caption, secondary

**Button Design:**
- Card Footer: 3 Buttons (✓, +, ↕) - alle grau
- Navigation: Checkmark für Show/Hide, Plus für Add Exercise
- Alle Buttons: .callout size, .secondary color
- Timer Controls: -15s, Skip (forward icon), +15s

### **Time-Based Exercise Support**

Übungen können jetzt entweder **Wiederholungen** ODER **Zeit** nutzen:

**Domain Layer:**
```swift
struct WorkoutExercise {
    var targetReps: Int?        // nil für zeitbasierte Übungen
    var targetTime: TimeInterval? // nil für wiederholungsbasierte Übungen
}
```

**UI:**
- Toggle: "Wiederholungen verwenden"
- Toggle: "Zeit verwenden" (mutual exclusive)
- Zeit-Picker: 15s, 30s, 45s, 60s, 90s, 120s
- Display: "3 × 10" (Reps) oder "3 × 60s" (Zeit)

**Validation:**
- Muss entweder Reps ODER Zeit haben
- Nicht beides gleichzeitig

### **Exercise Counter im Timer**

Zeigt aktuelle Übung und Gesamt-Übungen:

```
┌─────────────────────┐
│      12:34          │ ← Workout-Dauer
│    Push Day         │ ← Workout-Name
│       2/7           │ ← Übung 2 von 7
└─────────────────────┘
```

**Logik:**
- Findet erste unvollständige Übung
- Bei allen komplett: zeigt Gesamtzahl

### **Smart Notifications**

**Während Workout:**
- Nach jeder Übung (außer letzter): 🟢 "Nächste Übung"
- Nach letzter Übung: 🟢 "Workout done! 💪🏼"

**Implementation:**
```swift
let isLastExercise = checkIfAllExercisesCompleted()
let message = isLastExercise ? "Workout done! 💪🏼" : "Nächste Übung"
showSuccessMessage(message)
```

### **Success Pill Visibility**

**Problem gelöst:** Pill war hinter ActiveWorkoutSheetView verborgen

**Lösung:** Pill als Overlay in ActiveWorkoutSheetView:
```swift
.overlay(alignment: .top) {
    if let message = sessionStore.successMessage {
        SuccessPill(message: message)
            .zIndex(1000)  // Above all content
    }
}
```

---

## 🔧 Technical Details

### **SwiftData Schema Versioning**

**DEBUG Mode:**
- Datenbank wird bei jedem Start gelöscht
- Non-versioned Schema (schnellere Entwicklung)

**RELEASE Mode:**
- Versioned Schema mit Migration Plan
- Produktiv-ready

```swift
#if DEBUG
    container = try! ModelContainer(for: schema)
#else
    container = try! ModelContainer(
        for: schema,
        migrationPlan: GymBoMigrationPlan.self
    )
#endif
```

### **Keyboard Management**

**Problem behoben:**
- Simulator nutzte Hardware-Keyboard (Mac-Tastatur)
- Software-Keyboard war deaktiviert

**Lösung:**
```bash
defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false
```

**TextField Focus:**
```swift
@FocusState private var isWeightFieldFocused: Bool

TextField("0", text: $targetWeight)
    .focused($isWeightFieldFocused)

// Keyboard Toolbar
ToolbarItemGroup(placement: .keyboard) {
    Button("Fertig") {
        isWeightFieldFocused = false
    }
}
```

### **Rest Timer Fix**

**Problem:** Timer startete beim Workout-Start mit altem Zustand

**Lösung:**
```swift
.onAppear {
    // Clear any leftover rest timer from previous workout
    restTimerManager.cancelRest()
}
```

---

## 📊 Database Schema

### **Entities**

| Entity | Fields | Relationships |
|--------|--------|---------------|
| **WorkoutEntity** | name, defaultRestTime, exerciseCount | → WorkoutExerciseEntity[] |
| **WorkoutExerciseEntity** | exerciseId, targetSets, targetReps?, targetTime?, order | → ExerciseEntity, → WorkoutEntity |
| **ExerciseEntity** | name, muscleGroup, equipment | |
| **WorkoutSessionEntity** | workoutId, startDate, endDate, state, **workoutName** | → SessionExerciseEntity[] |
| **SessionExerciseEntity** | exerciseId, orderIndex | → ExerciseSetEntity[], → WorkoutSessionEntity |
| **ExerciseSetEntity** | reps, weight, restTime, completed | → SessionExerciseEntity |

### **Schema Changes**

**WorkoutExerciseEntity:**
- Added: `exerciseId: UUID?` (direct reference, fixes lazy loading)

**WorkoutExercise (Domain):**
- Changed: `targetReps: Int` → `targetReps: Int?`
- Added: `targetTime: TimeInterval?`

**WorkoutSessionEntity:**
- Added: `workoutName: String?` (cached for display)

---

## 🎨 UI Components

### **Reusable Components**
- ✅ **SuccessPill**: Auto-dismiss Notifications (3s)
- ✅ **TimerSection**: Rest Timer & Workout Duration (schwarzer Hintergrund)
- ✅ **CompactExerciseCard**: Moderne Exercise Cards (39pt corners, 24pt padding)
- ✅ **CompactSetRow**: Set-Zeilen mit invertierten Checkboxen
- ✅ **EditExerciseDetailsView**: Form mit Zeit/Reps Toggle

### **Design System**
- **Corner Radius**: 39pt (iPhone Display Radius)
- **Card Padding**: 24pt horizontal
- **Button Size**: .callout (klein & dezent)
- **Button Color**: Color.gray (explizit grau, nicht tint)
- **Checkbox Size**: 24x24pt (kompakt)
- **Typography**: 24pt Exercise Name, 28pt Weight, 12pt Units

---

## 🐛 Known Issues

**None currently!** 🎉

---

## 🚀 Next Steps

### **Potential Future Features**
1. **Exercise Templates**: Vordefinierte Übungssammlungen
2. **Progress Charts**: Visualisierung von Kraft-/Gewichtsentwicklung
3. **Rest Day Tracker**: Pausentage markieren
4. **Custom Exercise Creation**: Eigene Übungen erstellen
5. **Workout History**: Vergangene Sessions durchsuchen
6. **Export/Import**: Daten sichern/teilen
7. **Apple Watch Support**: Workout-Tracking am Handgelenk
8. **Social Features**: Workouts mit Freunden teilen

### **Technical Improvements**
1. Unit Tests für Use Cases
2. UI Tests für kritische Flows
3. Performance Profiling (SwiftData Queries)
4. Accessibility Labels
5. Localization (Mehrsprachigkeit)

---

## 📝 Development Notes

### **Git Workflow**
- Feature-Branches für größere Features (`feature/redesign-exercise-card`)
- Descriptive Commit Messages
- Regular Documentation Updates
- Clean merge strategy

### **Code Style**
- SwiftLint (TODO: Setup)
- Clean Architecture Principles
- MARK Comments für Struktur
- Comprehensive Inline Documentation

### **Testing Strategy**
- Manual Testing in Simulator
- Real Device Testing für Performance
- Console Logging für Debugging

---

## 🎯 Session 6 Summary

**Main Focus:** UI Redesign + Performance Optimization

### **Part 1: Modern Dark Theme Redesign**

**Achievements:**
1. ✅ Komplettes UI Redesign zu modernem Dark Theme
2. ✅ Schwarzer Hintergrund mit weißen Exercise Cards
3. ✅ 39pt Corner Radius (iPhone Display Radius)
4. ✅ Invertierte Checkboxen (schwarz mit weißem Haken)
5. ✅ Optimierte Typografie (24pt Exercise Name)
6. ✅ Cleaner Card Header (ohne Dot, ohne 3-Dot-Menu)
7. ✅ Graue Buttons statt blau (einheitliches Design)
8. ✅ Timer Section bis zum oberen Rand
9. ✅ Skip-Button als Icon (forward.fill)
10. ✅ Memories-Icon für Show/Hide Completed
11. ✅ Reorder nur noch in Card-Footer (arrow.up.arrow.down.circle)
12. ✅ 24pt Padding für bessere Lesbarkeit
13. ✅ Subtiles Notizen-Field ohne Hintergrund

**Design Principles Applied:**
- **ULTRATHINK**: Pixel-genaue Details beachtet
- **Consistency**: Einheitliche Farben und Größen
- **Simplicity**: Unnötige Elemente entfernt
- **Spacing**: Mehr Luft zwischen Elementen
- **Contrast**: Schwarz/Weiß für optimale Lesbarkeit

### **Part 2: Performance Optimization**

**Problem 1: Mark All Complete Delay (1-2 Sekunden)**

**Root Cause:** SwiftUI Animationen verlangsamten UI-Updates
- Database operations waren sehr schnell (~0.013s)
- `.animation()` und `.transition()` Modifiers verursachten Verzögerung

**Solution:**
```swift
// REMOVED:
.animation(.timingCurve(0.2, 0.0, 0.0, 1.0, duration: 0.3), value: showAllExercises)
.transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), 
                       removal: .opacity.combined(with: .move(edge: .top))))
```

**Result:** ⚡ Instant UI updates beim Markieren von Übungen als abgeschlossen

**Problem 2: View-Flash nach Workout-Abschluss**

**Root Cause:** 
- ActiveWorkoutSheetView zeigte kurz `noSessionView` zwischen Summary und HomeView
- WorkoutSummaryView wurde als Sheet ÜBER ActiveWorkoutSheetView angezeigt
- Beim Schließen der Summary sah man kurz die leere View dahinter

**Solution - New Architecture:**

1. **SessionStore**: Neue `completedSession` Property
```swift
var completedSession: DomainWorkoutSession?

func endSession() async {
    // Save to completedSession for summary
    completedSession = finishedSession
    // Clear active session immediately
    currentSession = nil
}
```

2. **ActiveWorkoutSheetView**: Auto-Dismiss
```swift
if let session = sessionStore.currentSession {
    // Show workout UI
} else {
    // No session - dismiss immediately
    Color.clear.onAppear { dismiss() }
}
```

3. **HomeView**: Summary Sheet Management
```swift
.sheet(isPresented: $showWorkoutSummary) {
    if let session = sessionStore.completedSession {
        WorkoutSummaryView(session: session) { ... }
    }
}
.onChange(of: sessionStore.completedSession) { _, newValue in
    showWorkoutSummary = (newValue != nil)
}
```

**Result:** 🎯 Nahtloser Übergang ohne Flash: Beenden → Dismiss → Summary → HomeView

### **Bug Fixes**

**Mark All Complete Button:**
- Problem: Button funktionierte nur bei erster Übung
- Ursache: `@ViewBuilder` nicht verwendet, Callback-Identität ging verloren
- Fix: `@ViewBuilder` mit expliziten Closures, `.buttonStyle(.plain)`

**isFinished Reset:**
- Problem: Nach Finish → Add Set → Complete Last Set wurde Übung nicht ausgeblendet
- Fix: `AddSetUseCase` setzt jetzt `isFinished = false`

**Notification Icons:**
- Problem: Zwei verwirrende Checkmark-Icons (Show/Hide und Mark Complete)
- Fix: Show/Hide Icon geändert zu `memories` SF Symbol

**Workout Complete Message:**
- Problem: Leere View nach dem Abschließen aller Übungen
- Fix: `allExercisesFinished()` Funktion, prüft `isFinished` Flag

### **Files Modified:**
- `Presentation/Stores/SessionStore.swift`
- `Presentation/Views/Home/HomeViewPlaceholder.swift`
- `Presentation/Views/ActiveWorkout/ActiveWorkoutSheetView.swift`
- `Presentation/Views/ActiveWorkout/Components/CompactExerciseCard.swift`
- `Presentation/Views/ActiveWorkout/Components/CompactSetRow.swift`
- `Presentation/Views/ActiveWorkout/Components/TimerSection.swift`
- `Domain/UseCases/Session/FinishExerciseUseCase.swift`
- `Domain/UseCases/Session/AddSetUseCase.swift`

### **Performance Metrics:**

**Before:**
- Mark Complete: 1-2 seconds delay ❌
- View transitions: Flash visible ❌

**After:**
- Mark Complete: Instant (~0.013s DB + 0s animation) ✅
- View transitions: Seamless, no flash ✅

### **Git Commits (Session 6):**
1. Feature branch created: `feature/redesign-exercise-card`
2. UI redesign commits: ~11 commits
3. Merged to main
4. Performance fixes: 3 commits
   - `f8d66a8` - Remove animations for instant completion
   - `af8bf33` - Eliminate flash on workout completion
   - `fc3aa82` - Remove undefined variables

**Total Lines Changed:** ~300+

---

## 📞 Support & Contact

**Developer:** Ben Kohler  
**Project:** GymBo V2  
**iOS Target:** 17.0+  
**Architecture:** Clean Architecture + SwiftData

---

*This document reflects the current state as of Session 6 (2025-10-24)*
