# GymBo V2 - TODO Liste

**Stand:** 2025-10-29
**Current Phase:** ✅ MVP COMPLETE - All Core Features Implemented (v2.3.0)
**Next Phase:** Nice-to-Have Features & Polish
**Letzte Änderungen:** Session 26 - Feature Flags System Complete

---

## 📋 AKTUELLE TO-DOs (Kanban)

> **Hinweis:** Neue To-dos einfach hier oben in die entsprechende Kategorie einfügen!

### 🔴 High Priority

- [ ] **Übungen tauschen bei aktivem Workout** - Lange auf Übung drücken → Alternative vorschlagen
- [x] ~~Feature Flags~~ - Implementiert (Session 26)
- [ ] **Live Activities** - Lock Screen Integration für aktive Sessions

### 🟡 Medium Priority

- [ ] **Progression** - Automatische Gewichtssteigerung & Progression Tracking
- [ ] **Widgets** - iOS Home Screen Widgets für schnellen Zugriff
- [ ] **Workout Import** - Workouts von anderen Plattformen importieren
- [ ] **Aufwärmsätze** - Warmup sets für bessere Trainingsstruktur

### 🟢 Low Priority / Nice-to-Have

- [ ] **Dynamic Island** - Live Activities während aktivem Workout

---

## ✅ MVP COMPLETE - Alle Core Features Implementiert!

### Was ist FERTIG (Production Ready):

**1. Workout Management** ✅
- Create/Edit/Delete Workouts
- Toggle Favorite
- **Workout Folders/Categories** (organize in colored folders)
- Move workouts between folders
- Folder reordering (drag & drop)
- Quick-Setup Workout Creation (wizard)
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
- Start/End/Cancel/Pause/Resume Session
- Complete/Uncomplete Sets
- Add/Remove Sets
- Update Set Weight/Reps
- Update All Sets
- **Per-Set Rest Times** (individual rest for each set)
- Exercise Notes
- Auto-Finish Exercise
- Reorder Exercises (session-only oder permanent)
- Rest Timer with UserNotifications (background support)
- Rest Timer cancellation on workout end/cancel
- Show/Hide completed
- Exercise Counter
- Session Persistence & Restoration

**5. UI/UX** ✅
- Modern Dark Theme
- **Brand Color #F77E2D** (custom GymBo orange)
- 39pt Corner Radius
- Inverted Checkboxes
- Haptic Feedback
- Success Pills
- Profile Button (HomeView)
- iOS 26 Modern Card Design
- Collapsible Sections (Favoriten, Folders, Ohne Kategorie)
- HomeView Redesign (Greeting, Locker Number, Workout Calendar)
- Difficulty badges (grayscale) removed from Exercise List
- **Configurable Weekly Workout Goal** (Profile Settings with 1-7 range)

**6. Architecture** ✅
- Clean Architecture (4 Layers)
- **25 Use Cases** (12 Session + 11 Workout + 2 Exercise)
- **3 Repositories** (Workout with folder support, Session, Exercise)
- **11 SwiftData Entities** + **7 Domain Entities**
- 2 Stores @Observable (SessionStore, WorkoutStore)
- DI Container
- SwiftData Migration Plan (V1 → V2)
- @Bindable + local @State for UI reactivity

**7. Code Quality** ✅
- Debug logging removed (72 lines cleaned)
- Legacy code removed (Item.swift)
- Proper file naming (HomeViewPlaceholder → HomeView)

---

## 🚀 GEPLANTE FEATURES (Priorisiert)

### 1. Exercise Swap Feature (Medium Effort - 4-6 Std)
**Status:** 🔴 High Priority (Kanban)
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

### 2. Feature Flags System (Low Effort - 2-3 Std)
**Status:** ✅ DONE (Session 26)
**Ziel:** System für experimentelle Features

**Features:**
- Remote config integration (optional)
- Local feature toggles
- Developer menu für Testing
- A/B Testing Unterstützung

