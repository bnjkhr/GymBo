# GymBo - Session Memory

**Letzte Aktualisierung:** 2025-10-25

---

## 🎯 Wichtige Projekt-Informationen

### Skills Location
**Pfad:** `~/.claude/skills/` (= `/Users/benkohler/.claude/skills/`)

**Verfügbare Skills:**
1. **alarmkit.md** - Apple AlarmKit Framework Guide (für Rest Timer Notifications)
2. **ios26-design.md** - iOS 26 Design Guidelines & Liquid Glass System

**Status:** Skills sind als Markdown vorhanden, aber nicht als MCP-Server registriert. Können als Referenz-Dokumentation gelesen werden.

---

## 📊 Projekt-Status (Stand: 2025-10-25)

### Version: 2.1.1 - UI Polishing & Bug Fixes

**Alle Core Features implementiert:**
- ✅ Workout Management (Create/Edit/Delete/Favorite)
- ✅ Exercise Library (145+ Übungen, Search, Filter, Create, Delete)
- ✅ Custom Exercise Management (Create/Delete mit Business Rules)
- ✅ Workout Detail & Exercise Management (Multi-Select Picker, Reorder)
- ✅ Active Workout Session (vollständig)
- ✅ UI/UX (Modern Dark Theme, iOS 26 Design, TabBar Auto-Hide)
- ✅ Architecture (Clean Architecture, 19 Use Cases, 3 Repositories)

**Dokumentation aktualisiert:**
- README.md → 2.1.0, Production Ready Status
- TODO.md → Alle erledigten Features markiert, neue Features aus notes.md hinzugefügt

---

## ✅ Session 2025-10-25 (Session 18) - Ganzkörper Maschine Workout Update

### Workout "Ganzkörper Maschine" mit korrekten Übungen aktualisiert
**Status:** ✅ Implementiert und getestet

**User Request:**
Workout "Ganzkörper Maschine" bearbeiten mit diesen 9 Übungen:
1. Beinpresse - 3x8 (90s)
2. Brustpresse - 3x8 (90s)
3. Latzug zur Brust - 3x8 (90s)
4. Schulterpresse - 3x8 (90s)
5. Beinbeuger - 3x8 (90s)
6. Rudermaschine - 3x8 (90s)
7. Beinstrecker - 3x8 (90s)
8. Trizepsmaschine - 3x8 (90s)
9. Bauchmaschine - 3x12 (60s)

**Implementation:**

**Datei:** `Infrastructure/SeedData/WorkoutSeedData.swift`

```swift
// 1. Beinpresse: 3x8
if let exercise = exercises["Beinpresse"] {
    let ex = WorkoutExerciseEntity(
        exerciseId: exercise.id,
        exercise: exercise,
        sets: createSets(count: 3, reps: 8, weight: 0),
        workout: fullBodyMachine,
        order: order
    )
    fullBodyMachine.exercises.append(ex)
    order += 1
}

// ... (weitere 8 Übungen)

// 9. Bauchmaschine: 3x12 (60s pause)
if let exercise = exercises["Bauchmuskel-Crunch-Maschine"] {
    let ex = WorkoutExerciseEntity(
        exerciseId: exercise.id,
        exercise: exercise,
        sets: createSets(count: 3, reps: 12, weight: 0, restTime: 60),
        workout: fullBodyMachine,
        order: order
    )
    fullBodyMachine.exercises.append(ex)
    order += 1
}
```

**Mapping:**
- Rudermaschine → "Sitzendes Kabelrudern"
- Trizepsmaschine → "Trizepsstrecker-Maschine"
- Bauchmaschine → "Bauchmuskel-Crunch-Maschine"

**Commits:**
- `a69dfd7` - feat: Update Ganzkörper Maschine workout with correct exercises

---

## ✅ Session 2025-10-25 (Session 17) - Tab-Bar Auto-Hide Fix

### Tab-Bar Auto-Hide in HomeView funktioniert jetzt
**Status:** ✅ Gelöst - Content-Länge war das Problem

**Problem:**
Tab-Bar verschwindet beim Scrollen in HomeView nicht, funktioniert aber in ExercisesView.

**Diagnose:**
Mehrere Ansätze getestet:
1. ❌ `.safeAreaInset()` für fixen Header
2. ❌ ZStack entfernen
3. ❌ Struktur an ExercisesView angleichen (VStack mit fixem Header)
4. ✅ **Root Cause:** View hatte nicht genug scrollbaren Content!

**Lösung:**
iOS benötigt eine **Mindest-Scroll-Länge**, um `.tabBarMinimizeBehavior(.onScrollDown)` zu aktivieren. Mit Test-Padding von 500pt funktionierte es sofort.

