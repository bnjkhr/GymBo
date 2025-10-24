# GymBo V2 - TODO Liste

**Stand:** 2025-10-24
**Current Phase:** ✅ MVP COMPLETE - All Core Features Implemented
**Next Phase:** Nice-to-Have Features & Polish
**Letzte Änderungen:** Session 8+ complete, Dokumentation aktualisiert

---

## ✅ MVP COMPLETE - Alle Core Features Implementiert!

### Was ist FERTIG (Production Ready):

**1. Workout Management** ✅
- Create/Edit/Delete Workouts
- Toggle Favorite
- WorkoutStore mit allen Use Cases
- Pull-to-refresh

**2. Exercise Library** ✅
- 145+ Übungen aus CSV
- Search & Filter (Muskelgruppe, Equipment)
- ExercisesView komplett implementiert
- ExerciseDetailView mit Instructions

**3. Workout Detail & Exercise Management** ✅
- Add Multiple Exercises (Multi-Select Picker)
- Edit Exercise Details (Sets, Reps, Time, Weight, Rest, Notes)
- Remove Exercise
- Reorder Exercises (Drag & Drop mit permanent save)
- Exercise Names werden geladen & angezeigt

**4. Active Workout Session** ✅
- Start/End/Cancel Session
- Complete/Uncomplete Sets
- Add/Remove Sets
- Update Set Weight/Reps
- Update All Sets
- Exercise Notes
- Auto-Finish Exercise
- Reorder Exercises (session-only oder permanent)
- Rest Timer (90s mit ±15s)
- Show/Hide completed
- Exercise Counter
- Session Persistence & Restoration

**5. UI/UX** ✅
- Modern Dark Theme
- 39pt Corner Radius
- Inverted Checkboxes
- Haptic Feedback
- Success Pills
- Profile Button (HomeView)
- iOS 26 Modern Card Design

**6. Architecture** ✅
- Clean Architecture (4 Layers)
- 17 Use Cases
- 3 Repositories + Mappers
- 2 Stores @Observable
- DI Container
- SwiftData Migration Plan (SchemaV1, SchemaV2, GymBoMigrationPlan)

---

## 🟢 Optional - Migration Support (Für Zukunft)

### SwiftData Migration Support (DONE - bereits implementiert!)
**Status:** ✅ IMPLEMENTED (GymBoMigrationPlan.swift, SchemaV1.swift, SchemaV2.swift)
**Location:** `/Data/Migration/`

**Was bereits vorhanden:**
- ✅ SchemaV1 mit allen V1 Entities
- ✅ SchemaV2 mit Migration (exerciseId hinzugefügt)
- ✅ GymBoMigrationPlan registriert
- ✅ ModelContainer nutzt Migration Plan (Production Mode)
- ✅ DEBUG Mode: Database deletion DISABLED (commented out)

**Nächste Schritte (optional):**
- [ ] Write Unit Tests für Migrations
- [ ] Test Migration mit verschiedenen iOS Versionen
- [ ] Document Schema Change Process

---

## 📝 Session 6 Complete (2025-10-23) - PRODUCTION-READY REORDERING

### ✅ Implementierte Features:

**1. Exercise Reordering Feature**
- Drag & drop reordering in active sessions
- **Permanent save toggle** (updates workout template)
- ReorderExercisesSheet (dedicated UI, verhindert Button-Auto-Trigger Bug)
- Production-ready mit explizitem orderIndex handling

**2. Auto-Finish Exercise**
- Exercises auto-finish when all sets completed
- Auto un-finish when set uncompleted
- Integrated in CompleteSetUseCase

**3. Production-Ready Fixes (Critical!)**
- **StartSessionUseCase**: Uses explicit orderIndex from templates (not array position)
- **WorkoutMapper**: In-place updates (preserves SwiftData relationships)
- **SessionMapper**: Correctly updates orderIndex during reordering
- **All mappers**: Avoid entity recreation (performance + stability)

### 🧪 Testing Status:
- ✅ Session-only reorder works
- ✅ Permanent template reorder works
- ✅ Auto-finish works on last set completion
- ✅ UI updates immediately
- ✅ No exercise deletion or corruption

### 📦 Files Changed (12):
- `SessionMapper.swift` - orderIndex update fix
- `WorkoutMapper.swift` - in-place updates
- `StartSessionUseCase.swift` - explicit orderIndex
- `CompleteSetUseCase.swift` - auto-finish logic
- `SwiftDataWorkoutRepository.swift` - updateExerciseOrder()
- `WorkoutRepositoryProtocol.swift` - new method
- `SessionStore.swift` - reorder with permanent save
- `ActiveWorkoutSheetView.swift` - ReorderExercisesSheet
- `DependencyContainer.swift` - workoutRepository injection
- `WorkoutSeedData.swift` - TEST Multi Exercise workout