**Implementiert:**
- Infrastruktur: `/Infrastructure/FeatureFlags/FeatureFlagService.swift` (Enum, Protocol, Service)
- DI: `DependencyContainer.makeFeatureFlagService()` (Singleton)
- AppStart: `GymBoApp` injiziert `FeatureFlagService` in `AppSettings`
- AppSettings: Flag-States laden/setzen, persistente Defaults
- Profile (DEBUG): Developer‑Section mit Toggles

---

### 3. Aufwärmsätze (Medium Effort - 4-5 Std)
**Status:** 🔴 High Priority (Kanban)
**Ziel:** Warmup sets vor Arbeitssätzen

**Features:**
- Warmup set marking
- Auto-berechnung von Warmup-Gewichten (% von Arbeitsgewicht)
- Separate Statistiken (warmup vs. working sets)
- Optional: Warmup templates

**Dateien:**
- Update `SessionSet` Entity mit `isWarmup: Bool`
- Update UI in `CompactSetRow`
- Update Use Cases für Set-Creation

---

### 4. Progression System (High Effort - 8-10 Std)
**Status:** 🟡 Medium Priority (Kanban)
**Ziel:** Automatische Gewichtssteigerung & Progression Tracking

**Features:**
- Linear Progression
- Double Progression
- Wave Loading
- Progression suggestions
- History tracking

**Referenz:** Siehe `PROGRESSION_FEATURE_PLAN.md`

---

### 5. iOS Widgets (Medium Effort - 5-6 Std)
**Status:** 🟡 Medium Priority (Kanban)
**Ziel:** Home Screen Widgets für schnellen Zugriff

**Widget Types:**
- Small: Nächstes Workout
- Medium: Workout Stats (Streak, Last Session)
- Large: Weekly Overview + Quick Start

**Dateien:**
- `/Widgets/GymBoWidgets.swift` - NEW
- `/Widgets/Views/` - Widget Views
- Widget Extension Target

---

### 6. Workout Import (Medium Effort - 4-5 Std)
**Status:** 🟡 Medium Priority (Kanban)
**Ziel:** Workouts von anderen Plattformen importieren

**Supported Formats:**
- JSON (custom format)
- CSV (simple format)
- JEFIT (popular app)
- Strong (popular app)

**Dateien:**
- `/Domain/UseCases/Import/ImportWorkoutUseCase.swift` - NEW
- `/Infrastructure/Import/WorkoutImporter.swift` - NEW
- UI in WorkoutList (Import Button)

---

### 7. Dynamic Island (Low Effort - 2-3 Std)
**Status:** 🟢 Low Priority (Kanban)
**Ziel:** Live Activities während aktivem Workout

**Features:**
- Current exercise name
- Set counter
- Rest timer countdown
- Quick actions (complete set, skip rest)

**Requirements:**
- iOS 16.1+
- iPhone 14 Pro+

**Dateien:**
- `/Widgets/LiveActivities/WorkoutLiveActivity.swift` - NEW
- Update `SessionStore` mit Live Activity Start/Stop

---

### 8. Live Activities (Medium Effort - 3-4 Std)
**Status:** 🟢 Low Priority (Kanban)
**Ziel:** Lock Screen Integration für aktive Sessions

**Features:**
- Lock screen widget during workout
- Compact view (minimal info)
- Expanded view (current set details)
- Quick actions

**Dateien:**
- Same as Dynamic Island
- Shared implementation

---

### 9. Rework Calendar Strip (Low Effort - 2-3 Std)
**Status:** 🟢 Low Priority (Kanban)
**Ziel:** Verbessertes Design & Interaktivität

**Improvements:**
- Tap on day → Show workout details
- Swipe gestures für Navigation
- Improved streak visualization
- Monthly view option

**Dateien:**
- Update `/Presentation/Views/Home/Components/WorkoutCalendarStripView.swift`
- Optional: New Sheet für Day Details