**Erkenntnisse:**
- `.tabBarMinimizeBehavior()` ist ein iOS 26 Feature (nicht iOS 18!)
- Funktioniert nur wenn genug Content zum Scrollen vorhanden ist
- ExercisesView hatte immer genug Content (100+ Übungen)
- HomeView mit nur 1-2 Workouts war zu kurz

**Finale Struktur (wie ExercisesView):**
```swift
VStack(spacing: 0) {
    // Fixed Header (scrollt NICHT mit)
    GreetingHeaderView(...)
    
    // Fixed Calendar (scrollt NICHT mit)
    WorkoutCalendarStripView(...)
    
    // Scrollable Content
    if store.isLoading {
        ProgressView(...)
    } else if workouts.isEmpty {
        emptyWorkoutState
    } else {
        workoutScrollView(...)  // ← ScrollView hier drin
    }
}
```

**Commits:**
- `cf87b0e` - fix: Replicate ExercisesView structure for Tab-Bar auto-hide
- `6f76132` - test: Add extra scrollable space to test Tab-Bar auto-hide
- `32080c5` - fix: Remove test padding - Tab-Bar auto-hide works correctly

---

## ✅ Session 2025-10-25 (Session 16) - ExercisesView 3-Line Layout & UI Fixes

### ExercisesView: 3-Zeilen-Layout für Exercise Cards
**Status:** ✅ Implementiert

**User Request:**
"Übungen: Darstellung wie folgt: Übungsname /neue Zeile equiptment type /neue Zeile Körperteil(e) /neue Zeile → Körperteile nicht umbrechen sondern kommagetrennt hintereinander"

**Implementation:**

**Datei:** `Presentation/Views/Exercises/ExercisesView.swift`

```swift
private struct ExerciseCard: View {
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Exercise Info (Left) - 3 lines
                VStack(alignment: .leading, spacing: 4) {
                    // Line 1: Exercise Name
                    Text(exercise.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    // Line 2: Equipment Type
                    if !exercise.equipmentTypeRaw.isEmpty {
                        Text(exercise.equipmentTypeRaw)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Line 3: Muscle Groups (comma-separated, no wrap)
                    if !exercise.muscleGroupsRaw.isEmpty {
                        Text(exercise.muscleGroupsRaw.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Difficulty Badge (Right)
                if !exercise.difficultyLevelRaw.isEmpty {
                    difficultyBadge(for: exercise.difficultyLevelRaw)
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
```

### HomeView: "Neues Workout erstellen" Button Redesign
**Status:** ✅ Implementiert

**User Request:**
"HomeView: Neues Workout erstellen in schwarz, nicht in blau und links zentrieren, direkt unter 'Workouts' (Überschrift)"

**Implementation:**

**Datei:** `Presentation/Views/Home/HomeViewPlaceholder.swift`

```swift
private var createWorkoutButton: some View {
    Button {
        showCreateWorkout = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    } label: {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.body)

            Text("Neues Workout erstellen")
                .font(.body)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black)  // ← Schwarz statt Grau
        .cornerRadius(12)
    }
    .frame(maxWidth: .infinity, alignment: .leading)  // ← Links ausgerichtet
}
```

**Positionierung:**
- Direkt unter "Workouts" Überschrift
- Vor der LazyVStack mit den Workout-Cards
- Links ausgerichtet statt zentriert

### Bug Fix: Syntax Error in AddExerciseToSessionSheet
**Status:** ✅ Gefixt

**Problem:**
```swift
filtered = filtered.filter { $0.    equipmentTypeRaw == equipment }
```
Extra Leerzeichen nach `$0.` verursachten Build-Error.

**Fix:**
```swift
filtered = filtered.filter { $0.equipmentTypeRaw == equipment }
```

**Commits:**
- `ea0403c` - fix: Remove extra whitespace in AddExerciseToSessionSheet filter
- Implements 3-line layout for ExercisesView cards

---

## ✅ Session 2025-10-24 (Session 15) - ExercisesView Redesign

### ExercisesView Exercise Cards Redesign
**Status:** ✅ Komplett implementiert, BUILD SUCCEEDED

**User Request:**
- Equipment icon vor Übungsnamen entfernen
- Equipment Type unter Übungsnamen anzeigen (in grau)
- Selbe Tags wie HomeView verwenden (Difficulty Badges mit Farben)

**Implementation:**

**ExerciseCard Redesign (ExercisesView.swift):**

**Before:**
```swift
HStack(spacing: 12) {
    Image(systemName: equipmentIcon)  // ← Removed
        .font(.title3)
        .frame(width: 32)
    
    VStack(alignment: .leading, spacing: 4) {
        Text(exercise.name)
        HStack {
            Text(muscleGroups).foregroundStyle(.secondary)
            Text("•")
            Text(difficulty).foregroundStyle(.secondary)
        }
    }
    Spacer()
    Image(systemName: "chevron.right")
}
```