**Commit:** `30b3e6f` - "feat: Production-ready exercise reordering with auto-finish"

---

## 📝 Session Notes (2025-10-22)

### Erledigte Fixes heute:
1. ✅ **orderIndex Bug** - Sets/Exercises haben jetzt explizite Reihenfolge (SwiftData @Relationship hat keine garantierte Order!)
2. ✅ **@Observable Migration** - Von ObservableObject zu iOS 17+ @Observable für bessere Reaktivität
3. ✅ **Timer Auto-Start** - Timer startet nicht mehr automatisch beim Workout-Launch
4. ✅ **Timer Always Visible** - TimerSection zeigt immer entweder Rest Timer ODER Workout Duration
5. ✅ **Doppel-Tap Bug** - Sets können jetzt mit einem Klick abgehakt werden
6. ✅ **UI Cleanup** - Duplicate kg/reps Labels entfernt

### Wichtige Learnings:
- **SwiftData @Relationship Arrays haben KEINE garantierte Reihenfolge!** → Immer `orderIndex` verwenden
- **@Observable ist besser als ObservableObject** für komplexe State-Updates in SwiftUI
- **TextField in ForEach kann zu Crashes führen** → Erstmal als separates Feature planen
- **UUIDs statt Array-Indices** verwenden für eindeutige Identifikation (wichtig für Reordering!)

### Offene TODOs für nächste Session:
- Weight/Reps editierbar machen (neuer Ansatz mit Sheet/Alert statt inline TextFields)
- Exercise Names aus Repository laden (aktuell: "Übung 1", "Übung 2")
- UpdateSetUseCase implementieren für persistente Weight/Reps Änderungen

---

## 🎯 Nächste Features (Nice-to-Have)

### ✅ ERLEDIGT: Exercise Names, Equipment, Workout Repository

Die folgenden Punkte wurden bereits implementiert:
- ✅ Exercise Names werden angezeigt (aus ExerciseRepository)
- ✅ Equipment wird angezeigt (Icons in WorkoutDetailView)
- ✅ Workout Repository ist fertig (SwiftDataWorkoutRepository)
- ✅ Exercise Repository ist fertig (SwiftDataExerciseRepository)
- ✅ ExercisesView mit Search & Filter

---

## 🚀 Neue Features (aus notes.md)

### 1. Exercise Swap Feature (Medium Effort - 4-6 Std)
**Ziel:** Lange auf Übung drücken → Alternative Übungen vorschlagen

**User Story:**
- User drückt lange auf Übung in Workout Detail
- App zeigt Sheet mit gleichwertigen Alternativen (gleiche Muskelgruppe)
- User kann auswählen oder selbst suchen
- Toggle: "Änderung dauerhaft speichern" (in Template) oder nur für diese Session

**Implementation:**
```swift
// In WorkoutDetailView oder CompactExerciseCard
.onLongPressGesture {
    showExerciseSwapSheet = true
}

// ExerciseSwapSheet
- Load alternatives from ExerciseRepository (same muscle groups)
- Show list with search
- Toggle: savePermanently
- OnConfirm: Update workout template or session
```

**Dateien:**
- `/Presentation/Views/WorkoutDetail/ExerciseSwapSheet.swift` - NEW
- `/Domain/UseCases/Workout/SwapExerciseUseCase.swift` - NEW
- Update `WorkoutDetailView.swift`

---

### 2. Profile Page (Low Effort - 2-3 Std)
**Ziel:** Profilseite implementieren (Button ist schon da!)

**Features:**
- User Name & Profilbild
- Standardprofilbild wenn nicht gesetzt
- Settings (Theme, Rest Timer defaults)
- About Section (Version, Credits)

**Dateien:**
- `/Presentation/Views/Profile/ProfileView.swift` - Aktuell Placeholder, erweitern!
- `/Domain/Entities/UserProfile.swift` - Optional: Domain Model
- `/SwiftDataEntities.swift` - UserProfileEntity bereits vorhanden!

---

### 3. HomeView Redesign ✅ COMPLETE (Session 2025-10-24 Abend)
**Status:** ✅ Implementiert und gebaut

**Implementierte Features:**
1. ✅ Zeitbasierte Begrüßung ("Hey, guten Morgen!" / "Hey!" / "Hey, guten Abend!")
2. ✅ Spintnummer-Widget mit Lock/Unlock States
3. ✅ Workout Calendar Strip (14 Tage, Streak-Badge, Auto-Scroll)
4. ✅ Repository-Erweiterung: `fetchCompletedSessions(from:to:)`

