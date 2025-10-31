# Superset & Circuit Training - User Guide

**Status:** ✅ PRODUCTION READY (V6 - Schema V6)
**Implementiert:** Session 33 (2025-10-30)
**Version:** GymBo v2.6.0+

---

## 📖 Übersicht

GymBo unterstützt jetzt **3 Trainingsarten**:

1. **Standard Training** - Klassisches sequentielles Training (Übung für Übung)
2. **Superset Training** - Paarweise Übungen ohne Pause (A1→A2, B1→B2)
3. **Circuit Training** - Mehrere Stationen in Rotation (A→B→C→D→E)

---

## 🏋️ Superset Training

### Was ist Superset Training?

Zwei Übungen werden **abwechselnd ohne Pause** ausgeführt:

```
Runde 1: A1 (Bankdrücken) → A2 (Klimmzüge) → Pause
Runde 2: A1 (Bankdrücken) → A2 (Klimmzüge) → Pause
Runde 3: A1 (Bankdrücken) → A2 (Klimmzüge) → Pause

Dann weiter zu B1/B2 ...
```

### Vorteile

- ⏱️ **Zeitersparnis** - Mehr Volumen in kürzerer Zeit
- 💪 **Intensität** - Kaum Pause zwischen Übungen
- 🎯 **Effizienz** - Ideal für antagonistische Muskelgruppen
- 🔥 **Metabolischer Stress** - Höherer Kalorienverbrauch

### Beispiele für Superset-Paare

**Antagonistische Muskelgruppen** (Push/Pull):
- Bankdrücken (Brust) + Klimmzüge (Rücken)
- Bizeps Curls (Bizeps) + Trizeps Dips (Trizeps)
- Schulterdrücken (Vordere Schulter) + Face Pulls (Hintere Schulter)

**Agonistische Muskelgruppen** (gleiche Muskelgruppe):
- Kniebeugen (Quads) + Beinpresse (Quads)
- Schrägbankdrücken (Brust) + Fliegende (Brust)

### Wie erstelle ich ein Superset-Workout?

#### Option 1: Programmatisch (für Developer)

```swift
// 1. Erstelle zwei Übungen
let exercise1 = WorkoutExercise(
    id: UUID(),
    exerciseId: benchPressID,
    targetSets: 3,
    targetReps: 10,
    targetWeight: 80.0,
    orderIndex: 0
)

let exercise2 = WorkoutExercise(
    id: UUID(),
    exerciseId: pullUpID,
    targetSets: 3,  // MUSS gleich sein!
    targetReps: 8,
    targetWeight: 0.0,
    orderIndex: 1
)

// 2. Erstelle eine ExerciseGroup (Superset-Paar)
let supersetGroup = ExerciseGroup(
    id: UUID(),
    exercises: [exercise1, exercise2],  // Genau 2 Übungen!
    groupIndex: 0,
    restAfterGroup: 120  // 2 Minuten Pause nach vollständiger Runde
)

// 3. Erstelle das Workout
let workout = try await createSupersetWorkoutUseCase.execute(
    name: "Upper Body Superset",
    defaultRestTime: 90,
    exerciseGroups: [supersetGroup]
)
```

#### Option 2: In der App (UI - geplant)

> **TODO:** UI für Superset-Erstellung muss noch implementiert werden!
> Aktuell können Supersets nur programmatisch erstellt werden.

**Geplanter Workflow:**
1. Workout erstellen → "Superset Training" auswählen
2. "Superset-Gruppe hinzufügen"
3. 2 Übungen auswählen (A1, A2)
4. Rundenanzahl festlegen (z.B. 3 Runden)
5. Pausenzeit nach Gruppe festlegen (z.B. 120 Sekunden)
6. Weitere Superset-Gruppen hinzufügen (B1/B2, C1/C2, ...)

### Wie nutze ich ein Superset-Workout?

1. **Workout starten** - App erkennt automatisch Superset-Typ
2. **SupersetWorkoutView öffnet sich** mit spezieller UI
3. **Superset-Gruppen-Karten** zeigen A1/A2 paarweise
4. **Runden-Tracking** - "Runde 1/3" Anzeige
5. **Sets abhaken** - A1 Set 1 → A2 Set 1 → Pause
6. **Automatischer Timer** - Pausenzeit nach jeder Runde
7. **Workout Complete** - Nachricht wenn alle Gruppen fertig

### UI Features

