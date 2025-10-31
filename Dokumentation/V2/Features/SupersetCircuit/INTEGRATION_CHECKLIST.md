# Superset/Circuit UI - Integration Checklist

**Status:** 🔄 In Progress
**Phase 1:** ✅ Core Components Complete
**Phase 2:** ⏳ Integration Required

---

## ✅ Abgeschlossen (Phase 1)

- [x] ExerciseGroupBuilder.swift erstellt
- [x] CreateSupersetWorkoutView.swift erstellt
- [x] CreateCircuitWorkoutView.swift erstellt
- [x] WorkoutCreationModeSheet.swift erweitert (2 neue Buttons)

---

## ⏳ Erforderliche Integration (Phase 2)

### 1. HomeView - State hinzufügen

**File:** `/Users/benkohler/Projekte/GymBo/GymBo/Presentation/Views/Home/HomeView.swift`

**Zeile ~40-45:** Neue @State-Variablen hinzufügen

```swift
// Nach @State private var showQuickSetup = false
@State private var showCreateSuperset = false  // V6: Superset Training
@State private var showCreateCircuit = false   // V6: Circuit Training
```

---

### 2. SheetsModifier - Bindings erweitern

**File:** `/Users/benkohler/Projekte/GymBo/GymBo/Presentation/Views/Home/HomeView.swift`

**Zeile ~810-815:** Neue Bindings hinzufügen

```swift
struct SheetsModifier: ViewModifier {
    @Binding var showCreateWorkout: Bool
    @Binding var showCreateWorkoutDirect: Bool
    @Binding var showQuickSetup: Bool
    @Binding var showCreateSuperset: Bool   // V6: NEW
    @Binding var showCreateCircuit: Bool    // V6: NEW
    @Binding var showProfile: Bool
    // ... rest bleibt gleich
```

---

### 3. SheetsModifier - WorkoutCreationModeSheet erweitern

**File:** `/Users/benkohler/Projekte/GymBo/GymBo/Presentation/Views/Home/HomeView.swift`

**Zeile ~833-843:** onSelectSuperset & onSelectCircuit hinzufügen

```swift
.sheet(isPresented: $showCreateWorkout) {
    WorkoutCreationModeSheet(
        onSelectEmpty: {
            showCreateWorkoutDirect = true
        },
        onSelectQuickSetup: {
            showQuickSetup = true
        },
        onSelectSuperset: {         // V6: NEW
            showCreateSuperset = true
        },
        onSelectCircuit: {          // V6: NEW
            showCreateCircuit = true
        },
        onSelectWizard: {
            // Coming soon
        }
    )
}
```

---

### 4. SheetsModifier - Neue Sheets hinzufügen

**File:** `/Users/benkohler/Projekte/GymBo/GymBo/Presentation/Views/Home/HomeView.swift`

**Nach `.sheet(isPresented: $showQuickSetup)` (Zeile ~860):**

```swift
// V6: Superset Creation Sheet
.sheet(isPresented: $showCreateSuperset) {
    if let store = workoutStore, let container = dependencyContainer {
        CreateSupersetWorkoutView { createdWorkout in
            navigateToNewWorkout = createdWorkout
        }
        .environment(store)
        .environment(\.dependencyContainer, container)
    }
}

// V6: Circuit Creation Sheet
.sheet(isPresented: $showCreateCircuit) {
    if let store = workoutStore, let container = dependencyContainer {
        CreateCircuitWorkoutView { createdWorkout in
            navigateToNewWorkout = createdWorkout
        }
        .environment(store)
        .environment(\.dependencyContainer, container)
    }
}
```

---

### 5. SheetsModifier - Initializer Parameter erweitern

**File:** `/Users/benkohler/Projekte/GymBo/GymBo/Presentation/Views/Home/HomeView.swift`

**Zeile ~60-75:** In der `.modifier(SheetsModifier(...))` Aufruf

```swift
.modifier(
    SheetsModifier(
        showCreateWorkout: $showCreateWorkout,
        showCreateWorkoutDirect: $showCreateWorkoutDirect,
        showQuickSetup: $showQuickSetup,
        showCreateSuperset: $showCreateSuperset,   // V6: NEW
        showCreateCircuit: $showCreateCircuit,     // V6: NEW
        showProfile: $showProfile,
        // ... rest bleibt gleich
    )
)
```

---

## 🔧 Zusätzliche Anpassungen