**After:**
```swift
HStack(spacing: 12) {
    VStack(alignment: .leading, spacing: 6) {
        // Exercise Name
        Text(exercise.name)
            .font(.body)
            .fontWeight(.medium)
            .lineLimit(1)
        
        // Equipment Type + Muscle Groups (gray)
        HStack(spacing: 8) {
            Text(exercise.equipmentTypeRaw)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("•")
            Text(muscleGroups)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    Spacer()
    
    // Difficulty Badge (SAME as HomeView)
    difficultyBadge(for: exercise.difficultyLevelRaw)
    
    Image(systemName: "chevron.right")
}
```

**Difficulty Badge (Reused from HomeView):**
```swift
@ViewBuilder
private func difficultyBadge(for level: String) -> some View {
    let (color, icon) = difficultyStyle(for: level)
    
    HStack(spacing: 4) {
        Image(systemName: icon)
            .font(.caption2)
        Text(level)
            .font(.caption)
            .fontWeight(.medium)
    }
    .foregroundColor(color)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(color.opacity(0.15))
    .cornerRadius(8)
}

private func difficultyStyle(for level: String) -> (Color, String) {
    switch level {
    case "Anfänger":
        return (.green, "leaf.fill")  // 🍃
    case "Fortgeschritten":
        return (.orange, "flame.fill")  // 🔥
    case "Profi":
        return (.red, "bolt.fill")  // ⚡
    default:
        return (.gray, "circle.fill")
    }
}
```

**Design Improvements:**
- ✅ **Consistent Design Language:** ExercisesView jetzt same style wie HomeView
- ✅ **Cleaner Look:** Kein Icon mehr → weniger visuelles Rauschen
- ✅ **More Informative:** Equipment Type sofort sichtbar (nicht nur Icon)
- ✅ **Color-Coded Difficulty:** Sofort erkennbar (green/orange/red)
- ✅ **Better Space Usage:** VStack layout nutzt Raum optimal

**Modified Files:**
- `Presentation/Views/Exercises/ExercisesView.swift` - ExerciseCard redesign

**Build Status:** ✅ BUILD SUCCEEDED
**UI Consistency:** ✅ HomeView und ExercisesView haben jetzt identische Badge-Styles

---

## ✅ Session 2025-10-24 (Session 14) - Equipment Type Labels

### Equipment Type Labels in HomeView
**Status:** ✅ Komplett implementiert, BUILD SUCCEEDED

**User Request:**
- Equipment type ("Maschine", "Freie Gewichte", "Gemischt") unter Workout-Namen anzeigen
- Barbell Icon vor dem Namen entfernen
- In grau anzeigen

**Implementation:**

**1. Schema Changes:**
```swift
// SwiftDataEntities.swift - WorkoutEntity
var equipmentType: String?  // "Maschine", "Freie Gewichte", "Gemischt"

// Domain/Entities/Workout.swift
var equipmentType: String?  // "Maschine", "Freie Gewichte", "Gemischt"
```

**2. WorkoutMapper Updates:**
- `toEntity()`: Maps equipmentType to SwiftData
- `toDomain()`: Maps equipmentType from SwiftData
- `updateEntity()`: Updates equipmentType on in-place updates
- Backwards compatible: nil für alte Workouts

**3. HomeView WorkoutCard Redesign:**

**Before:**
```swift
HStack(spacing: 12) {
    Image(systemName: "dumbbell.fill")  // ← Removed
    Text(workout.name)
    Spacer()
    if workout.isFavorite { ... }
}
```

**After:**
```swift
HStack(spacing: 12) {
    VStack(alignment: .leading, spacing: 4) {
        // Title
        Text(workout.name)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .lineLimit(1)
        
        // Equipment Type (NEW)
        if let equipmentType = workout.equipmentType {
            Text(equipmentType)
                .font(.subheadline)
                .foregroundColor(.secondary)  // Gray color
        }
    }
    Spacer()
    if workout.isFavorite { ... }
}
```

**4. WorkoutSeedData Updates:**
- All 6 workouts now have `equipmentType` set:
  - "Ganzkörper Maschine" → "Maschine"
  - "Oberkörper Maschine" → "Maschine"
  - "Push Day (Langhantel)" → "Freie Gewichte"
  - "Pull Day (Langhantel & Kurzhantel)" → "Freie Gewichte"
  - "Beine Push/Pull" → "Gemischt"
  - "Oberkörper Hybrid" → "Gemischt"

**Modified Files:**
- `SwiftDataEntities.swift` - equipmentType property in WorkoutEntity
- `Domain/Entities/Workout.swift` - equipmentType property
- `Data/Mappers/WorkoutMapper.swift` - equipmentType mapping
- `Presentation/Views/Home/HomeViewPlaceholder.swift` - WorkoutCard UI redesign
- `Infrastructure/SeedData/WorkoutSeedData.swift` - Equipment types for all 6 workouts