- ✅ **Timer-Sektion** - Rest Timer + Workout Duration
- ✅ **Gruppe 1/4 Anzeige** - Aktueller Fortschritt in Navigation
- ✅ **SupersetGroupCard** - Spezielle Karten für A1/A2 Paare
- ✅ **Runden-Fortschritt** - "Runde 2/3" pro Gruppe
- ✅ **Set-Completion** - Checkbox für jedes Set
- ✅ **Weight/Reps Anpassung** - Inline während Training
- ✅ **Success Pills** - Feedback-Nachrichten
- ✅ **Workout Complete Message** - Abschluss-Nachricht

### Business Rules

- ✅ **Genau 2 Übungen** pro Superset-Gruppe
- ✅ **Gleiche Rundenanzahl** - Beide Übungen müssen gleiche `targetSets` haben
- ✅ **Mindestens 1 Gruppe** - Workout muss mind. 1 Superset-Gruppe haben
- ✅ **Default Rest Time** - 90 Sekunden zwischen Sets
- ✅ **Default Rest After Group** - 120 Sekunden nach vollständiger Runde

---

## 🔄 Circuit Training

### Was ist Circuit Training?

Mehrere Stationen (3+) werden **in Rotation** ohne Pause absolviert:

```
Runde 1: A (Kniebeugen) → B (Push-ups) → C (Rows) → D (Lunges) → E (Plank) → Pause
Runde 2: A → B → C → D → E → Pause
Runde 3: A → B → C → D → E → Pause
```

### Vorteile

- 🔥 **Hohe Intensität** - Minimale Pausen
- ⏱️ **Zeiteffizient** - Viel Volumen in kurzer Zeit
- ❤️ **Kardio-Effekt** - Erhöhte Herzfrequenz
- 💪 **Ganzkörper-Training** - Alle Muskelgruppen in einer Session
- 🎯 **Functional Fitness** - Realistische Bewegungsmuster

### Beispiele für Circuits

**Full Body Circuit** (5 Stationen):
1. Kniebeugen (Beine)
2. Push-ups (Brust/Trizeps)
3. Bent-Over Rows (Rücken)
4. Lunges (Beine)
5. Plank (Core)

**Upper Body Circuit** (4 Stationen):
1. Bankdrücken (Brust)
2. Klimmzüge (Rücken)
3. Schulterdrücken (Schultern)
4. Bizeps Curls (Bizeps)

**HIIT Circuit** (6 Stationen):
1. Burpees
2. Mountain Climbers
3. Jump Squats
4. Push-ups
5. High Knees
6. Plank Jacks

### Wie erstelle ich ein Circuit-Workout?

#### Option 1: Programmatisch (für Developer)

```swift
// 1. Erstelle mehrere Übungen (3+)
let squats = WorkoutExercise(
    id: UUID(),
    exerciseId: squatID,
    targetSets: 3,  // 3 Runden
    targetReps: 15,
    targetWeight: 60.0,
    orderIndex: 0
)

let pushups = WorkoutExercise(
    id: UUID(),
    exerciseId: pushupID,
    targetSets: 3,  // MUSS gleich sein!
    targetReps: 15,
    targetWeight: 0.0,
    orderIndex: 1
)

let rows = WorkoutExercise(
    id: UUID(),
    exerciseId: rowID,
    targetSets: 3,  // MUSS gleich sein!
    targetReps: 12,
    targetWeight: 50.0,
    orderIndex: 2
)

let lunges = WorkoutExercise(
    id: UUID(),
    exerciseId: lungeID,
    targetSets: 3,  // MUSS gleich sein!
    targetReps: 20,
    targetWeight: 0.0,
    orderIndex: 3
)

let plank = WorkoutExercise(
    id: UUID(),
    exerciseId: plankID,
    targetSets: 3,  // MUSS gleich sein!
    isTimeBased: true,
    targetTime: 60,  // 60 Sekunden
    orderIndex: 4
)

// 2. Erstelle eine ExerciseGroup (Circuit-Stationen)
let circuitGroup = ExerciseGroup(
    id: UUID(),
    exercises: [squats, pushups, rows, lunges, plank],  // 3+ Übungen!
    groupIndex: 0,
    restAfterGroup: 180  // 3 Minuten Pause nach vollständiger Runde
)

// 3. Erstelle das Workout
let workout = try await createCircuitWorkoutUseCase.execute(
    name: "Full Body Circuit",
    defaultRestTime: 30,  // Kürzer für Circuits!
    exerciseGroups: [circuitGroup]
)
```

#### Option 2: In der App (UI - geplant)

> **TODO:** UI für Circuit-Erstellung muss noch implementiert werden!
> Aktuell können Circuits nur programmatisch erstellt werden.

