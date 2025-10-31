# Session Memory: Progressionsvorschläge Implementation

## 📋 Projektübersicht

**Feature**: Automatische Progressionsvorschläge für GymBo App  
**Branch**: `feature/progression-suggestions`  
**Start Datum**: 2025-10-31  
**Architektur**: V2 Clean Architecture mit SwiftData  
**Schema Version**: V6 → V7 (non-breaking)  
**Ziel**: MVP mit Linear Progression, keine Breaking Changes  

## 🎯 MVP Definition (Phase 1-4)

### ✅ Was funktioniert im MVP:
- Lineare Progressionsvorschläge (Weight + Reps)
- Card im ActiveWorkoutSheetView nach Exercise Completion  
- Manuelle Akzeptanz/Dismiss
- Persistent Storage der Vorschläge
- Confidence basiert auf erfolgreichen Sessions

### ❌ Was kommt später:
- Deload Detection
- Smart Progression mit ML
- Analytics & Insights  
- Erweiterte Settings

## 🏗️ Aktuelle Architektur (Snapshot)

### Schema Version
- **Aktuell**: V6 (Superset/Circuit Support)
- **Ziel**: V7 (+ ProgressionSuggestionEntity)
- **Migration**: Lightweight (nur neue Entity)

### Wichtigste Dateien
```
SwiftData Models:
- GymBo/SwiftDataEntities.swift (V6)
- GymBo/Data/Migration/SchemaV6.swift
- GymBo/Data/Migration/GymBoMigrationPlan.swift

Domain Layer:
- GymBo/Domain/Entities/WorkoutSession.swift
- GymBo/Domain/Entities/UserProfile.swift (ExperienceLevel, FitnessGoal existieren!)
- GymBo/Domain/UseCases/GetPersonalRecordsUseCase.swift

Presentation Layer:
- GymBo/Presentation/Views/ActiveWorkout/ActiveWorkoutSheetView.swift
- GymBo/Presentation/Stores/SessionStore.swift
```

### Bestehende Integration Points
- `ActiveWorkoutSheetView` → wo Card angezeigt wird
- `SessionStore` → manages current workout session
- `DomainUserProfile.experienceLevel` → für Progression Logic
- `DomainUserProfile.fitnessGoal` → für Progression Logic

## 📁 Dateistruktur (NEU)

### Domain Layer
```
GymBo/Domain/Entities/
├── ProgressionSuggestion.swift          # NEU
├── ExerciseHistory.swift                 # NEU (vereinfacht)
└── ProgressionPreferences.swift          # NEU (optional für MVP)

GymBo/Domain/Services/
└── ProgressionEngine.swift                # NEU (nur Linear für MVP)

GymBo/Domain/RepositoryProtocols/
└── ProgressionSuggestionRepositoryProtocol.swift  # NEU

GymBo/Domain/UseCases/
├── GenerateProgressionSuggestionUseCase.swift      # NEU
├── AcceptProgressionSuggestionUseCase.swift         # NEU
└── GetExerciseHistoryUseCase.swift                  # NEU
```

### Data Layer
```
GymBo/Data/Migration/
├── SchemaV7.swift                       # NEU
└── GymBoMigrationPlan.swift             # UPDATE

GymBo/Data/Repositories/
└── SwiftDataProgressionSuggestionRepository.swift  # NEU

GymBo/Data/Mappers/
└── ProgressionSuggestionMapper.swift     # NEU
```

### Presentation Layer
```
GymBo/Presentation/Views/ActiveWorkout/Components/
└── ProgressionSuggestionCard.swift       # NEU

GymBo/Presentation/Views/Settings/ (optional)
└── ProgressionSettingsView.swift         # NEU
```

## 🚀 Implementierungsphasen

### Phase 1: Data Model & Schema V7 (4-5h)
**Status**: ⏳ Nicht gestartet  
**Files**: 
- `SchemaV7.swift` 
- `GymBoMigrationPlan.swift` (update)
- `DomainProgressionSuggestion.swift`
- `ExerciseHistory.swift`

**Checkpoint**: Schema kompiliert, migration test erfolgreich

### Phase 2: Progression Engine (3-4h)  
**Status**: ⏳ Nicht gestartet  
**Files**:
- `ProgressionEngine.swift` (nur Linear für MVP)
- Unit Tests für Progression Logic

**Checkpoint**: Progression Logic funktioniert mit Testdaten

### Phase 3: Use Cases & Repositories (3-4h)
**Status**: ⏳ Nicht gestartet  
**Files**:
- Alle Use Cases
- Repository Implementation
- Mapper

**Checkpoint**: End-to-End von Session History → Progression Vorschlag

### Phase 4: UI Integration (4-5h)
**Status**: ⏳ Nicht gestartet  
**Files**:
- `ProgressionSuggestionCard.swift`
- `ActiveWorkoutSheetView.swift` (minimal changes)
- `SessionStore.swift` (neue methods)