**Neue Dateien:**
- ✅ `/Presentation/Views/Home/Components/GreetingHeaderView.swift`
- ✅ `/Presentation/Views/Home/Components/LockerNumberInputSheet.swift`
- ✅ `/Presentation/Views/Home/Components/WorkoutCalendarStripView.swift`

**Technische Details:**
- Spintnummer: `@AppStorage("lockerNumber")` für Persistierung
- Begrüßung: `.largeTitle` Font (konsistent mit anderen Views)
- Calendar: Lädt Sessions aus letzten 14 Tagen, berechnet Streak
- Design: iOS-native Components, Haptic Feedback

**Build Status:** ✅ BUILD SUCCEEDED

---

### 4. Session History (2-3 Stunden)
**Ziel:** Vergangene Workouts anzeigen

**Features:**
- Liste vergangener Sessions
- Filter nach Workout-Typ
- Session Detail View (read-only)
- Statistiken (Total Volume, Duration)

**UI:**
- Neuer Tab "Verlauf" oder in Progress Tab
- Session Cards mit Datum, Name, Stats

**Dateien:**
- `/Presentation/Views/History/SessionHistoryView.swift` - NEW
- `/Presentation/Views/History/SessionDetailView.swift` - NEW
- `/Domain/UseCases/Session/GetSessionHistoryUseCase.swift` - NEW
- Update `SessionRepository` mit `fetchRecentSessions()`

---

### 5. Localization Support (3-4 Stunden)
**Ziel:** App für Übersetzung vorbereiten

**Tasks:**
- Strings.swift mit allen Texten
- NSLocalizedString wrapper
- Localizable.strings (de, en)
- Export/Import Workflow

**Dateien:**
- `/Infrastructure/Localization/Strings.swift` - NEW
- `/Resources/de.lproj/Localizable.strings` - NEW
- `/Resources/en.lproj/Localizable.strings` - NEW

---

---

## 📊 Langfristig (Phase 2)

### 6. Statistics & Charts (Phase 3)
- Workout-Frequenz (Heatmap Calendar)
- Volumen-Trends (Line Charts)
- Personal Records (PRs)
- Progress per Exercise
- SwiftUI Charts Framework

### 7. Advanced Workout Builder
- Templates & Folders
- Superset Support
- Drop Sets, Pyramid Sets
- Custom Rest Timer per Exercise

### 8. Cloud Sync & Social
- iCloud Sync
- Share Workouts
- Social Feed (optional)

### 9. AI Features (Phase 4)
- Workout Generator (AI-basiert)
- Form Check (Video Analysis)
- Smart Progression Suggestions

---

## ✅ ABGESCHLOSSEN (Sessions 1-8+)

### Session 8+ (2025-10-24) - Documentation Update
- ✅ Reviewed entire codebase
- ✅ Updated README.md with actual status
- ✅ Updated TODO.md with new priorities
- ✅ Confirmed all MVP features complete

### Session 7 (2025-10-23) - Workout Management Complete
- ✅ Create/Edit/Delete Workouts
- ✅ Multi-select ExercisePicker
- ✅ Exercise Detail Editor (Time/Reps toggle)
- ✅ Standardized headers
- ✅ Fixed HomeView refresh bug

**Was implementiert wurde:**
- ✅ Exercise drag & drop reordering in active sessions
- ✅ Permanent save toggle (saves to workout template)
- ✅ ReorderExercisesSheet with dedicated UI
- ✅ Production-ready with explicit orderIndex
- ✅ In-place updates in WorkoutMapper & SessionMapper
- ✅ Auto-finish exercise when all sets completed

**Was noch aussteht:**
- [ ] Set reordering within exercises
- [ ] Undo/redo for reordering
- [ ] Haptic feedback during drag