**Build Status:** ✅ BUILD SUCCEEDED
**UI Improvements:** 
- Cleaner look without icon
- More informative (equipment type immediately visible)
- Better vertical space usage

---

## ✅ Session 2025-10-24 (Session 13) - Sample Workouts + Difficulty Levels

### 6 Comprehensive Sample Workouts
**Status:** ✅ Komplett implementiert, getestet, BUILD SUCCEEDED

**Motivation:**
- App brauchte production-ready Beispiel-Workouts
- User wollte 2x Maschinen, 2x Freie Gewichte, 2x Gemischt
- Difficulty Tags sollten Anfänger vs. Fortgeschrittene vs. Profi zeigen

**1. Neue Sample Workouts:**

**Nur Maschinen (2):**
1. **"Ganzkörper Maschine"** - Anfänger 🍃
   - 6 Übungen: Beinpresse, Brustpresse, Latzug, Schulterpresse, Beinbeuger, Sitzendes Rudern
   - 3x10-12 Reps pro Übung
   - 90s Rest
   - Perfekt für Gym-Einsteiger

2. **"Oberkörper Maschine"** - Fortgeschritten 🔥
   - 7 Übungen: Brustpresse, Latzug, Schulterpresse, Sitzendes Rudern, Butterfly, Trizeps-, Bizepsmaschine
   - 3-4x8-12 Reps
   - Intensiveres Oberkörpertraining

**Nur Freie Gewichte (2):**
3. **"Push Day (Langhantel)"** - Fortgeschritten 🔥
   - 5 Übungen: Bankdrücken (4x6), Schrägbank (4x8), Überkopfdrücken (4x8), Dips (3x10), Trizeps Kabel (3x12)
   - 120s Rest (schwerere Gewichte)
   - Classic compound movements

4. **"Pull Day (Langhantel & Kurzhantel)"** - Fortgeschritten 🔥
   - 6 Übungen: Kreuzheben (4x5, 180s rest!), Langhantelrudern (4x8), Klimmzüge (4x6), Kurzhantelrudern (3x10), Bizeps Curls, Hammer Curls
   - 120-180s Rest
   - Heavy pulling focus

**Gemischt (2):**
5. **"Beine Push/Pull"** - Profi ⚡
   - 7 Übungen: Kniebeugen (5x5), Beinpresse, Rumänisches Kreuzheben, Beinbeuger, Beinstrecker, Ausfallschritte, Wadenheben (4x15)
   - 180s Rest für Squats
   - Kombination Langhantel + Maschinen
   - Komplettes Beintraining

6. **"Oberkörper Hybrid"** - Fortgeschritten 🔥
   - 8 Übungen: Mix aus Bankdrücken, Brustpresse, Klimmzüge, Latzug, Kurzhantel Schulterdrücken, Seitheben, Bizeps, Trizeps
   - 90-120s Rest
   - Best of both worlds (Free weights + Machines)

**2. Difficulty Level System:**

**Schema Changes:**
```swift
// SwiftDataEntities.swift - WorkoutEntity
var difficultyLevel: String?  // "Anfänger", "Fortgeschritten", "Profi"

// Domain/Entities/Workout.swift
var difficultyLevel: String?  // "Anfänger", "Fortgeschritten", "Profi"
```

**WorkoutMapper Updates:**
- `toEntity()`: Maps difficultyLevel to SwiftData
- `toDomain()`: Maps difficultyLevel from SwiftData
- `updateEntity()`: Updates difficultyLevel on in-place updates
- Backwards compatible: nil für alte Workouts ohne Level

**3. HomeView Difficulty Badges:**

**Implementation (HomeViewPlaceholder.swift - WorkoutCard):**
```swift
// Difficulty Badge
if let difficulty = workout.difficultyLevel {
    difficultyBadge(for: difficulty)
}

private func difficultyBadge(for level: String) -> some View {
    let (color, icon) = difficultyStyle(for: level)
    
    HStack(spacing: 4) {
        Image(systemName: icon)
            .font(.caption2)
        Text(level)
            .font(.caption)
            .fontWeight(.medium)
    }
    .foregroundColor(color)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(color.opacity(0.15))
    .cornerRadius(8)
}

private func difficultyStyle(for level: String) -> (Color, String) {
    switch level {
    case "Anfänger":
        return (.green, "leaf.fill")
    case "Fortgeschritten":
        return (.orange, "flame.fill")
    case "Profi":
        return (.red, "bolt.fill")
    default:
        return (.gray, "circle.fill")
    }
}
```

**Design:**
- Green pill mit 🍃 leaf icon für "Anfänger"
- Orange pill mit 🔥 flame icon für "Fortgeschritten"
- Red pill mit ⚡ bolt icon für "Profi"
- 15% opacity background (subtle, nicht überwältigend)
- Positioned bottom-right in stats row

