# GymBo V2 - Current State

**Last Updated:** 2025-10-24  
**Session:** 5

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
- Icon Updates (Auge → Clipboard für Übersicht)
- Intelligente Notifications:
  - "Nächste Übung" nach abgeschlossener Übung
  - "Workout done! 💪🏼" nach letzter Übung
- Success Pill in ActiveWorkoutSheetView (sichtbar über allem)

### **Bug Fixes (Session 5)** ✅
- ✅ Rest Timer startet nicht mehr automatisch beim Workout-Start
- ✅ Workout-Name wird korrekt im Timer angezeigt (nicht "Workout")
- ✅ "Nächste Übung" Notification erscheint jetzt sichtbar
- ✅ Keyboard funktioniert korrekt (Software Keyboard aktiviert)
- ✅ TextEditor Keyboard lässt sich schließen mit "Fertig"-Button
- ✅ Optional targetReps für zeitbasierte Übungen behoben

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
│   │       ├── ActiveWorkoutSheetView.swift (Success Pill Overlay)
│   │       └── Components/
│   │           └── TimerSection.swift (Exercise Counter: 2/7)
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

### **Schema Changes (Session 5)**

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
- ✅ **TimerSection**: Rest Timer & Workout Duration
- ✅ **CompactExerciseCard**: Exercise Display mit Sets
- ✅ **EditExerciseDetailsView**: Form mit Zeit/Reps Toggle

### **Icons Updated**
- ❌ `eye.fill` / `eye.slash.fill`
- ✅ `list.bullet.clipboard.fill` / `list.bullet.clipboard`

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
- Feature-Branches für größere Features
- Descriptive Commit Messages
- Regular Documentation Updates

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

## 🎯 Session 5 Summary

**Main Focus:** Bug Fixes & Polish

**Achievements:**
1. ✅ Time-based Exercise Support implementiert
2. ✅ Exercise Counter im Timer (2/7)
3. ✅ Smart Notifications ("Nächste Übung" vs "Workout done!")
4. ✅ Success Pill Visibility behoben
5. ✅ Workout-Name Mapping korrigiert
6. ✅ Rest Timer Auto-Start behoben
7. ✅ Keyboard Issues gelöst (Software Keyboard + Focus Management)
8. ✅ Icon Updates (Clipboard statt Auge)

**Files Modified:**
- `Domain/Entities/WorkoutExercise.swift`
- `Domain/UseCases/Workout/UpdateWorkoutExerciseUseCase.swift`
- `Domain/UseCases/Session/StartSessionUseCase.swift`
- `Data/Entities/WorkoutSessionEntity.swift`
- `Data/Mappers/SessionMapper.swift`
- `Data/Mappers/WorkoutMapper.swift`
- `Presentation/Views/WorkoutDetail/EditExerciseDetailsView.swift`
- `Presentation/Views/WorkoutDetail/WorkoutDetailView.swift`
- `Presentation/Views/ActiveWorkout/ActiveWorkoutSheetView.swift`
- `Presentation/Views/ActiveWorkout/Components/TimerSection.swift`
- `Presentation/Stores/SessionStore.swift`
- `Presentation/Stores/WorkoutStore.swift`

**Lines of Code Changed:** ~500+

---

## 📞 Support & Contact

**Developer:** Ben Kohler  
**Project:** GymBo V2  
**iOS Target:** 17.0+  
**Architecture:** Clean Architecture + SwiftData

---

*This document reflects the current state as of Session 5 (2025-10-24)*