**Original Requirements (ERFÜLLT):**
- ✅ **NIEMALS Index verwenden** für Identifikation
- ✅ **IMMER UUID verwenden** für eindeutige Identifikation
- ✅ Neue Reihenfolge wird im Workout persistiert
- ✅ orderIndex to Entities added
   }
   
   // Domain/Entities/SessionSet.swift
   struct DomainSessionSet {
       let id: UUID
       var orderIndex: Int  // ← NEU: Explizite Reihenfolge
       // ...
   }
   ```

2. **Add ReorderExerciseUseCase**
   ```swift
   protocol ReorderExerciseUseCase {
       func execute(
           sessionId: UUID,
           exerciseId: UUID,
           newIndex: Int
       ) async throws -> DomainWorkoutSession
   }
   ```

3. **Add ReorderSetUseCase**
   ```swift
   protocol ReorderSetUseCase {
       func execute(
           sessionId: UUID,
           exerciseId: UUID,
           setId: UUID,
           newIndex: Int
       ) async throws -> DomainWorkoutSession
   }
   ```

4. **UI Implementation**
   ```swift
   // In ActiveWorkoutSheetView.swift
   ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { exercise in
       CompactExerciseCard(...)
   }
   .onMove { indices, newOffset in
       Task {
           // Get exerciseId (NOT index!)
           let exerciseId = session.exercises[indices.first!].id
           await sessionStore.reorderExercise(
               exerciseId: exerciseId,
               newIndex: newOffset
           )
       }
   }
   
   // In CompactExerciseCard.swift
   ForEach(exercise.sets.sorted(by: { $0.orderIndex < $1.orderIndex })) { set in
       CompactSetRow(set: set)
   }
   .onMove { indices, newOffset in
       // Get setId (NOT index!)
       let setId = exercise.sets[indices.first!].id
       onReorderSet?(setId, newOffset)
   }
   ```

5. **Persistence**
   - Update SwiftData Entities mit orderIndex
   - Mapper aktualisieren
   - Repository speichert neue Reihenfolge

**Warum orderIndex statt Array-Position?**
- ✅ Explizit persistiert in Datenbank
- ✅ Unabhängig von Filter/Sort in UI
- ✅ Robust bei concurrency
- ✅ Ermöglicht Undo/Redo in Zukunft

**Testing:**
- User verschiebt Übung 3 nach Position 1
- App restart → Reihenfolge bleibt erhalten
- Set-Completion funktioniert weiterhin korrekt

**Dateien:**
- `/Domain/Entities/SessionExercise.swift` - Add orderIndex
- `/Domain/Entities/SessionSet.swift` - Add orderIndex
- `/Domain/UseCases/Session/ReorderExerciseUseCase.swift` - NEW
- `/Domain/UseCases/Session/ReorderSetUseCase.swift` - NEW
- `/Data/SwiftDataEntities.swift` - Update entities
- `/Data/Mappers/SessionMapper.swift` - Map orderIndex
- `/Presentation/Stores/SessionStore.swift` - Add reorder functions
- `/Presentation/Views/ActiveWorkout/ActiveWorkoutSheetView.swift` - Add .onMove
- `/Presentation/Views/ActiveWorkout/Components/CompactExerciseCard.swift` - Add .onMove

---

### 8. Statistics (Phase 3 aus TECHNICAL_CONCEPT_V2.md)
- Workout-Frequenz
- Volumen-Trends
- Personal Records (PRs)
- Charts (SwiftUI Charts)

### 9. Workout Builder (Phase 2 aus UX_CONCEPT_V2.md)
- Drag & Drop Exercises
- Template Management
- Folders

### 9. Profile & Settings
- User Profile
- Rest Timer Defaults
- Theme Settings

### 10. Testing
- Integration Tests (Store + Use Case)
- UI Tests (Critical Flows)
- Performance Tests

---

## 🐛 Bug-Fixes (Alle erledigt!)

- ✅ ~~"Keine Übungen" nach Set-Completion~~ (In-place updates)
- ✅ ~~Rest Timer startet nur einmal~~ (Timer nach jedem Set)

---

## 🔧 Technical Debt

### 1. Ordnerstruktur aufräumen (30 Min) 🟡 OPTIONAL
**Problem:** `GymBo/GymBo/GymBo/` verschachtelt  
**Lösung:** Flache Struktur (NACH MVP stabilisiert)  
**Risiko:** Xcode .pbxproj absolute Pfade könnten brechen

### 2. Logging verbessern (1 Stunde)
**Aktuell:** print() Statements  
**Besser:** Structured Logging mit AppLogger

```swift
AppLogger.session.info("Set completed", metadata: [
    "exerciseId": "\(exerciseId)",
    "setId": "\(setId)"
])
```

### 3. Error Handling verbessern
**Aktuell:** print() bei Fehlern  
**Besser:** User-facing Error Messages

```swift
@Published var errorMessage: String?

// In Store:
catch {
    errorMessage = error.localizedDescription
}