**4. WorkoutSeedData Komplett überarbeitet:**

**Removed:**
- "Push Day" (single exercise)
- "Pull Day" (single exercise)
- "Leg Day" (single exercise)
- "TEST - Multi Exercise" (Test-Workout)
- Old "Ganzkörper Maschine" (kept but improved)

**Added:**
- 5 neue comprehensive Workouts
- Alle mit `isSampleWorkout: true` Flag
- Alle mit `difficultyLevel` gesetzt
- Realistiche Gewichte für jede Übung
- Varied rep ranges (5-15 reps)
- Varied rest times (60-180s)

**Neue Dateien:**
- Keine neuen Dateien (nur Änderungen)

**Modified Files:**
- `SwiftDataEntities.swift` - difficultyLevel property in WorkoutEntity
- `Domain/Entities/Workout.swift` - difficultyLevel property
- `Data/Mappers/WorkoutMapper.swift` - Mapping für difficultyLevel
- `Presentation/Views/Home/HomeViewPlaceholder.swift` - Difficulty badges
- `Infrastructure/SeedData/WorkoutSeedData.swift` - 6 neue Workouts

**Build Status:** ✅ BUILD SUCCEEDED
**Testing:** App zeigt jetzt 6 production-ready Workouts mit Difficulty Badges
**Performance:** Keine Performance-Issues, Seed läuft schnell

**Learnings:**
- Optional Properties in SwiftData für backwards compatibility
- Difficulty Badges verbessern UX massiv (User sieht sofort Level)
- Sample Workouts müssen realistic sein (Gewichte, Rest Times)
- Icon + Color Coding ist intuitiver als nur Text

---

## ✅ Session 2025-10-24 (Session 12) - Add Exercise to Active Workout

### Add Exercise to Active Session Feature
**Status:** ✅ Komplett implementiert, getestet, alle Bugs gefixt

**Feature:**
- Plus-Button in ActiveWorkoutSheetView
- Öffnet AddExerciseToSessionSheet mit Exercise Picker
- Single-Select Picker mit Search/Filter
- Toggle: "Dauerhaft in Workout speichern"
- Zwei Modi:
  - **Session-Only:** Übung nur für aktuelle Session hinzufügen
  - **Permanent:** Übung zu Session UND Workout-Template hinzufügen

**1. Domain Layer - AddExerciseToSessionUseCase:**
- Business Logic für Hinzufügen von Übungen zu aktiven Sessions
- Progressive Overload Integration (lastUsed values)
- Validierung: Session & Exercise müssen existieren
- Automatische orderIndex-Berechnung (maxOrderIndex + 1)
- Default Sets mit Smart Defaults (lastUsed oder Fallback-Werte)

**Implementation Details:**
```swift
func execute(sessionId: UUID, exerciseId: UUID) async throws -> DomainWorkoutSession {
    // 1. Fetch active session
    guard var session = try await sessionRepository.fetchActiveSession() else {
        throw AddExerciseToSessionError.sessionNotFound(sessionId)
    }
    
    // 2. Fetch exercise from catalog
    guard let catalogExercise = try? await exerciseRepository.fetch(id: exerciseId) else {
        throw AddExerciseToSessionError.exerciseNotFound(exerciseId)
    }
    
    // 3. Determine next orderIndex
    let maxOrderIndex = session.exercises.map { $0.orderIndex }.max() ?? -1
    let newOrderIndex = maxOrderIndex + 1
    
    // 4. Create default sets with Progressive Overload
    let defaultSets = createDefaultSets(from: catalogExercise)
    
    // 5. Create new session exercise
    let newSessionExercise = DomainSessionExercise(
        exerciseId: exerciseId,
        sets: defaultSets,
        notes: nil,
        restTimeToNext: catalogExercise.lastUsedRestTime ?? 90.0,
        orderIndex: newOrderIndex,
        isFinished: false
    )
    
    // 6. Add to session and persist
    session.exercises.append(newSessionExercise)
    try await sessionRepository.update(session)
    
    return session
}

private func createDefaultSets(from exercise: DomainExercise) -> [DomainSessionSet] {
    let targetSetCount = exercise.lastUsedSetCount ?? 3
    return (0..<targetSetCount).map { index in
        DomainSessionSet(
            setNumber: index + 1,
            type: .normal,
            targetReps: exercise.lastUsedReps ?? 8,
            targetWeight: exercise.lastUsedWeight,
            actualReps: nil,
            actualWeight: nil,
            isCompleted: false
        )
    }
}
```

**2. Presentation Layer - AddExerciseToSessionSheet:**
- Navigation Stack mit Exercise List
- Search & Filter (Muscle Groups, Equipment)
- Single-Select Pattern (Button statt Checkbox)
- Caching für Performance (wie ExercisesView)
- Bottom Toggle Section mit Erklärung
- Auto-Dismiss nach Auswahl

