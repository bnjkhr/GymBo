# GymBo V2

**iOS Workout Tracking App** - Built with SwiftUI, SwiftData & Clean Architecture

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-purple.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

> **Status:** ✅ MVP Functional - Active Workout Session Management Working

GymBo ist eine moderne iOS App zum Tracken von Gym-Workouts mit Fokus auf schnelle Bedienung während des Trainings. Die App verwendet Clean Architecture mit iOS 17+ Features wie `@Observable` und SwiftData.

---

## Features

### Implemented (MVP)

- **Active Workout Tracking**
  - ScrollView-basiertes Workout Interface
  - Live Rest Timer (90s default, ±15s anpassbar)
  - Workout Duration Timer
  - Compact Exercise Cards mit Set-Completion
  - One-tap Set-Completion mit Haptic Feedback
  - Show/Hide completed exercises
  - Session Persistence (automatische Wiederherstellung nach App-Restart)

- **Session Management**
  - Start Session (mit Test-Workouts)
  - Complete Sets (mit orderIndex-basierter Reihenfolge)
  - End Session (mit Workout Summary)
  - Session Restoration (aktive Sessions werden beim App-Start geladen)

- **Clean Architecture**
  - 4-Layer Architecture (Domain, Data, Presentation, Infrastructure)
  - Use Case Pattern für Business Logic
  - Repository Pattern mit SwiftData
  - Dependency Injection Container
  - iOS 17+ `@Observable` State Management

### In Development

- Exercise Repository (aktuell hardcoded Test-Daten)
- Workout Repository (Templates)
- Weight/Reps Editing während Session
- Reordering von Exercises & Sets
- Session History & Statistics

---

## Tech Stack

| Layer | Technologies |
|-------|-------------|
| **UI** | SwiftUI 5.0+, iOS 17+ `@Observable` |
| **Persistence** | SwiftData (iOS 17+) |
| **Architecture** | Clean Architecture (4 Layers) |
| **State Management** | Feature Stores (Redux-style) |
| **Dependency Injection** | Custom DI Container |
| **Patterns** | Use Cases, Repository, Mapper |

---

## Architecture

GymBo folgt **Clean Architecture** mit strikter Dependency Rule (Abhängigkeiten zeigen nach innen):

```
┌─────────────────────────────────────────────────┐
│  Presentation Layer (SwiftUI)                   │
│  - Views, Stores, Services                      │
├─────────────────────────────────────────────────┤
│  Infrastructure Layer (DI, Logging)             │
│  - DependencyContainer, AppLogger               │
├─────────────────────────────────────────────────┤
│  Data Layer (SwiftData)                         │
│  - Repositories, Mappers, Entities              │
├─────────────────────────────────────────────────┤
│  Domain Layer (Business Logic)                  │
│  - Entities, Use Cases, Repository Protocols    │
│  - Framework-unabhängig!                        │
└─────────────────────────────────────────────────┘
```

### Vorteile

- **Testability:** Use Cases sind pure Swift (keine SwiftUI/SwiftData Dependencies)
- **Maintainability:** Klare Verantwortlichkeiten pro Layer
- **Flexibility:** Data Layer austauschbar (SwiftData → CoreData möglich)
- **Scalability:** Neue Features via neue Use Cases

Mehr Details: [TECHNICAL_CONCEPT_V2.md](Dokumentation/V2/TECHNICAL_CONCEPT_V2.md)

---

## Project Structure