**Checkpoint**: Card erscheint nach Exercise Completion

### Phase 5: Settings (optional, 2-3h)
**Status**: ⏳ Nicht gestartet  
**Files**:
- `ProgressionPreferences.swift`
- `ProgressionSettingsView.swift`

## 🔧 Technical Decisions (Fixed)

### Data Model
- **ProgressionSuggestionEntity**: Alle Felder optional mit defaults
- **KEINE Änderungen** an bestehenden Entities (non-breaking)
- **Schema V7**: Nur neue Entity hinzufügen

### Progression Logic (MVP)
```swift
// EINFACHE Regeln für Linear Progression:
if successfulSessionsCount >= 3 {
    if goal == .muscleGain {
        return weightSuggestion()  // +2.5kg
    } else {
        return repsSuggestion()   // +1-2 reps
    }
}
```

### UI Integration
- **Timing**: Vorschlag NACH Exercise Completion (nicht vorher)
- **Persistenz**: NICHT automatisch im Template speichern
- **Frequency**: Max. 1x pro Übung pro Session

### Performance
- **Lazy Loading**: Nur bei Bedarf berechnen
- **Caching**: ExerciseHistory in SessionStore (optional für MVP)
- **Background**: Keine Blocking Operations in UI

## 🎲 Risk Assessment

### ⚠️ Medium Risk
- Schema V7 Migration (test intensiv)
- UI Integration in ActiveWorkoutSheetView (complex view)

### ✅ Low Risk  
- Domain Entities (reine structs)
- Progression Logic (isoliert testbar)
- Use Cases (klar definierte contracts)

## 🧪 Test Strategy

### Unit Tests
```swift
ProgressionEngineTests.swift
- testLinearWeightProgression()
- testLinearRepsProgression() 
- testConfidenceCalculation()

GenerateProgressionSuggestionUseCaseTests.swift
- testWithNoHistory()
- testWithSuccessfulSessions()
- testWithFailedSessions()
```

### Integration Tests
```swift
ProgressionIntegrationTests.swift
- testEndToEndExerciseCompletion()
- testSuggestionAcceptance()
- testSuggestionDismissal()
```

### UI Tests
```swift
ProgressionUITests.swift
- testProgressionCardAppearance()
- testProgressionCardInteraction()
```

## 📝 Working Rules

### Code Style
- **Follow existing patterns**: Look at similar files
- **Use full type annotations**: No type inference in critical paths
- **Document everything**: Headers, inline comments, WHY not WHAT
- **Error handling**: Never crash, always graceful degradation

### Git Workflow
```bash
# Commit pattern:
git commit -m "feat: add progression suggestion data models"
git commit -m "fix: resolve schema migration issue"
git commit -m "test: add progression engine unit tests"
```

### Validation Rules
- **Build succeeds**: Keine compilation errors
- **Tests pass**: Alle Unit + Integration Tests green
- **Migration tested**: Alte Daten bleiben intakt
- **UI responsive**: Kein blocking in main thread

## 🔍 Debugging Checklist

### Wenn etwas nicht funktioniert:
1. **Check Schema**: Ist V7 korrekt migriert?
2. **Check Domain Entities**: Sind alle required fields gefüllt?
3. **Check Use Cases**: Werden Repositories korrekt aufgerufen?
4. **Check UI**: Werden @State Variables korrekt updated?
5. **Check Performance**: Blocking operations identifizieren?

### Logging Strategy
```swift
// Consistent logging pattern:
print("✅ ProgressionSuggestion saved: \(suggestion.id)")
print("⚠️ No exercise history available for \(exerciseId)")
print("🔄 Calculating progression for exercise: \(exerciseName)")
```

## 📞 How to Resume

### When context window is full:
1. **Read SESSION_MEMORY.md** (this file)
2. **Check last completed phase** (status section)
3. **Look at current git state** (`git log --oneline -10`)
4. **Run tests** to ensure current state is stable
5. **Continue from next phase**

### Quick Commands:
```bash
# Check current state
git status
git log --oneline -10

# Run tests  
xcodebuild test -scheme GymBo

# Check migration
# (Debug migration in simulator)
```

## 📊 Progress Tracking

### Completed Tasks
- [x] Feature branch created
- [x] Session memory document created
- [ ] Phase 1: Data Model & Schema V7
- [ ] Phase 2: Progression Engine  
- [ ] Phase 3: Use Cases & Repositories
- [ ] Phase 4: UI Integration
- [ ] Phase 5: Settings (optional)

### Open Questions
- UI Design final approvement?
- Migration testing strategy?
- Performance requirements?

---

**Last Updated**: 2025-10-31  
**Next Action**: Start Phase 1 - Create SchemaV7 and Domain Entities  
**Estimated Time Remaining**: 16-21 Stunden  
**Risk Level**: Medium (manageable)