**UI Features:**
```swift
struct AddExerciseToSessionSheet: View {
    let onAddExercise: (ExerciseEntity, Bool) -> Void
    
    @State private var savePermanently = false
    @State private var cachedFilteredExercises: [ExerciseEntity] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Exercise List
                List {
                    ForEach(cachedFilteredExercises) { exercise in
                        ExerciseRowButton(exercise: exercise) {
                            selectExercise(exercise)
                        }
                    }
                }
                .searchable(text: $searchText)
                
                // Bottom Toggle Section
                permanentSaveToggle
            }
        }
    }
    
    private var permanentSaveToggle: some View {
        Toggle(isOn: $savePermanently) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dauerhaft in Workout speichern")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Übung wird dem Workout-Template hinzugefügt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.orange)
        .padding()
    }
}
```

**3. SessionStore Enhancement:**
- `addExerciseToSession(exerciseId:savePermanently:)` Methode
- Private Helper: `addExerciseToWorkoutTemplate()`
- Immediate UI Update (set currentSession = nil then reload)
- Success Message mit Haptic Feedback

**Implementation:**
```swift
func addExerciseToSession(exerciseId: UUID, savePermanently: Bool) async {
    guard let sessionId = currentSession?.id,
          let workoutId = currentSession?.workoutId else {
        return
    }

    do {
        // 1. Add to session
        let updatedSession = try await addExerciseToSessionUseCase.execute(
            sessionId: sessionId,
            exerciseId: exerciseId
        )

        // 2. Update UI immediately
        currentSession = nil
        currentSession = updatedSession

        // 3. If permanent save requested, add to workout template
        if savePermanently {
            try await addExerciseToWorkoutTemplate(
                workoutId: workoutId,
                exerciseId: exerciseId
            )
        }

        showSuccessMessage("Übung hinzugefügt")
    } catch {
        self.error = error
    }
}

private func addExerciseToWorkoutTemplate(workoutId: UUID, exerciseId: UUID) async throws {
    guard let exercise = try? await exerciseRepository.fetch(id: exerciseId),
          let workout = try? await workoutRepository.fetch(id: workoutId) else {
        throw NSError(...)
    }
    
    let maxOrderIndex = workout.exercises.map { $0.orderIndex }.max() ?? -1
    
    let newWorkoutExercise = WorkoutExercise(
        exerciseId: exerciseId,
        targetSets: exercise.lastUsedSetCount ?? 3,
        targetReps: exercise.lastUsedReps ?? 8,
        targetWeight: exercise.lastUsedWeight,
        restTime: exercise.lastUsedRestTime ?? 90.0,
        orderIndex: maxOrderIndex + 1,
        notes: nil
    )
    
    var updatedWorkout = workout
    updatedWorkout.exercises.append(newWorkoutExercise)
    try await workoutRepository.update(updatedWorkout)
}
```

**4. WorkoutDetailView Refresh Fix:**
- **Problem:** Nach permanentem Hinzufügen war Workout-Übersicht nicht aktualisiert
- **Lösung:** Refresh Trigger Pattern

**WorkoutStore Enhancement:**
```swift
@Observable
final class WorkoutStore {
    var workouts: [Workout] = []
    var refreshTrigger: Int = 0
    
    func triggerRefresh() {
        refreshTrigger += 1
        Task {
            await loadWorkouts()
        }
    }
}
```

**WorkoutDetailView Update:**
```swift
.task(id: workoutStore.refreshTrigger) {
    // Reload when refreshTrigger changes
    await loadData()
}
```

**ActiveWorkoutSheetView Trigger:**
```swift
.sheet(isPresented: $showAddExerciseSheet) {
    AddExerciseToSessionSheet { exercise, savePermanently in
        Task {
            await sessionStore.addExerciseToSession(
                exerciseId: exercise.id,
                savePermanently: savePermanently
            )
            await loadExerciseNames()
            
            if savePermanently {
                workoutStore.triggerRefresh()
            }
        }
    }
}
```

**Neue Dateien:**
- `/Domain/UseCases/Session/AddExerciseToSessionUseCase.swift`
- `/Presentation/Views/ActiveWorkout/Sheets/AddExerciseToSessionSheet.swift`

**Modified Files:**
- `SessionStore.swift` - addExerciseToSession(), addExerciseToWorkoutTemplate()
- `WorkoutStore.swift` - refreshTrigger property & triggerRefresh()
- `ActiveWorkoutSheetView.swift` - Plus button, sheet, WorkoutStore environment
- `WorkoutDetailView.swift` - task(id: refreshTrigger)
- `HomeViewPlaceholder.swift` - WorkoutStore environment für ActiveWorkoutSheetView
- `DependencyContainer.swift` - AddExerciseToSessionUseCase factory