```
GymBo/
├── Domain/                              # Business Logic (Framework-unabhängig)
│   ├── Entities/
│   │   ├── WorkoutSession.swift         # Domain Session Model
│   │   ├── SessionExercise.swift        # Domain Exercise Model
│   │   └── SessionSet.swift             # Domain Set Model
│   ├── UseCases/
│   │   └── Session/
│   │       ├── StartSessionUseCase.swift
│   │       ├── CompleteSetUseCase.swift
│   │       └── EndSessionUseCase.swift
│   └── RepositoryProtocols/
│       └── SessionRepositoryProtocol.swift
│
├── Data/                                # Data Access & Mapping
│   ├── Repositories/
│   │   └── SwiftDataSessionRepository.swift
│   ├── Mappers/
│   │   └── SessionMapper.swift          # Domain ↔ Entity Mapping
│   └── SwiftDataEntities.swift          # @Model Entities
│
├── Presentation/                        # UI & State
│   ├── Stores/
│   │   └── SessionStore.swift           # Feature Store (@Observable)
│   ├── Services/
│   │   └── RestTimerStateManager.swift  # Timer State
│   └── Views/
│       ├── Main/
│       │   └── MainTabView.swift
│       ├── Home/
│       │   └── HomeViewPlaceholder.swift
│       └── ActiveWorkout/
│           ├── ActiveWorkoutSheetView.swift
│           └── Components/
│               ├── TimerSection.swift
│               ├── CompactExerciseCard.swift
│               ├── CompactSetRow.swift
│               └── BottomActionBar.swift
│
├── Infrastructure/                      # Framework Isolation
│   ├── DI/
│   │   └── DependencyContainer.swift
│   └── AppLogger.swift
│
├── Dokumentation/
│   └── V2/
│       ├── CURRENT_STATE.md             # Implementation Status
│       ├── TODO.md                      # Task List
│       ├── TECHNICAL_CONCEPT_V2.md      # Architecture Details
│       └── UX_CONCEPT_V2.md             # UX/UI Konzept
│
└── GymBoApp.swift                       # App Entry Point
```

---

## Getting Started

### Requirements

- **Xcode:** 15.0+
- **iOS:** 17.0+ (wegen SwiftData & `@Observable`)
- **Swift:** 5.9+

### Installation

1. **Clone Repository**
   ```bash
   git clone https://github.com/bnjkhr/GymBo.git
   cd GymBo
   ```

2. **Open in Xcode**
   ```bash
   open GymBo.xcodeproj
   ```

3. **Build & Run**
   - Select Simulator (iPhone 15 Pro recommended)
   - Press `Cmd + R`

### First Launch

1. App startet mit HomeView
2. Tap "Start Workout" → Öffnet Active Workout Sheet
3. Test-Workout mit 3 Übungen wird geladen
4. Tap auf Checkboxes um Sets zu completen
5. Rest Timer startet automatisch nach jedem Set
6. Tap "Beenden" → Workout Summary

---

## Key Concepts

### 1. Session Store Pattern (iOS 17+ @Observable)

GymBo verwendet `@Observable` statt `ObservableObject` für bessere Performance:

```swift
@MainActor
@Observable
final class SessionStore {
    var currentSession: DomainWorkoutSession?
    
    let startSessionUseCase: StartSessionUseCase
    let completeSetUseCase: CompleteSetUseCase
    let endSessionUseCase: EndSessionUseCase
    
    func startSession(workoutId: UUID) async { ... }
    func completeSet(exerciseId: UUID, setId: UUID) async { ... }
}

// In Views:
@Environment(SessionStore.self) private var sessionStore
```

### 2. Repository Pattern mit In-Place Updates

**Wichtig:** SwiftData Relationships erfordern In-Place Updates:

```swift
// ❌ NICHT so (verliert SwiftData Referenzen):
entity.exercises.removeAll()
entity.exercises = domain.exercises.map { toEntity($0) }

// ✅ SONDERN so (behält Referenzen):
for domainExercise in domain.exercises {
    if let existing = entity.exercises.first(where: { $0.id == domainExercise.id }) {
        updateExerciseEntity(existing, from: domainExercise)
    }
}
```

### 3. orderIndex Pattern

**SwiftData @Relationship Arrays haben KEINE garantierte Reihenfolge!**

Lösung: Explizites `orderIndex` Property:

```swift
struct DomainSessionExercise {
    let id: UUID
    var orderIndex: Int  // ← Explizite Reihenfolge
    var sets: [DomainSessionSet]
}

// In Views IMMER sortieren:
ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
    CompactExerciseCard(exercise: exercise)
}
```