---

### 10. Profile Page (Low Effort - 2-3 Std)
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

### 11. Session History (2-3 Stunden)
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

### 12. Localization Support (3-4 Stunden)
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

## 📊 Langfristig (Phase 2+)

### Statistics & Charts (Phase 3)
- Workout-Frequenz (Heatmap Calendar)
- Volumen-Trends (Line Charts)
- Personal Records (PRs)
- Progress per Exercise
- SwiftUI Charts Framework

### Advanced Workout Builder
- Templates & Folders
- Superset Support
- Drop Sets, Pyramid Sets
- Custom Rest Timer per Exercise

### Cloud Sync & Social
- iCloud Sync
- Share Workouts
- Social Feed (optional)

### AI Features (Phase 4)
- Workout Generator (AI-basiert)
- Form Check (Video Analysis)
- Smart Progression Suggestions

---

## ✅ ABGESCHLOSSEN

### Session 26 (2025-10-29) - Feature Flags System
- ✅ **Feature Flags Infrastruktur & Integration**
  - `FeatureFlag` Enum + `FeatureFlagServiceProtocol` + `FeatureFlagService` (UserDefaults)
  - DI: `DependencyContainer` stellt Singleton bereit
  - `GymBoApp`: injiziert Service in `AppSettings`
  - `AppSettings`: `isFeatureEnabled`, `setFeature`, persistente Defaults
  - `ProfileView` (DEBUG): Developer‑Section mit Flag‑Toggles
- Defaults: Alle Flags initial auf false (Swap/Widgets/Live Activities/Dynamic Island)

### Session 25 (2025-10-27) - ProfileView Complete Implementation & Theme Switching Fix
- ✅ **Complete ProfileView Implementation**
  - Schema Migration V2 → V3: Expanded UserProfileEntity with full profile data
  - Personal Information: Name, Age (stepper), Experience Level, Fitness Goal
  - Profile Image: Camera/Photo Library with permissions (NSCameraUsageDescription)
  - Settings: Apple Health toggle (removed dummy Read/Write toggles)
  - App Theme: System/Hell/Dunkel picker with reactive updates
  - Notifications: Deep link to iOS Settings, Live Activity (disabled - future)
  - HealthKit Import: Age, Weight, Height from Apple Health
- ✅ **Theme Switching Reactivity Fix**
  - Changed `appSettings` from `private let` to `@State` in GymBoApp
  - ProfileView uses `@Bindable` for reactive theme updates
  - AppSettings.currentTheme property tracks selected theme
  - ProfileView displays correct theme value immediately on change
- ✅ **HealthKit Toggle Simplification**
  - Removed dummy Read/Write toggles (iOS manages permissions)
  - Single "Apple Health aktivieren" toggle with real functionality
  - Cleaned up across all layers (Domain, Data, Presentation)
- ✅ **Architecture Improvements**
  - Clean separation: Domain → Use Cases → Data → Presentation
  - Proper @Observable usage with @Bindable in views
  - ImagePicker UIViewControllerRepresentable with compression
  - Separate sheets for camera/gallery selection (confirmationDialog)
- Commits: Multiple (ProfileView implementation, theme fix, toggle cleanup)

### Session 24 (2025-10-27) - Weekly Workout Goal Feature + Profile UI/UX Polish
- ✅ **Wöchentliches Workout-Ziel Feature**
  - UserProfileEntity: weeklyWorkoutGoal Feld hinzugefügt (Default: 3)
  - DomainUserProfile: weeklyWorkoutGoal Property hinzugefügt
  - UserProfileMapper: Mapping für weeklyWorkoutGoal implementiert
  - Repository: updateWeeklyWorkoutGoal() mit Validierung (1-7)
  - ProfileView: Neue "Trainingsziele" Section mit Stepper
  - WorkoutCalendarStripView: Dynamisches Ziel statt hardcoded "3"