**Geplanter Workflow:**
1. Workout erstellen → "Circuit Training" auswählen
2. "Circuit-Gruppe hinzufügen"
3. 3+ Übungen auswählen (Station A, B, C, D, E, ...)
4. Rundenanzahl festlegen (z.B. 3 Runden)
5. Pausenzeit zwischen Stationen (z.B. 30 Sek)
6. Pausenzeit nach Runde (z.B. 180 Sek)
7. Weitere Circuits hinzufügen (optional)

### Wie nutze ich ein Circuit-Workout?

1. **Workout starten** - App erkennt automatisch Circuit-Typ
2. **CircuitWorkoutView öffnet sich** mit spezieller UI
3. **Circuit-Gruppen-Karten** zeigen alle Stationen (A-E)
4. **Station-Rotation** - Aktuelle Station wird hervorgehoben
5. **Sets abhaken** - Station A → B → C → D → E → Pause
6. **Manueller "Nächste Runde"-Button** - Optional zum Überspringen
7. **Automatischer Timer** - Pausenzeit nach jeder Runde
8. **Workout Complete** - Nachricht wenn alle Runden fertig

### UI Features

- ✅ **Timer-Sektion** - Rest Timer + Workout Duration
- ✅ **Circuit 1/3 Anzeige** - Aktueller Fortschritt in Navigation
- ✅ **CircuitGroupCard** - Spezielle Karten für Station-Rotation
- ✅ **Station-Overview** - Alle Stationen sichtbar mit aktuellem Fokus
- ✅ **Runden-Fortschritt** - "Runde 2/3" pro Circuit
- ✅ **Set-Completion** - Checkbox für jede Station
- ✅ **Weight/Reps Anpassung** - Inline während Training
- ✅ **"Nächste Runde"-Button** - Manuelles Weiterspringen
- ✅ **Success Pills** - Feedback-Nachrichten
- ✅ **Workout Complete Message** - Abschluss-Nachricht

### Business Rules

- ✅ **Mindestens 3 Übungen** pro Circuit-Gruppe
- ✅ **Gleiche Rundenanzahl** - Alle Übungen müssen gleiche `targetSets` haben
- ✅ **Mindestens 1 Gruppe** - Workout muss mind. 1 Circuit-Gruppe haben
- ✅ **Default Rest Time** - 30 Sekunden zwischen Stationen (kürzer als Standard!)
- ✅ **Default Rest After Circuit** - 180 Sekunden (3 Minuten) nach vollständiger Runde

---

## 🏗️ Architektur-Details

### Domain Layer

**Neue Entities:**
- `WorkoutType` Enum - `.standard`, `.superset`, `.circuit`
- `ExerciseGroup` - Gruppiert Übungen für Superset/Circuit
- `SessionExerciseGroup` - Runtime-Version mit `currentRound`/`totalRounds`

**Neue Use Cases:**
- `CreateSupersetWorkoutUseCase` - Erstellt Superset-Workout
- `CreateCircuitWorkoutUseCase` - Erstellt Circuit-Workout
- `StartGroupedWorkoutSessionUseCase` - Startet Superset/Circuit Session
- `CompleteGroupSetUseCase` - Markiert Set in Gruppe als abgeschlossen
- `AdvanceToNextRoundUseCase` - Springt zur nächsten Runde (Circuit)

### Presentation Layer

**Neue Views:**
- `SupersetWorkoutView` - Haupt-View für Superset-Sessions
- `CircuitWorkoutView` - Haupt-View für Circuit-Sessions
- `SupersetGroupCard` - Karte für Superset-Paare (A1/A2)
- `CircuitGroupCard` - Karte für Circuit-Stationen (A-E)

### Data Layer

**Schema V6** (Migration V5→V6):
- `WorkoutEntity.workoutType: String` - Speichert Workout-Typ
- `ExerciseGroupEntity` - SwiftData-Entity für Exercise Groups
- `SessionExerciseGroupEntity` - SwiftData-Entity für Session Groups

**Neue Mappers:**
- `ExerciseGroupMapper` - Domain ↔ Entity für Exercise Groups
- `SessionExerciseGroupMapper` - Domain ↔ Entity für Session Groups

---

## 🧪 Testing

### Unit Tests (Domain Layer)

```swift
// CreateSupersetWorkoutUseCase Tests
✅ Successful creation with valid data
✅ Throws error for empty workout name
✅ Throws error for invalid rest time
✅ Throws error for empty exercise groups
✅ Throws error for groups with != 2 exercises
✅ Throws error for inconsistent rounds

// CreateCircuitWorkoutUseCase Tests
✅ Successful creation with valid data
✅ Throws error for groups with < 3 exercises
✅ Validates consistent rounds across all exercises
```

### Integration Tests

> **TODO:** Integration Tests müssen noch geschrieben werden!