// In View:
.alert("Fehler", isPresented: $showError) {
    Text(sessionStore.errorMessage ?? "Unbekannter Fehler")
}
```

### 4. Preview Data auslagern
**Aktuell:** Preview Helper in Production Code  
**Besser:** Separate Preview Target

---

## 📋 Feature-Priorisierung (Empfehlung)

### Must-Have (MVP Launch)
1. ✅ Session Management ← **FERTIG**
2. ✅ Active Workout UI ← **FERTIG**
3. 🔴 Exercise Names ← **NÄCHSTES**
4. 🔴 Workout Repository ← **DANACH**
5. 🔴 Session History (simple Liste)

### Nice-to-Have (v2.1)
6. Statistics & Charts
7. Workout Builder
8. Exercise Database (erweitert)
9. Profile & Settings

### Future (v2.2+)
10. Cloud Sync
11. Social Features
12. AI Workout Generator
13. Video Tutorials

---

## 🎯 Nächste Session - Quick Win (2 Stunden)

**Ziel:** Exercise Names + Equipment anzeigen

**Checklist:**
- [ ] Add `exerciseName: String?` to SessionExercise
- [ ] Add `equipment: String?` to SessionExercise
- [ ] Update test data in StartSessionUseCase
- [ ] Update CompactExerciseCard to use names
- [ ] Build & Test
- [ ] Screenshot für Dokumentation

**Ergebnis:**
```
Statt: "Übung 1"
Jetzt: "Bankdrücken (Barbell)"
```

---

## 📊 Definition of Done

**Ein Feature ist "fertig" wenn:**
- ✅ Code kompiliert ohne Warnings
- ✅ Feature funktioniert im Simulator
- ✅ Grundlegende Tests vorhanden (Domain Layer)
- ✅ Code folgt Clean Architecture
- ✅ Keine hardcoded Magic Numbers
- ✅ Deutsche Lokalisierung
- ✅ Dokumentation aktualisiert (CURRENT_STATE.md)

---

## 📚 Referenzen

- `CURRENT_STATE.md` - Aktueller Implementierungsstatus
- `TECHNICAL_CONCEPT_V2.md` - Vollständige Architektur
- `UX_CONCEPT_V2.md` - UX/UI Konzept & User Flows
- `ACTIVE_WORKOUT_REDESIGN.md` - Design-Prozess (historisch)

---

**Letzte Aktualisierung:** 2025-10-22 22:40

---

## 🔮 Phase 2: Progression Features (Future)

**Status:** 📋 PLANNED - Fully documented, ready for implementation  
**Documentation:** See `PROGRESSION_FEATURE_PLAN.md` (detailed) or `PROGRESSION_QUICK_REF.md` (quick overview)  
**Estimated Time:** ~14 hours  
**Dependencies:** Workout Repository (Phase 1) must be complete first

### What's Ready

✅ **Complete feature specification**
- Linear Progression, Double Progression, Wave Loading strategies
- Data model extensions documented
- Clean Architecture implementation plan
- UI/UX mockups and flows

✅ **No breaking changes**
- All new fields are optional
- Backward compatible with Phase 1
- User can opt-in per workout

✅ **All raw data already captured**
- ExerciseEntity tracks lastUsed*
- ExerciseRecordEntity tracks PRs + 1RM
- UserProfileEntity has goals/experience
- WorkoutSessionEntity has complete history

### Quick Overview

**New Entities:**
- `ProgressionEventEntity` - Track all progression events (increases, deloads)

**Entity Extensions:**
- `WorkoutEntity`: Add `progressionStrategyRaw`, `defaultTargetReps*`
- `WorkoutExerciseEntity`: Add `progressionIncrement`, `autoProgressionDisabled`
- `WorkoutSessionEntity`: Add `perceivedDifficulty` (RPE)

**Use Cases:**
- `SuggestProgressionUseCase` - Analyze history, suggest next workout values
- `RecordProgressionEventUseCase` - Log progression events
- `GetProgressionHistoryUseCase` - Display progression timeline

**UI Components:**
- Progression suggestion banner (accept/decline)
- Progression settings in workout editor
- Progression timeline view

### When to Start Phase 2

**Start when:**
1. ✅ Workout Repository is complete and tested
2. ✅ User can select workouts from database
3. ✅ Sessions load real workout templates
4. ✅ App is stable with Phase 1 features

**Don't start if:**
- Workout Repository has bugs
- Session flow isn't working reliably
- Data model is still changing

---

## 📚 Documentation Index

- `CURRENT_STATE.md` - Current implementation status (Session 4)
- `TODO.md` - This file - Task prioritization
- `TECHNICAL_CONCEPT_V2.md` - Architecture details
- `UX_CONCEPT_V2.md` - UI/UX design
- `PROGRESSION_FEATURE_PLAN.md` - ⭐ NEW: Complete Phase 2 specification
- `PROGRESSION_QUICK_REF.md` - ⭐ NEW: Quick reference for Phase 2

---

---

**Last Updated:** 2025-10-24 (Abend) - HomeView Redesign Complete