- ✅ **Instant Updates via NotificationCenter**
  - Notification.Name.userProfileDidChange implementiert
  - ProfileView postet Notification bei Änderung
  - WorkoutCalendarStripView empfängt und refresht sofort
  - Keine Tab-Switches mehr nötig - updates instant!
- ✅ **Profile UI/UX Konsistenz**
  - Alle statischen Icons → dunkelgrau (.secondary)
  - "Profil wird ausgebaut" Icon: sparkles → person.text.rectangle
  - Import Button: tint(.secondary) statt orange
  - Keine bunten Icons mehr (außer Status-Indikatoren)
- ✅ Compilation fixes (Color.appOrange, Mock Repositories)
- Commits: `18c8c56`, `e86cf7a`, `4f5ed52`, `04e4091`, `7c4777b`, `a2a5cbd`

### Session 22 (2025-10-27) - Code Cleanup & Refactoring
- ✅ Debug logging entfernt (72 lines, 4 files)
- ✅ Folder reordering implementiert (drag & drop in ManageFoldersSheet)
- ✅ Legacy code entfernt (Item.swift)
- ✅ HomeViewPlaceholder → HomeView umbenannt
- ✅ All references updated (MainTabView.swift)
- Commits: `064d70e`, `6fca564`

### Sessions 19-21 (2025-10-26) - Workout Folders & Quick-Setup

**Session 19 - Brand Color & Per-Set Rest Times:**
- ✅ Brand Color #F77E2D systemweit implementiert
- ✅ Per-Set Rest Times (individuelle Pausenzeiten pro Satz)
- ✅ Difficulty Badges zu Graustufen geändert
- ✅ Color+AppColors.swift mit hex initializer

**Session 20 - Quick-Setup Workout Creation:**
- ✅ WorkoutCreationModeSheet mit 3 Modi
- ✅ 3-Schritt Quick-Setup Wizard (Equipment → Dauer → Ziel)
- ✅ QuickSetupWorkoutUseCase (AI-basierte Generierung)
- ✅ QuickSetupPreviewView mit Smart Exercise Swap
- ✅ Plus-Icon Button für Create Workout

**Session 21 - Workout Folders/Categories:**
- ✅ WorkoutFolder Domain Entity + SwiftData persistence
- ✅ ManageFoldersSheet + CreateFolderSheet
- ✅ 8 vordefinierte Farben für Folders
- ✅ Context Menu zum Verschieben von Workouts
- ✅ Collapsible Folder Sections in HomeView
- ✅ Auto-move zu "Ohne Kategorie" bei Folder-Deletion
- ✅ UI Reactivity Fixes (@Bindable + onChange Listener)
- ✅ Rest Timer Notification Bugs behoben
- ✅ Difficulty Labels aus Exercise List entfernt
- ✅ Collapsible Sections für Favoriten & Alle Workouts

### Session 8+ (2025-10-24) - Documentation Update & HomeView Redesign
- ✅ HomeView Redesign (Greeting, Locker Number, Calendar)
- ✅ Dark Mode Fix (white text on white background)
- ✅ Reviewed entire codebase
- ✅ Updated README.md with actual status
- ✅ Updated TODO.md with new priorities

### Session 7 (2025-10-23) - Workout Management Complete
- ✅ Create/Edit/Delete Workouts
- ✅ Multi-select ExercisePicker
- ✅ Exercise Detail Editor (Time/Reps toggle)
- ✅ Standardized headers
- ✅ Fixed HomeView refresh bug

### Session 6 (2025-10-23) - Exercise Reordering
- ✅ Exercise drag & drop reordering in active sessions
- ✅ Permanent save toggle (saves to workout template)
- ✅ ReorderExercisesSheet with dedicated UI
- ✅ Production-ready with explicit orderIndex
- ✅ In-place updates in WorkoutMapper & SessionMapper
- ✅ Auto-finish exercise when all sets completed