**Bug Fixes (während Session):**
1. **Parameter Name Mismatch:** `catalogExerciseId` → `exerciseId`
2. **Preview Missing Dependency:** Added addExerciseToSessionUseCase to SessionStore.preview
3. **Property Name Errors:** `muscleGroups` → `muscleGroupsRaw`, `equipment` → `equipmentTypeRaw`
4. **Environment Missing:** Added `.environment(workoutStore)` zu ActiveWorkoutSheetView

**Build Status:** ✅ BUILD SUCCEEDED
**Testing:** ✅ Beide Modi funktionieren perfekt
**UI Updates:** ✅ Sofortige Aktualisierung in allen Views

**Commits:**
- `866601a` - feat: Implement Add Exercise to Active Session
- `2bb717d` - fix: Add missing dependency to SessionStore preview
- `4ca604d` - fix: Update property names to match ExerciseEntity
- `5c2e8dc` - fix: Add WorkoutStore environment to ActiveWorkoutSheetView
- `11a6102` - feat: Implement WorkoutDetailView refresh trigger

---

## ✅ Session 2025-10-24 (Session 11) - TextField Performance & UI Update Fixes

### Critical Performance Fixes
**Status:** ✅ Implementiert

**Problem 1: TextField Performance Issues**
- Console Errors: "Gesture: System gesture gate timed out"
- "Invalid frame dimension (negative or non-finite)"
- Massive lag beim Tippen in allen TextFields
- Betroffene Views: CreateWorkout, EditWorkout, CreateExercise, EditExerciseDetails

**Lösung:**
- Added `.scrollDismissesKeyboard(.interactively)` zu allen ScrollViews
- Reduziert View-Updates während Eingabe
- Keyboard wird beim Scrollen automatisch dismissed

**Problem 2: Keyboard verdeckt TextField**
- Gewicht-TextField in EditExerciseDetailsView war nicht sichtbar
- ScrollView scrollte nicht automatisch nach oben

**Lösung:**
- Added `.padding(.bottom, 100)` für Extra-Platz unter Content
- Toolbar "Fertig" Button zum manuellen Keyboard-Dismiss
- `.scrollDismissesKeyboard(.interactively)` für bessere Keyboard-Behandlung

**Problem 3: UI aktualisiert nicht sofort nach Speichern**
- Gewichts-Änderung in WorkoutDetailView wurde erst nach App-Neustart angezeigt
- ExerciseCard zeigte alte Daten

**Lösung:**
- Added `.id()` Modifier auf ExerciseCard basierend auf aktuellen Werten
```swift
.id("\(exercise.id)-\(exercise.targetSets)-\(exercise.targetReps ?? 0)-\(exercise.targetWeight ?? 0)")
```
- Erzwingt SwiftUI Re-Render bei Daten-Änderung

**Modified Files:**
- `Presentation/Views/WorkoutDetail/EditExerciseDetailsView.swift` - Keyboard fixes
- `Presentation/Views/WorkoutDetail/CreateWorkoutView.swift` - Performance fix
- `Presentation/Views/WorkoutDetail/EditWorkoutView.swift` - Performance fix
- `Presentation/Views/Exercises/CreateExerciseView.swift` - Performance fix
- `Presentation/Views/WorkoutDetail/WorkoutDetailView.swift` - Immediate UI update fix

**Result:** 
- ✅ Butterweiche TextField-Performance
- ✅ Keyboard verdeckt Felder nicht mehr
- ✅ UI aktualisiert sofort nach Speichern

---

## ✅ Session 2025-10-24 (Session 10) - TabBar Auto-Hide

### TabBar Auto-Hide Feature
**Status:** ✅ Implementiert

**Implementation:**
- Added `.tabBarMinimizeBehavior(.onScrollDown)` to MainTabView
- TabBar verschwindet automatisch beim Runterscrollen
- TabBar erscheint wieder beim Hochscrollen
- Gibt mehr Platz für Content
- Modernes iOS-Pattern

**Modified Files:**
- `Presentation/Views/Main/MainTabView.swift` - Added modifier to TabView

**Build Status:** ✅ Erfolgreich

---

## ✅ Session 2025-10-24 (Session 9) - Custom Exercise Management

### Custom Exercises: Create & Delete Feature
**Status:** ✅ Komplett implementiert, getestet, dokumentiert

**1. Create Custom Exercises:**
- **CreateExerciseView** - Vollständiges Formular
  - Name TextField (auto-focus)
  - Multi-Select Muscle Groups (FlowLayout chips, orange selection)
  - Equipment Radio Buttons (5 Optionen)
  - Difficulty Pills (3 Stufen)
  - Optional Description & Instructions
  - Validation + Error Handling

- **CreateExerciseUseCase** - Business Logic
  - Name-Validierung (nicht leer)
  - Muscle Groups-Validierung (mindestens 1)
  - Equipment-Validierung (muss ausgewählt sein)
  - Lokalisierte Error Messages

