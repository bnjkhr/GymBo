# GymBo V2 - Dokumentation

**Stand:** 2025-10-26
**Version:** 2.3.0
**Status:** ✅ MVP COMPLETE - Production Ready with Workout Folders

---

## 📖 Dokumentations-Übersicht

### ⭐ START HIER
- **[CURRENT_STATE.md](./CURRENT_STATE.md)** - Aktueller Implementierungsstatus (was funktioniert)
- **[TODO.md](./TODO.md)** - Priorisierte Aufgaben (was als nächstes)

### 📋 Architektur & Design
- **[TECHNICAL_CONCEPT_V2.md](./TECHNICAL_CONCEPT_V2.md)** - Clean Architecture Specs (vollständig)
- **[UX_CONCEPT_V2.md](./UX_CONCEPT_V2.md)** - UX/UI Design & User Flows

### 🔥 Feature Documentation
- **[Features/WarmupSets/](./Features/WarmupSets/)** - Warmup Sets Feature (Complete)
  - Auto-calculated warmup sets
  - 3 progressive strategies
  - Architecture rules & bug fixes
  - Production ready
- **[Features/SupersetCircuit/](./Features/SupersetCircuit/)** - Superset & Circuit Training (Backend Complete)
  - Superset training (paired exercises)
  - Circuit training (station rotation)
  - Round tracking & completion
  - User guide & examples
  - UI for creation pending

### 📚 Weitere Dokumentation
- **[V2_CLEAN_ARCHITECTURE_ROADMAP.md](./V2_CLEAN_ARCHITECTURE_ROADMAP.md)** - Migrations-Roadmap
- **[V2_MASTER_PROGRESS.md](./V2_MASTER_PROGRESS.md)** - Sprint-Progress
- **[SPRINT_*.md](./SPRINT_1_1_PROGRESS.md)** - Sprint-Reports

### 🗄️ Archiviert
- **[Archive/ACTIVE_WORKOUT_REDESIGN.md](./Archive/ACTIVE_WORKOUT_REDESIGN.md)** - Design-Prozess (historisch)

---

## 🚀 Quick Start

**Neuer Entwickler:**
1. Lies `CURRENT_STATE.md` (10 Min) - Was ist implementiert?
2. Lies `TECHNICAL_CONCEPT_V2.md` Sections 1-3 (30 Min) - Wie funktioniert es?
3. Öffne Xcode, Run (⌘R), teste Session Start
4. Lies `TODO.md` (5 Min) - Was kommt als nächstes?

**Neue Feature implementieren:**
1. Checke `TODO.md` für Priorität
2. Folge Clean Architecture Pattern aus `TECHNICAL_CONCEPT_V2.md`
3. Update `CURRENT_STATE.md` wenn fertig
4. Add Task in `TODO.md` wenn neue TODOs entstehen

---

## 📊 Projekt-Status

### ✅ KOMPLETT FERTIG (Production Ready)

**Workout Management:**

- ✅ Create/Edit/Delete Workouts
- ✅ Toggle Favorite (Stern-Icon)
- ✅ Workout List mit Favoriten-Sektion
- ✅ **Workout Folders/Categories** (organize workouts in colored folders)
  - Create/Edit/Delete Folders
  - 8 predefined colors
  - Move workouts between folders (context menu)
  - Collapsible folder sections
  - Auto-move to "Ohne Kategorie" on folder deletion
- ✅ **Superset Training** (Backend complete - UI pending)
  - Paired exercises (A1/A2, B1/B2)
  - Round-based progression
  - SupersetWorkoutView with specialized UI
  - See [User Guide](./Features/SupersetCircuit/USER_GUIDE.md)
- ✅ **Circuit Training** (Backend complete - UI pending)
  - Station rotation (A→B→C→D→E)
  - Round tracking
  - CircuitWorkoutView with station overview
  - See [User Guide](./Features/SupersetCircuit/USER_GUIDE.md)