---

## Current Status

### What Works

- ✅ Start/End Session
- ✅ Complete Sets (one-tap)
- ✅ Rest Timer (auto-start, ±15s, Skip)
- ✅ Session Persistence & Restoration
- ✅ Compact UI Design (ScrollView)
- ✅ Haptic Feedback
- ✅ Workout Summary

### Known Limitations

- Exercise Names: Hardcoded ("Übung 1", "Übung 2")
- Workout Templates: Test-Daten statt echte Workouts
- Weight/Reps Editing: Nicht editierbar (UI zeigt nur an)
- History: Keine Historie-Ansicht
- Statistics: Keine Stats/Charts

### Next Steps

1. Exercise Repository (Namen, Equipment, Kategorien)
2. Workout Repository (Templates)
3. Weight/Reps Editing (Sheet-basiert)
4. Session History
5. Reordering (Exercises & Sets)

Details: [TODO.md](Dokumentation/V2/TODO.md)

---

## Documentation

| Datei | Beschreibung |
|-------|--------------|
| [CURRENT_STATE.md](Dokumentation/V2/CURRENT_STATE.md) | Aktueller Implementierungsstatus, Code-Beispiele, Bugs |
| [TODO.md](Dokumentation/V2/TODO.md) | Priorisierte Aufgaben, Session Notes |
| [TECHNICAL_CONCEPT_V2.md](Dokumentation/V2/TECHNICAL_CONCEPT_V2.md) | Vollständige Architektur-Specs, 6-Wochen Roadmap |
| [UX_CONCEPT_V2.md](Dokumentation/V2/UX_CONCEPT_V2.md) | UX/UI Design, User Flows, Wireframes |

---

## Key Learnings

### 1. SwiftData Gotchas

- **@Relationship Arrays:** Keine garantierte Reihenfolge → `orderIndex` verwenden
- **Entity Recreation:** Verliert Referenzen → In-place updates
- **Fetch Performance:** Eager Loading via `#Predicate`

### 2. iOS 17+ @Observable

- **Vorteile:** Weniger Boilerplate, bessere Performance
- **Nachteile:** Nicht mit `ObservableObject` kompatibel
- **Migration:** `@EnvironmentObject` → `@Environment`

### 3. Clean Architecture Pays Off

- Bug-Fixes sind isoliert (z.B. Mapper-Fix betraf nur Data Layer)
- Use Cases sind testbar (keine SwiftUI Dependencies)
- Neue Features via neue Use Cases (keine Spaghetti-Code)

---

## Testing

### Current Coverage

- **Domain Layer:** 44 Tests (laut Dokumentation)
- **Integration Tests:** 0
- **UI Tests:** 0

### Planned Tests

- [ ] Use Case Unit Tests (CompleteSetUseCase, etc.)
- [ ] Repository Integration Tests (SwiftData)
- [ ] Store Tests (SessionStore)
- [ ] UI Tests (Critical User Flows)

---

## Performance

**Targets:** (aus TECHNICAL_CONCEPT_V2.md)

- ✅ UI Response: <100ms (erreicht - instant)
- ✅ Session Start: <500ms (erreicht - ~200ms)
- ✅ SwiftData Fetch: <100ms (erreicht - in-memory cache)

**Optimierungen:**

- LazyVStack für Exercise List
- In-place updates (keine Entity-Recreation)
- @MainActor für UI Thread Safety
- Optimistic Updates (instant UI feedback)

---

## Contributing

**Status:** Private Repository (nicht Open Source)

Für Feature-Requests oder Bug-Reports:
- Siehe [TODO.md](Dokumentation/V2/TODO.md)
- Kontakt: [@bnjkhr](https://github.com/bnjkhr)

---

## License

**Private Project** - All Rights Reserved

---

## Contact

**Developer:** Benjamin Kohler ([@bnjkhr](https://github.com/bnjkhr))  
**Project Start:** Oktober 2025  
**Current Version:** v2.0.0 (MVP)  
**Last Updated:** 2025-10-22