**Geplante Tests:**
- Start Superset Session → Verify SupersetWorkoutView
- Complete Superset Round → Verify round progression
- Start Circuit Session → Verify CircuitWorkoutView
- Advance to next circuit round → Verify state update

---

## 📊 Vergleich: Standard vs Superset vs Circuit

| Feature | Standard | Superset | Circuit |
|---------|----------|----------|---------|
| **Übungen pro Gruppe** | 1 | 2 | 3+ |
| **Rest zwischen Sets** | 90s | 90s | 30s |
| **Rest nach Gruppe** | - | 120s | 180s |
| **Trainingszeit** | Lang | Mittel | Kurz |
| **Intensität** | Mittel | Hoch | Sehr hoch |
| **Kardio-Effekt** | Niedrig | Mittel | Hoch |
| **Ideal für** | Hypertrophie | Zeitersparnis | Kondition |

---

## 🚀 Roadmap: Geplante Features

### Phase 1: UI für Workout-Erstellung ⏳

**Status:** 🟡 Geplant (High Priority)

- [ ] **SupersetWorkoutCreationView** - UI zum Erstellen von Superset-Workouts
- [ ] **CircuitWorkoutCreationView** - UI zum Erstellen von Circuit-Workouts
- [ ] **ExerciseGroupBuilder** - Komponente zum Hinzufügen/Bearbeiten von Gruppen
- [ ] **WorkoutTypePickerSheet** - Sheet zur Auswahl von Standard/Superset/Circuit

**Geschätzter Aufwand:** 6-8 Stunden

### Phase 2: Erweiterte Circuit Features ⏳

**Status:** 🟢 Nice-to-Have (Low Priority)

- [ ] **EMOM (Every Minute On the Minute)** - Zeitbasierte Circuits
- [ ] **AMRAP (As Many Reps As Possible)** - Max-Reps-Tracking
- [ ] **Tabata Timer** - 20s Work / 10s Rest Intervals
- [ ] **Custom Circuit Templates** - Vordefinierte Circuit-Vorlagen

**Geschätzter Aufwand:** 8-10 Stunden

### Phase 3: Analytics & Progression ⏳

**Status:** 🟢 Nice-to-Have (Low Priority)

- [ ] **Circuit Performance Tracking** - Runden-Zeiten, Total Volume
- [ ] **Superset Progression** - Automatische Gewichtssteigerung pro Gruppe
- [ ] **Circuit Leaderboards** - Zeit-Vergleiche (optional)
- [ ] **Rest Time Optimization** - Vorschläge basierend auf Performance

**Geschätzter Aufwand:** 10-12 Stunden

---

## ❓ FAQ

### Kann ich Superset/Circuit-Workouts bearbeiten?

**Ja**, mit `UpdateWorkoutUseCase` - aber nur die gesamte `exerciseGroups`-Liste. Einzelne Gruppen-Edits müssen über die volle Liste erfolgen.

### Kann ich Standard-Workouts in Superset/Circuit umwandeln?

**Nein**, aktuell nicht. Du musst ein neues Workout erstellen. Migration ist geplant.

### Wie viele Superset-Gruppen kann ich haben?

**Unbegrenzt** - Du kannst beliebig viele Superset-Paare (A1/A2, B1/B2, C1/C2, ...) hinzufügen.

### Kann ein Workout mehrere Circuits haben?

**Ja** - Du kannst mehrere Circuit-Gruppen in einem Workout haben (Circuit 1, Circuit 2, ...).

### Was passiert, wenn ich eine Übung in einer Gruppe lösche?

**Validation schlägt fehl** - Supersets müssen genau 2, Circuits mindestens 3 Übungen haben. Du musst die Gruppe neu erstellen.

### Kann ich die Rundenanzahl während des Trainings ändern?

**Nein**, aktuell nicht. Die Rundenanzahl (`totalRounds`) wird beim Start der Session fixiert.

### Werden Superset/Circuit-Workouts in der Session History angezeigt?

**Ja** - Sie werden genauso wie Standard-Sessions in der History gespeichert und angezeigt.

---

## 📚 Weiterführende Dokumentation

- **[TECHNICAL_CONCEPT_V2.md](../../TECHNICAL_CONCEPT_V2.md)** - Clean Architecture Details
- **[TODO.md](../../TODO.md)** - Feature Roadmap
- **[CURRENT_STATE.md](../../CURRENT_STATE.md)** - Aktueller Implementierungsstatus
- **[SWIFTDATA_MIGRATION_STRATEGY.md](../../SWIFTDATA_MIGRATION_STRATEGY.md)** - Schema V6 Migration

---

**Letzte Aktualisierung:** 2025-10-31
**Version:** GymBo v2.6.0
**Autor:** Claude Code (Session 34)