- ✅ Pull-to-refresh
- ✅ WorkoutStore mit allen Use Cases
- ✅ 6 Comprehensive Sample Workouts (2x Maschinen, 2x Freie Gewichte, 2x Gemischt)
- ✅ Difficulty Levels (Anfänger 🍃, Fortgeschritten 🔥, Profi ⚡)
- ✅ Equipment Type Labels (Maschine, Freie Gewichte, Gemischt)
- ✅ **Quick-Setup Workout Creation** (wizard for fast workout creation)
  - Equipment category selection
  - Duration & goal selection
  - AI-based exercise generation
  - Preview & customize before saving

**Exercise Library:**

- ✅ 145+ Übungen aus CSV (ExerciseSeedData)
- ✅ Search Funktion
- ✅ Filter nach Muskelgruppe & Equipment
- ✅ ExerciseDetailView mit Instructions
- ✅ Modern Card Design
- ✅ Create Custom Exercises (Multi-Select Muscles, Equipment, Difficulty)
- ✅ Delete Custom Exercises (Catalog exercises protected)

**Workout Detail & Exercise Management:**

- ✅ Add Multiple Exercises (Multi-Select Picker)
- ✅ Edit Exercise Details (Sets, Reps, Time, Weight, Rest, Notes)
- ✅ Remove Exercise (Context Menu)
- ✅ Reorder Exercises (Drag & Drop mit permanent save)
- ✅ Exercise Names werden angezeigt (aus Repository!)
- ✅ Equipment Icons werden angezeigt

**Active Workout Session:**

- ✅ Start/End/Cancel Session
- ✅ Complete/Uncomplete Sets (Toggle)
- ✅ Add/Remove Sets dynamisch
- ✅ Update Set Weight/Reps
- ✅ Update All Sets in bulk
- ✅ **Per-Set Rest Times** (NEU - individual rest times for each set)
- ✅ Exercise Notes inline editing
- ✅ Auto-Finish Exercise
- ✅ Reorder Exercises (session-only oder permanent)
- ✅ Add Exercise to Active Session (Plus-Button mit permanent save toggle)
- ✅ Rest Timer with UserNotifications (background support)
- ✅ Rest Timer cancellation on workout end/cancel
- ✅ Show/Hide completed exercises
- ✅ Exercise Counter (2/7)
- ✅ Session Persistence & Restoration
- ✅ Pause/Resume Session

**UI/UX:**

- ✅ Modern Dark Theme (schwarz + weiße Cards)
- ✅ **Brand Color** #F77E2D (custom GymBo orange)
- ✅ 39pt Corner Radius (iPhone display radius)
- ✅ Inverted Checkboxes
- ✅ Haptic Feedback
- ✅ Success Pills (auto-dismiss 3s)
- ✅ Profile Button (HomeView rechts oben)
- ✅ iOS 26 Modern Card Design
- ✅ TabBar Auto-Hide (.tabBarMinimizeBehavior(.onScrollDown))
- ✅ Difficulty Badges (Grayscale: light/medium/dark gray mit Icons 🍃🔥⚡)
- ✅ Equipment Type Labels (Under workout name in gray)
- ✅ HomeView Redesign (Greeting, Locker Number, Workout Calendar Strip)
- ✅ Collapsible Sections (Favoriten, Folders, Ohne Kategorie)
- ✅ Difficulty labels removed from Exercise List (kept in Detail View)

**Architecture:**

- ✅ Clean Architecture (4 Layers)
- ✅ **32 Use Cases** (Domain Layer)
  - 19 Session Use Cases (Start, End, Cancel, CompleteGroupSet, AdvanceToNextRound, etc.)
  - 11 Workout Use Cases (Create, Update, Delete, CreateSuperset, CreateCircuit, etc.)
  - 2 Exercise Use Cases (Create, Delete)
- ✅ **3 Repositories + Mappers** (Data Layer)
  - SwiftDataWorkoutRepository (with folder & workout type support)
  - SwiftDataSessionRepository (with group support)
  - SwiftDataExerciseRepository
- ✅ **13 SwiftData Entities** (@Model classes - Schema V6)
  - NEW: ExerciseGroupEntity, SessionExerciseGroupEntity
- ✅ **10 Domain Entities** (Pure Swift structs)
  - NEW: ExerciseGroup, SessionExerciseGroup, WorkoutType enum
