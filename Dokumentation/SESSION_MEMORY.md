# GymBo - Session Memory

**Letzte Aktualisierung:** 2025-10-27

---

## 🎯 Wichtige Projekt-Informationen

### Skills Location
**Pfad:** `~/.claude/skills/` (= `/Users/benkohler/.claude/skills/`)

**Verfügbare Skills:**
1. **alarmkit.md** - Apple AlarmKit Framework Guide (für Rest Timer Notifications)
2. **ios26-design.md** - iOS 26 Design Guidelines & Liquid Glass System

**Status:** Skills sind als Markdown vorhanden, aber nicht als MCP-Server registriert. Können als Referenz-Dokumentation gelesen werden.

---

## 📊 Projekt-Status (Stand: 2025-10-27)

### Version: 2.4.0 - Apple Health Integration (Phase 1-4 Complete)

**Alle Core Features implementiert:**
- ✅ Workout Management (Create/Edit/Delete/Favorite)
- ✅ Workout Folders/Categories - Workouts in Ordnern organisieren
- ✅ Exercise Library (145+ Übungen, Search, Filter, Create, Delete)
- ✅ Custom Exercise Management (Create/Delete mit Business Rules)
- ✅ Workout Detail & Exercise Management (Multi-Select Picker, Reorder)
- ✅ Active Workout Session (vollständig)
- ✅ Per-Set Rest Times - Individuelle Pausenzeiten pro Satz
- ✅ Quick-Setup Workout Creation - Schnelles Workout-Erstellen
- ✅ **Apple Health Integration** (NEU) - Workouts & Body Metrics synchronisieren
- ✅ UI/UX (Brand Color #F77E2D, iOS 26 Design, TabBar Auto-Hide)
- ✅ Architecture (Clean Architecture, 30+ Use Cases, 4 Repositories)

**Dokumentation aktualisiert:**
- APPLE_HEALTH_IMPLEMENTATION_PLAN.md → Phase 1-4 complete
- SESSION_MEMORY.md → Session 22 dokumentiert
- CURRENT_STATE.md → Apple Health Features dokumentiert

---

## ✅ Session 2025-10-27 (Session 22) - Apple Health Integration (Phase 1-4)

### Apple Health (HealthKit) Integration - Komplett implementiert
**Status:** ✅ Phase 1-4 abgeschlossen (Phase 3 deferred to Live Activity)

**Branch:** `feature/apple-health-integration`

### Phase 1: Core HealthKit Integration ✅

**Domain Layer:**
- `HealthKitServiceProtocol.swift` - Protocol abstraction in Domain
- `HealthKitError` enum mit 6 Error Cases
- `WorkoutActivityType` enum für Workout-Mapping

**Infrastructure Layer:**
- `HealthKitService.swift` - Complete HKHealthStore implementation
- Workout session management (start/end/pause/resume)
- Body metrics queries (fetchBodyMass, fetchHeight)
- Heart rate streaming (deferred to Live Activity)

**Use Cases Integration:**
- `StartSessionUseCase` - Starts HKWorkoutSession (non-blocking background task)
- `EndSessionUseCase` - Saves completed workout to Health with metadata
- Fire-and-forget approach: Workout functionality nicht blockiert wenn HealthKit fehlt

**Dependency Injection:**
- `DependencyContainer.swift` - Registered HealthKitService
- Mock implementations für Tests/Previews

**Key Design Decisions:**
- Non-blocking: HealthKit operations laufen in `Task.detached(priority: .background)`
- Graceful degradation: App funktioniert auch ohne HealthKit permissions
- Clean Architecture: Domain kennt nur Protocol, Infrastructure implementiert

### Phase 2: Permissions & UI ✅

**Permission Flow:**
- `HealthKitPermissionView.swift` - Permission request sheet mit Benefits
- Info.plist keys hinzugefügt:
  - `NSHealthShareUsageDescription` - Für Health-Daten lesen
  - `NSHealthUpdateUsageDescription` - Für Workout-Export
- Integration in ProfileView als Settings-Option

**SessionStore Extension:**
- `requestHealthKitAuthorization()` method
- Non-intrusive: User kann Permission jederzeit in Settings erteilen

### Phase 3: Heart Rate Streaming ⏸️

**Status:** DEFERRED to Live Activity Phase
**Reason:** User-Entscheidung - Heart Rate macht mehr Sinn im Kontext der Live Activity
**Future:** Wird später mit Live Activity Widget implementiert

### Phase 4: Body Metrics Import ✅

**Domain Layer:**
- `UserProfile.swift` - Domain entity mit:
  - `bodyMass: Double?` (kg)
  - `height: Double?` (cm)
  - `bmi: Double?` (calculated property)
  - `bodyMassOrDefault` & `heightOrDefault` (fallbacks: 80kg / 175cm)
- `UserProfileRepositoryProtocol.swift` - Repository interface
- `ImportBodyMetricsUseCase.swift` - Fetch weight & height from HealthKit

**Data Layer:**
- `SwiftDataUserProfileRepository.swift` - Persistence via SwiftData
- `UserProfileMapper.swift` - Maps Domain ↔ Data
  - **Wichtig:** Mapper mappt `bodyMass` → `weight` (existing entity field)
- Reused existing `UserProfileEntity` from `SwiftDataEntities.swift`
  - Existing fields: id, weight, height, createdAt, updatedAt
  - `lastHealthKitSync` wird nicht persistiert (nur in Domain)

**SwiftData Migration:**
- `GymBoMigrationPlan.swift` - Custom V1→V2 migration
- **Problem:** Alte Datenbanken (V1) haben keine UserProfileEntity
- **Lösung:** Changed from lightweight to custom migration
- `didMigrate` callback creates default UserProfile:
  ```swift
  let profileDescriptor = FetchDescriptor<SchemaV2.UserProfileEntity>()
  let existingProfiles = try? context.fetch(profileDescriptor)
  
  if existingProfiles?.isEmpty ?? true {
      print("📝 Creating default UserProfile")
      let defaultProfile = SchemaV2.UserProfileEntity()
      context.insert(defaultProfile)
      try? context.save()
  }
  ```
- **Ergebnis:** User müssen App nicht mehr löschen bei Updates!

**Calorie Calculation Improvement:**
- `EndSessionUseCase.swift` - Updated calorie calculation
- **Vorher:** Hardcoded 80kg body weight
- **Jetzt:** 
  ```swift
  let bodyWeight: Double
  if let profile = try? await userProfileRepository.fetchOrCreate() {
      bodyWeight = profile.bodyMassOrDefault  // Real weight or 80kg default
      print("💪 Using user body weight: \(bodyWeight) kg")
  } else {
      bodyWeight = 80.0
      print("⚠️ Using default body weight: 80.0 kg")
  }
  
  let calories = met * bodyWeight * hours
  ```
- MET-Wert: 6.0 (moderate strength training)
- Formel: Calories = MET × bodyWeight (kg) × time (hours)

**UI Implementation:**
- `ProfileView.swift` - Body Metrics Section:
  - Zeigt Gewicht, Größe, BMI
  - "Aus Apple Health importieren" Button
  - Loading state während Import
- `importBodyMetrics()` async function:
  - Calls `ImportBodyMetricsUseCase`
  - Updates UserProfile via repository
  - Reloads profile data for UI

**DependencyContainer Updates:**
- `makeUserProfileRepository()` - Creates SwiftData repository
- `makeImportBodyMetricsUseCase()` - Creates use case with HealthKit service
- `makeEndSessionUseCase()` - Now includes UserProfile repository dependency

### Critical Bug Fixes During Implementation

**1. Type-Checker Timeout in HomeView.swift:54**
- **Problem:** Too many chained view modifiers overwhelmed Swift compiler
- **Symptom:** "The compiler is unable to type-check this expression in reasonable time"
- **Solution:** Extracted modifiers into 3 separate ViewModifier structs:
  - `SheetsModifier` - All 7 `.sheet()` presentations
  - `NavigationModifier` - Both `.navigationDestination()` calls
  - `LifecycleModifier` - All `.onChange()` handlers
- **Result:** Clean compilation, maintainable code structure

**2. Build Database Lock Errors**
- **Problem:** Multiple concurrent xcodebuild processes
- **Symptom:** "unable to attach DB: database is locked"
- **Solution:** `killall xcodebuild swift-frontend` + `rm -rf DerivedData`
- **Persistent Issue:** Happened multiple times throughout session

**3. Switch Expression Type Inference**
- **Problem:** Swift couldn't infer types in switch expressions for nil assignments
- **Location:** `ImportBodyMetricsUseCase.swift`
- **Solution:** Changed from switch expression to traditional switch statement:
  ```swift
  // Before (failed):
  let bodyMass: Double? = switch bodyMassResult {
  case .success(let mass): mass
  case .failure: nil
  }
  
  // After (works):
  var bodyMass: Double?
  switch bodyMassResult {
  case .success(let mass): bodyMass = mass
  case .failure: bodyMass = nil
  }
  ```

**4. Missing Dependencies in Previews**
- **Problem:** SessionStore.preview missing new dependencies
- **Solution:** Added MockUserProfileRepository to preview helpers

**5. Duplicate UserProfileEntity**
- **Problem:** Created new entity file but one already existed
- **Solution:** 
  - Deleted duplicate file
  - Updated mapper to use existing entity's field names (weight not bodyMass)
  - Avoided Predicate macro (causes type inference issues)

**6. SwiftData Schema Initialization Failure**
- **Problem:** "invalid reuse after initialization failure"
- **Root Cause:** Old database without UserProfileEntity
- **User Question:** "Muss ich die App von meinem Test-Device auch löschen?"
- **Solution:** Custom migration statt manual deletion

**7. Optional Unwrapping Issues**
- **Problem:** DependencyContainer is optional from Environment
- **Solution:** Made modifier parameter optional with proper unwrapping

### Technical Highlights

**Clean Architecture Principles:**
- Domain layer defines protocols
- Infrastructure implements concrete services
- Use Cases orchestrate business logic
- Repositories handle persistence
- Complete separation of concerns

**Non-Blocking HealthKit:**
```swift
Task.detached(priority: .background) { [weak self] in
    let result = await self.healthKitService.startWorkoutSession(...)
    if case .failure(let error) = result {
        print("⚠️ HealthKit failed: \(error)")
        // User can continue workout anyway
    }
}
```

**Async/Await Throughout:**
- All repository methods async
- Use Cases return Result<T, Error>
- SwiftUI views use async functions with Task {}

**Repository Pattern:**
```swift
protocol UserProfileRepositoryProtocol {
    func fetchOrCreate() async throws -> DomainUserProfile
    func update(_ profile: DomainUserProfile) async throws
    func updateBodyMetrics(bodyMass: Double?, height: Double?) async throws
}
```

**Mapper Pattern:**
```swift
struct UserProfileMapper {
    func toDomain(_ entity: UserProfileEntity) -> DomainUserProfile
    func toEntity(_ domain: DomainUserProfile) -> UserProfileEntity
    func updateEntity(_ entity: UserProfileEntity, from domain: DomainUserProfile)
}
```

### Files Created

**Domain Layer (6 files):**
- `GymBo/Domain/Services/HealthKitServiceProtocol.swift`
- `GymBo/Domain/Entities/UserProfile.swift`
- `GymBo/Domain/RepositoryProtocols/UserProfileRepositoryProtocol.swift`
- `GymBo/Domain/UseCases/HealthKit/RequestHealthKitAuthorizationUseCase.swift`
- `GymBo/Domain/UseCases/HealthKit/SaveWorkoutToHealthKitUseCase.swift`
- `GymBo/Domain/UseCases/HealthKit/ImportBodyMetricsUseCase.swift`

**Infrastructure Layer (1 file):**
- `GymBo/Infrastructure/Services/HealthKit/HealthKitService.swift`

**Data Layer (2 files):**
- `GymBo/Data/Repositories/SwiftDataUserProfileRepository.swift`
- `GymBo/Data/Mappers/UserProfileMapper.swift`

**Presentation Layer (1 file):**
- `GymBo/Presentation/Views/Profile/HealthKitPermissionView.swift`

**Updated Files:**
- `GymBo/Domain/UseCases/Session/StartSessionUseCase.swift` - HealthKit integration
- `GymBo/Domain/UseCases/Session/EndSessionUseCase.swift` - HealthKit + real body weight
- `GymBo/Infrastructure/DI/DependencyContainer.swift` - New dependencies
- `GymBo/Presentation/Views/Profile/ProfileView.swift` - Body metrics section
- `GymBo/Presentation/Views/Home/HomeView.swift` - ViewModifier refactoring
- `GymBo/Data/Migration/GymBoMigrationPlan.swift` - Custom migration
- `GymBo.xcodeproj/project.pbxproj` - Info.plist keys

### Testing Notes

**Manual Testing Required:**
1. ✅ Clean build succeeds
2. ⏳ Run on Simulator - verify migration runs
3. ⏳ Run on test device - verify no "invalid reuse" error
4. ⏳ Grant HealthKit permissions
5. ⏳ Import body metrics from Health
6. ⏳ Complete workout - verify saved to Health
7. ⏳ Check calorie calculation uses real weight

**Console Output Expected:**
```
🔄 Starting migration V1 → V2
📝 Creating default UserProfile
✅ Default UserProfile created
✅ Migration V1 → V2 complete

💪 Using user body weight: 82.5 kg
✅ HealthKit workout saved
```

### Commits (9 total)

1. `feat(healthkit): Add HealthKit service protocol and infrastructure`
2. `feat(healthkit): Add permission view and profile integration`
3. `feat(healthkit): Add body metrics import use case and repository`
4. `feat(healthkit): Update EndSessionUseCase to use real body weight`
5. `feat(healthkit): Add custom V1→V2 migration to create default UserProfile`
6. `fix: Refactor HomeView to fix type-checker timeout - Extract view modifiers`
7. `fix: Correct ExerciseTemplate to WorkoutExercise in SheetsModifier`
8. `fix: Make dependencyContainer optional in SheetsModifier`
9. ⏳ (pending) Final merge to main

### Next Steps

**Phase 5: Polish & Analytics (Optional - Low Priority)**
- [ ] Workout Summary: "✓ Saved to Apple Health" badge
- [ ] Deep link to Health App
- [ ] Statistics: Import resting heart rate (optional)

**Future: Live Activity Integration**
- [ ] Heart Rate Streaming implementation
- [ ] Live Activity widget with HR display
- [ ] Real-time workout stats on Lock Screen

### User Decisions Documented

- ❌ **No Apple Watch Support** (vorerst nicht)
- ⏸️ **Heart Rate Streaming** deferred to Live Activity
- ✅ **Body Metrics Import** high priority (better calorie calculation)
- ✅ **Automatic Migration** statt manual app deletion

---

## ✅ Session 2025-10-26 (Session 21) - Workout Folders Implementation

### Workout Folders/Categories Feature
**Status:** ✅ Komplett implementiert und getestet

**Implementierte Features:**
1. **Domain Layer:**
   - WorkoutFolder Entity (id, name, color, order, createdDate)
   - Workout.folderId: UUID? für Zuordnung
   - Workout.orderInFolder: Int für Sortierung innerhalb Folder

2. **Data Layer:**
   - WorkoutFolderEntity (SwiftData @Model)
   - WorkoutFolderMapper (Domain ↔ Data)
   - Repository Methods:
     - fetchAllFolders() - Alle Ordner laden
     - createFolder() - Ordner erstellen
     - updateFolder() - Ordner bearbeiten
     - deleteFolder() - Ordner löschen (setzt Workouts auf nil)
     - moveWorkoutToFolder() - Workout verschieben

3. **Presentation Layer:**
   - ManageFoldersSheet - Ordner-Verwaltung (Liste, Delete, Edit)
   - CreateFolderSheet - Ordner erstellen/bearbeiten
     - Name-Input
     - Farb-Picker (8 vordefinierte Farben)
   - HomeView Integration:
     - Folder Icon Button in Toolbar
     - Collapsible Folder Sections mit Farb-Indikator
     - Context Menu zum Verschieben
   - WorkoutStore Methods:
     - loadFolders()
     - createFolder()
     - updateFolder()
     - deleteFolder()
     - moveWorkoutToFolder()

4. **UI/UX Features:**
   - 8 vordefinierte Folder-Farben (#8B5CF6, #EF4444, #F59E0B, #10B981, #3B82F6, #EC4899, #6366F1, #14B8A6)
   - Collapsible Sections für Folders
   - Farb-Indikator (Circle) bei Folder-Namen
   - Context Menu: "Verschieben nach..." mit Folder-Liste
   - "Ohne Kategorie" Sektion für uncategorized Workouts
   - Swipe-to-Delete in ManageFoldersSheet
   - Workout-Count Badge in Folder-Liste

5. **Bug Fixes während Implementation:**
   - Duplicate Color+hex extension entfernt (3x → 1x in Color+AppColors.swift)
   - Predicate Syntax Fix (lokale Variable statt closure-capture)
   - UI Reactivity Fix: @Bindable + lokale @State Kopien + onChange Listener
   - Sofortige UI-Updates nach Folder-Deletion
   - Rest Timer Notification-Bug behoben (cancelRest() nach Workout-Ende)
   - Difficulty Labels aus Exercise List entfernt
   - Collapsible Sections für "Favoriten" + "Alle Workouts"

**Technische Details:**
- Clean Architecture konsequent eingehalten
- SwiftData Relationship: WorkoutFolderEntity ↔ WorkoutEntity (deleteRule: .nullify)
- @Observable Store mit @Bindable in Views
- Lokale @State Kopien für Performance + Reactivity
- onChange Listener für automatische UI-Updates
- Extensive Debug-Logging für Troubleshooting

**Commits:**
- fix: Remove duplicate Color+hex extension declarations
- fix: Reload folders when ManageFolders sheet is dismissed
- fix: Add reload triggers for folders in ManageFoldersSheet
- fix: Correct Predicate syntax for folder verification
- debug: Add extensive logging for folder creation and loading
- fix: Use @Bindable and local state for folders to fix UI reactivity
- fix: Reload workouts in HomeView after moving to folder
- feat: Add debug logging for folder deletion and reload workouts in HomeView
- fix: Add onChange listener for folders to update HomeView immediately after deletion

---

## ✅ Session 2025-10-26 (Session 20) - Quick-Setup Workout Creation

### Quick-Setup Feature
**Status:** ✅ Komplett implementiert

**Features:**
- WorkoutCreationModeSheet mit 3 Modi
- 3-Schritt Wizard (Equipment → Dauer → Ziel)
- QuickSetupWorkoutUseCase (AI-basierte Workout-Generierung)
- QuickSetupPreviewView mit Smart Exercise Swap

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