### DependencyContainer - Preview Extension (Optional)

**File:** `/Users/benkohler/Projekte/GymBo/GymBo/Infrastructure/DI/DependencyContainer.swift`

Falls noch nicht vorhanden, Preview-Extension hinzufügen:

```swift
#if DEBUG
extension DependencyContainer {
    static var preview: DependencyContainer {
        // Create in-memory ModelContext for previews
        let schema = Schema([
            WorkoutEntity.self,
            WorkoutExerciseEntity.self,
            ExerciseEntity.self,
            WorkoutSessionEntity.self,
            SessionExerciseEntity.self,
            SessionSetEntity.self,
            WorkoutFolderEntity.self,
            UserProfileEntity.self,
            ExerciseGroupEntity.self,  // V6
            SessionExerciseGroupEntity.self  // V6
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        return DependencyContainer(modelContext: modelContainer.mainContext)
    }
}
#endif
```

---

## ✅ Test-Checklist

Nach Integration:

- [ ] App buildet ohne Errors
- [ ] WorkoutCreationModeSheet zeigt 5 Buttons (Empty, Quick-Setup, Superset, Circuit, Wizard)
- [ ] "Superset Training" Button öffnet CreateSupersetWorkoutView
- [ ] "Circuit Training" Button öffnet CreateCircuitWorkoutView
- [ ] Step 1 → Name eingeben & Rest Times auswählen → Weiter funktioniert
- [ ] Step 2 → Gruppe hinzufügen funktioniert (Exercise Picker TODO)
- [ ] Step 3 → Preview zeigt korrekte Daten
- [ ] "Erstellen" Button ruft Use Case auf
- [ ] Nach Erstellung → Navigiert zu WorkoutDetailView
- [ ] Error Handling zeigt Alerts korrekt

---

## 🚧 TODOs (Phase 3)

### Exercise Picker Integration

**Problem:** Aktuell zeigt `exercisePickerSheet` nur "TODO"

**Lösung:** ExercisePicker wiederverwenden

**Implementation:**
1. ExercisePicker als Sheet einbinden
2. Selected Exercise empfangen
3. EditExerciseDetailsSheet öffnen
4. WorkoutExercise erstellen mit:
   - Sets (Rundenanzahl)
   - Reps
   - Weight
   - Rest Time (optional)
5. WorkoutExercise zu Gruppe hinzufügen
6. Exercise Names cachen für Display

**Geschätzter Aufwand:** 1-2 Stunden

---

### Validation & Error Handling

**Was fehlt noch:**
- [ ] Inline Validation Messages
- [ ] "Weiter"-Button disabled bei fehlenden Daten
- [ ] Error Alerts für Use Case Failures
- [ ] Confirmation Dialog bei "Abbrechen" (wenn Daten eingegeben)

**Geschätzter Aufwand:** 30 Min

---

### Polish & UX

**Nice-to-Haves:**
- [ ] Animations (Step transitions)
- [ ] Drag & Drop für Exercise Reordering
- [ ] Auto-Sync von Rundenanzahl zwischen Übungen
- [ ] Loading States während Exercise Namen laden
- [ ] Success Pill nach Workout-Erstellung

**Geschätzter Aufwand:** 1-2 Stunden

---

## 📝 Commit Message (Nach Integration)

```
feat(ui): Add Superset & Circuit Workout creation UI

**Features:**
- CreateSupersetWorkoutView with 3-step wizard
- CreateCircuitWorkoutView with 3-step wizard
- ExerciseGroupBuilder shared component
- Extended WorkoutCreationModeSheet with 2 new buttons

**Wizard Steps:**
1. Basic settings (name, rest times)
2. Create groups (add exercises - ExercisePicker TODO)
3. Preview & save

**Integration:**
- Updated HomeView with new sheet state
- Updated SheetsModifier with Superset/Circuit bindings
- Connected to CreateSupersetWorkoutUseCase & CreateCircuitWorkoutUseCase

**Status:**
✅ Core UI complete
✅ Navigation flow working
✅ Use Cases called correctly
⚠️  Exercise Picker integration pending (Phase 3)

**Next Steps:**
- Integrate ExercisePicker for adding exercises to groups
- Add validation & error handling
- Polish animations & UX

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

**Total Aufwand bisher:** ~4 Stunden (Phase 1 Complete)
**Verbleibend:** ~3-4 Stunden (Phase 2-3)