- ✅ 3 Stores @Observable (Presentation) - SessionStore, WorkoutStore, SessionHistoryStore
- ✅ DI Container (Infrastructure)
- ✅ SwiftData Migration Plan (V1 → V6)
- ✅ Refresh Trigger Pattern (reaktive UI updates)
- ✅ @Bindable + local @State for UI reactivity

### 🟡 Nice-to-Have (Später)

- Superset/Circuit Creation UI (Backend fertig, UI fehlt noch)
- Statistics & Charts
- Localization Support (Deutsch/Englisch)
- Profile Page enhancements

---

## 🏗️ Architektur-Überblick

```
Domain (Business Logic)
├── Entities (DomainWorkoutSession, SessionExercise, SessionSet)
├── Use Cases (StartSession, CompleteSet, EndSession)
└── Repository Protocols (Contracts)

Data (Persistence)
├── Repositories (SwiftDataSessionRepository)
├── Mappers (SessionMapper - Domain ↔ Entity)
└── SwiftData Entities (@Model)

Presentation (UI)
├── Stores (SessionStore - Feature Store Pattern)
├── Views (ActiveWorkoutSheetView, TimerSection, CompactExerciseCard)
└── Services (RestTimerStateManager)

Infrastructure (Framework Isolation)
└── DI (DependencyContainer)
```

**Dependency Rule:** Abhängigkeiten zeigen nach innen (Domain hat keine Framework-Dependencies)

---

## 🎨 UI Design

**Active Workout:**
- ScrollView mit ALLEN Übungen (nicht TabView)
- Timer Section (conditional, schwarzer Hintergrund)
- Compact Exercise Cards (39pt corner radius)
- Bottom Action Bar (Repeat, Add, Reorder)
- Eye-Icon Toggle (Show/Hide completed)

**Details:** Siehe `CURRENT_STATE.md` Section "UI Design Specs"

---

## 🧪 Testing

**Domain Layer:** 44 Tests (Use Cases)  
**Integration Tests:** 0  
**UI Tests:** 0  

**TODO:** Siehe `TODO.md` Section "Testing"

---

## 📝 Conventions

### Code Style
- Swift Standard Style
- No Magic Numbers (use enums)
- German UI Text
- English Code Comments

### Naming
- Domain Entities: `Domain*` prefix (e.g., `DomainWorkoutSession`)
- Use Cases: `*UseCase` suffix (e.g., `StartSessionUseCase`)
- Stores: `*Store` suffix (e.g., `SessionStore`)
- Repositories: `*Repository` suffix

### File Structure
```
Domain/
├── Entities/
├── UseCases/
│   └── Session/
└── RepositoryProtocols/

Data/
├── Repositories/
└── Mappers/

Presentation/
├── Stores/
├── Services/
└── Views/
    └── [Feature]/
        └── Components/
```

---

## 🐛 Bug Reports

**Bekannte Bugs:** Keine (alle gefixt!)

**Neue Bugs melden:**
1. Beschreibe Reproduktions-Schritte
2. Console Logs anhängen
3. Screenshots/Videos wenn möglich
4. Add to `TODO.md` mit 🔴 KRITISCH Label

---

## 📚 Weitere Ressourcen

**Clean Architecture:**
- Uncle Bob's Blog: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- iOS Clean Architecture: https://tech.olx.com/clean-architecture-and-mvvm-on-ios-c9d167d9f5b3

**SwiftData:**
- Apple Docs: https://developer.apple.com/documentation/swiftdata

**SwiftUI:**
- Apple Docs: https://developer.apple.com/documentation/swiftui

---

## 🤝 Contributing

**Before implementing:**
1. Check `TODO.md` für Priorität
2. Lese `TECHNICAL_CONCEPT_V2.md` für Architektur
3. Folge Clean Architecture Patterns

**After implementing:**
1. Update `CURRENT_STATE.md`
2. Update `TODO.md`
3. Add Tests (Domain Layer minimum)
4. Build ohne Warnings

---

**Letzte Aktualisierung:** 2025-10-24 (Session 8+)
**Maintainer:** Ben Kohler