### Earlier Sessions (1-5) - MVP Foundation
- ✅ Clean Architecture Setup (4 Layers)
- ✅ SwiftData Integration
- ✅ Session Management (Start/End/Pause/Resume)
- ✅ Active Workout UI
- ✅ Exercise Library (145+ Übungen)
- ✅ Set Management (Complete/Uncomplete/Add/Remove)
- ✅ Rest Timer with Notifications

---

## 🔧 Technical Debt

### Code Quality Improvements (Optional)

**✅ DONE:**
- ✅ Debug Logging entfernt (Session 22)
- ✅ Legacy Code Cleanup - Item.swift entfernt (Session 22)
- ✅ File naming - HomeViewPlaceholder → HomeView (Session 22)

**Medium Priority:**
- [ ] **Unit Tests auslagern** - Tests aus inline zu separate Test target verschieben
  - CompleteSetUseCase.swift, EndSessionUseCase.swift, StartSessionUseCase.swift
  - SwiftDataSessionRepository.swift, SessionMapper.swift
- [ ] **Structured Logging** - print() → AppLogger mit strukturierten Metadaten

**Low Priority (Nice-to-Have):**
- [ ] **Profile Placeholders** - ProfileView.swift & ExerciseDetailView.swift komplettieren
- [ ] **ProgressView implementieren** - Aktuell nur Placeholder
- [ ] **CompactExerciseCard verbessern** - Exercise names/equipment aus Repository laden (aktuell hardcoded)
- [ ] **Ordnerstruktur aufräumen** - `GymBo/GymBo/GymBo/` verschachtelt (Risiko: Xcode .pbxproj breaking)

### Error Handling Improvements

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

---

## 📋 Wie du neue To-dos hinzufügst

### Quick Add (Oben im Dokument)

1. **Scroll nach oben** zu "📋 AKTUELLE TO-DOs (Kanban)"
2. **Wähle Priorität:**
   - 🔴 High Priority - Wichtig, bald erledigen
   - 🟡 Medium Priority - Wichtig, aber nicht dringend
   - 🟢 Low Priority - Nice-to-have
3. **Füge eine Zeile hinzu:**
   ```markdown
   - [ ] **Dein Feature Name** - Kurze Beschreibung
   ```

### Detailed Add (Unten bei "GEPLANTE FEATURES")

1. **Scroll zu "🚀 GEPLANTE FEATURES"**
2. **Kopiere ein bestehendes Feature** als Template
3. **Fülle aus:**
   - Status (🔴/🟡/🟢)
   - Ziel
   - User Story (optional)
   - Implementation Details
   - Dateien
4. **Füge Link im Kanban oben hinzu** (optional)

### Beispiel:

```markdown
## 📋 AKTUELLE TO-DOs (Kanban)

### 🔴 High Priority
- [x] ~~Debug Logging entfernen~~ (DONE Session 22)
- [ ] **Dein neues Feature** - Beschreibung

---

## 🚀 GEPLANTE FEATURES

### 13. Dein neues Feature (Effort - X Std)
**Status:** 🔴 High Priority (Kanban)
**Ziel:** Was soll erreicht werden

**Features:**
- Feature 1
- Feature 2

**Dateien:**
- `/Path/To/File.swift` - NEW
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
- ✅ Committed & Pushed mit descriptive message

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

---

## 📚 Documentation Index

- `CURRENT_STATE.md` - Current implementation status
- `TODO.md` - This file - Task prioritization & tracking
- `TECHNICAL_CONCEPT_V2.md` - Architecture details
- `UX_CONCEPT_V2.md` - UI/UX design
- `PROGRESSION_FEATURE_PLAN.md` - Complete Phase 2 specification
- `PROGRESSION_QUICK_REF.md` - Quick reference for Phase 2

---

**Last Updated:** 2025-10-29 - Session 26 Feature Flags Complete