- **Repository Implementation**
  - `ExerciseRepository.create()` Methode
  - SwiftData Persistierung mit `createdAt` timestamp

**2. Delete Custom Exercises:**
- **DeleteExerciseUseCase** - Business Logic & Protection
  - **Business Rule:** Nur custom exercises löschbar (mit `createdAt`)
  - Catalog exercises geschützt (kein `createdAt`)
  - Validierung: Exercise muss existieren
  - Lokalisierte Error Messages

- **UI Implementation**
  - Roter Trash-Button in ExerciseDetailView toolbar
  - Nur sichtbar für custom exercises
  - Confirmation Dialog ("Übung löschen?")
  - Loading State während Deletion
  - Error Alert bei Fehlern
  - Auto-dismiss nach erfolgreichem Löschen
  - Callback für List-Refresh

**3. Performance Optimizations (CRITICAL):**
- **Problem:** Massive Performance-Issues in ExercisesView
  - "Gesture: System gesture gate timed out"
  - Multi-Sekunden Input-Delays
  - Computed properties recalculated on EVERY view update (145+ exercises)

- **Lösung:** Caching Pattern
  ```swift
  @State private var cachedFilteredExercises: [ExerciseEntity] = []
  @State private var cachedMuscleGroups: [String] = []
  @State private var cachedEquipment: [String] = []

  // Updates via .onChange triggers
  .onChange(of: searchText) { _, _ in updateFilteredExercises() }
  .onChange(of: exercises) { _, _ in
      updateFilteredExercises()
      updateAvailableFilters()
  }
  ```
  - **Performance Gain:** ~90-95% reduction in calculations
  - **Result:** Butterweiche Performance, keine Delays mehr

- **HomeView Performance Fix:**
  - Replaced expensive string `.id()` with Hasher-based integer
  - Eliminiert `.map { "\($0.name)-\($0.isFavorite)" }.joined()` overhead
  ```swift
  var hasher = Hasher()
  hasher.combine(workouts.count)
  for workout in workouts {
      hasher.combine(workout.name)
      hasher.combine(workout.isFavorite)
  }
  workoutsHash = hasher.finalize()
  ```

**4. UI Standardization:**
- **Plus Button Pattern** (nach mehreren Iterationen korrekt):
  - Icon: `"plus.circle"` (SF Symbol)
  - Font: `.title2`
  - Color: `.primary`
  - ButtonStyle: `.plain`
  - 44x44 Frame für Touch-Target (optional)

- **ExercisesView Header Redesign:**
  - Problem: Plus-Button saß zu tief (VStack mit 2 Zeilen)
  - Lösung: Count zu Search Placeholder verschoben
  - Single-Line Header: "Übungen" + Plus Button
  - Search: "Durchsuche \(count) Übungen ..."
  - Perfekte vertikale Ausrichtung

**5. New Content:**
- **"Ganzkörper Maschine" Workout** hinzugefügt
  - 9 Übungen (Maschinen-basiert)
  - CSV-Mapping zu existierenden Exercises
  - Extended `createSets()` mit `restTime` parameter

**Neue Dateien:**
- `/Domain/UseCases/Exercise/CreateExerciseUseCase.swift`
- `/Domain/UseCases/Exercise/DeleteExerciseUseCase.swift`
- `/Presentation/Views/Exercises/CreateExerciseView.swift`

**Modified Files:**
- `ExerciseRepositoryProtocol.swift` - create(), delete() methods
- `SwiftDataExerciseRepository.swift` - Implementation
- `ExerciseDetailView.swift` - Delete UI + callback
- `ExercisesView.swift` - Performance caching + Plus button
- `HomeViewPlaceholder.swift` - Hasher-based performance fix
- `ActiveWorkoutSheetView.swift` - Eye toggle color
- `WorkoutSeedData.swift` - Ganzkörper Maschine workout

**Build Status:** ✅ BUILD SUCCEEDED

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
- `/Domain/` - 19 Use Cases, Entities, Protocols
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

**Zuletzt bearbeitet:** 2025-10-24 (Session 15 - ExercisesView Redesign)
**Session-Dauer:** ~30 Minuten
**Features:** 
- ExercisesView Exercise Cards Redesign (consistent with HomeView)
- Removed equipment icon from exercise rows
- Equipment Type below name in gray + Muscle Groups
- Difficulty Badges (same style as HomeView: 🍃🔥⚡)
**Modified Files:** 1 File (ExercisesView.swift)
**Design:** Consistent design language across HomeView and ExercisesView
**UI Improvement:** Cleaner look, more informative, color-coded difficulty
**Dokumentation:** CURRENT_STATE.md, SESSION_MEMORY.md aktualisiert
**Build Status:** ✅ BUILD SUCCEEDED
**Testing:** ✅ Exercise cards display correctly with badges
