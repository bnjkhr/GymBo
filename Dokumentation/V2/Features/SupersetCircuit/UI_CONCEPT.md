# Superset & Circuit Training - UI Konzept

**Status:** 📝 Konzept zur Diskussion
**Erstellt:** 2025-10-31
**Backend Status:** ✅ Komplett implementiert
**Geschätzter Aufwand:** 6-8 Stunden

---

## 🎯 Ziel

Eine **intuitive, schrittweise UI** zur Erstellung von Superset- und Circuit-Workouts, die sich nahtlos in die existierende GymBo-App integriert.

---

## 📱 User Flow Overview

```
HomeView
  └─> Plus-Button (Workout erstellen)
       └─> WorkoutCreationModeSheet (NEU - erweitert)
            ├─> "Standard Workout" → CreateWorkoutView (existiert)
            ├─> "Quick-Setup" → QuickSetupView (existiert)
            ├─> "Superset Training" → CreateSupersetWorkoutView (NEU)
            └─> "Circuit Training" → CreateCircuitWorkoutView (NEU)
```

---

## 🏗️ Architektur-Übersicht

### Neue Komponenten

**1. WorkoutCreationModeSheet (Erweitern)**
- Füge 2 neue Buttons hinzu: "Superset" und "Circuit"

**2. CreateSupersetWorkoutView (NEU)**
- Wizard-Flow in 3 Schritten
- Step 1: Name & Rest Time
- Step 2: Superset-Gruppen erstellen
- Step 3: Preview & Save

**3. CreateCircuitWorkoutView (NEU)**
- Ähnlicher Wizard-Flow wie Superset
- Step 1: Name & Rest Time
- Step 2: Circuit-Gruppen erstellen
- Step 3: Preview & Save

**4. ExerciseGroupBuilder (NEU - Shared Component)**
- Wiederverwendbare Komponente für beide Workout-Typen
- Verwaltet eine einzelne Gruppe (A1/A2 oder A/B/C/D/E)

---

## 📐 Detailliertes UI-Design

### 1. WorkoutCreationModeSheet (Erweitert)

**Aktuell:** 3 Optionen (Standard, Quick-Setup, Leeres Workout)
**Neu:** 5 Optionen (+ Superset, + Circuit)

```swift
// Layout (Grid 2 Spalten)

[Standard Workout]    [Quick-Setup]
[Superset Training]   [Circuit Training]
[Leeres Workout]
```

**Neue Karten:**

**Superset Training:**
- Icon: 🏋️ (zwei Hanteln übereinander)
- Title: "Superset Training"
- Description: "Zwei Übungen abwechselnd"
- Badge: "NEU" (orange)

**Circuit Training:**
- Icon: 🔄 (Kreispfeil)
- Title: "Circuit Training"
- Description: "Mehrere Stationen in Rotation"
- Badge: "NEU" (orange)

---

### 2. CreateSupersetWorkoutView - Detailliert

**Navigation:** 3-Step Wizard mit Progress Indicator (ähnlich QuickSetupView)

#### **Step 1: Basis-Einstellungen**

```
┌──────────────────────────────────────┐
│  Superset Workout erstellen  [X]     │
├──────────────────────────────────────┤
│                                      │
│  Schritt 1 von 3                     │
│  ●────○────○                          │
│                                      │
│  NAME                                │
│  ┌────────────────────────────────┐  │
│  │ z.B. Upper Body Superset     │  │
│  └────────────────────────────────┘  │
│                                      │
│  PAUSENZEIT ZWISCHEN SETS            │
│  [30 Sek] [60 Sek] [✓90 Sek] [2 Min]│
│                                      │
│  PAUSENZEIT NACH SUPERSET            │
│  [60 Sek] [90 Sek] [✓120 Sek] [3 Min]│
│                                      │
│  ℹ️  Superset = 2 Übungen            │
│     abwechselnd ohne Pause           │
│                                      │
│              [Weiter →]               │
└──────────────────────────────────────┘
```

**Features:**
- Name TextField (auto-focus)
- Rest Time Buttons (zwischen Sets: 30/60/90/120s)
- Rest After Superset Buttons (nach Gruppe: 60/90/120/180s)
- Info-Box mit Erklärung
- "Weiter"-Button (disabled wenn Name leer)

---

#### **Step 2: Superset-Gruppen erstellen**

```
┌──────────────────────────────────────┐
│  Superset Workout erstellen  [X]     │
├──────────────────────────────────────┤
│                                      │
│  Schritt 2 von 3                     │
│  ○────●────○                          │
│                                      │
│  SUPERSET-GRUPPEN                    │
│                                      │
│  ┌─ Superset 1 ────────────────────┐ │
│  │ A1: Bankdrücken        [Ändern] │ │
│  │    3 Sätze × 10 Wdh × 80kg      │ │
│  │                                  │ │
│  │ A2: Klimmzüge          [Ändern] │ │
│  │    3 Sätze × 8 Wdh × 0kg        │ │
│  │                                  │ │
│  │ [🗑️ Gruppe löschen]              │ │
│  └──────────────────────────────────┘ │
│                                      │
│  ┌─ Superset 2 ────────────────────┐ │
│  │ A1: (Leer)             [+ Übung]│ │
│  │ A2: (Leer)             [+ Übung]│ │
│  └──────────────────────────────────┘ │
│                                      │
│  [+ Weiteres Superset hinzufügen]    │
│                                      │
│  [← Zurück]        [Weiter →]        │
└──────────────────────────────────────┘
```

**Features:**
- **Liste aller Superset-Gruppen**
- Jede Gruppe zeigt:
  - A1 Übung (Name, Sets, Reps, Weight)
  - A2 Übung (Name, Sets, Reps, Weight)
  - "Ändern"-Button → ExercisePickerSheet
  - "Gruppe löschen"-Button
- **"+ Weiteres Superset hinzufügen"** Button
- **Validation:**
  - Mind. 1 Superset-Gruppe erforderlich
  - Beide Übungen (A1 + A2) müssen ausgefüllt sein
  - Gleiche Rundenanzahl für A1 und A2 (automatisch synchronisiert)
- **"Weiter"-Button** disabled wenn Validation fehlschlägt

**Exercise Picker Integration:**
- Tap auf "Ändern" → ExercisePickerSheet öffnet
- User wählt Übung aus Library
- EditExerciseDetailsSheet öffnet:
  - Sets (Rundenanzahl): Stepper 1-10
  - Reps: Stepper 1-30
  - Weight: Number Input
  - Rest Time: Optional (erbt default)
  - **Info: "Sets = Runden für das gesamte Superset"**

---

#### **Step 3: Preview & Save**

```
┌──────────────────────────────────────┐
│  Superset Workout erstellen  [X]     │
├──────────────────────────────────────┤
│                                      │
│  Schritt 3 von 3                     │
│  ○────○────●                          │
│                                      │
│  VORSCHAU                            │
│                                      │
│  🏋️ Upper Body Superset              │
│  Pausenzeit: 90s zwischen Sets       │
│  Pausenzeit: 120s nach Superset      │
│                                      │
│  ┌─ Superset 1 (3 Runden) ─────────┐ │
│  │ A1: Bankdrücken                  │ │
│  │     3 × 10 Wdh × 80kg            │ │
│  │                                  │ │
│  │ A2: Klimmzüge                    │ │
│  │     3 × 8 Wdh × Körpergewicht    │ │
│  └──────────────────────────────────┘ │
│                                      │
│  ┌─ Superset 2 (4 Runden) ─────────┐ │
│  │ A1: Bizeps Curls                 │ │
│  │     4 × 12 Wdh × 15kg            │ │
│  │                                  │ │
│  │ A2: Trizeps Dips                 │ │
│  │     4 × 12 Wdh × Körpergewicht   │ │
│  └──────────────────────────────────┘ │
│                                      │
│  Gesamt: 2 Supersets, 14 Sätze      │
│                                      │
│  [← Zurück]     [✓ Erstellen]        │
└──────────────────────────────────────┘
```

**Features:**
- **Summary Card:**
  - Workout Name
  - Rest Times
  - Alle Superset-Gruppen mit Details
  - Gesamt-Statistik
- **"Erstellen"-Button:**
  - Validiert alle Eingaben
  - Ruft `CreateSupersetWorkoutUseCase` auf
  - Zeigt Loading-State
  - Success → Navigiert zu WorkoutDetailView
  - Error → Zeigt Alert

---

### 3. CreateCircuitWorkoutView - Detailliert

**Sehr ähnlich zu Superset, aber mit Unterschieden:**

#### **Step 1: Basis-Einstellungen**

```
┌──────────────────────────────────────┐
│  Circuit Workout erstellen   [X]     │
├──────────────────────────────────────┤
│                                      │
│  Schritt 1 von 3                     │
│  ●────○────○                          │
│                                      │
│  NAME                                │
│  ┌────────────────────────────────┐  │
│  │ z.B. Full Body Circuit        │  │
│  └────────────────────────────────┘  │
│                                      │
│  PAUSENZEIT ZWISCHEN STATIONEN       │
│  [✓30 Sek] [45 Sek] [60 Sek] [90 Sek]│
│                                      │
│  PAUSENZEIT NACH RUNDE               │
│  [90 Sek] [120 Sek] [✓180 Sek] [4 Min]│
│                                      │
│  ℹ️  Circuit = 3+ Stationen          │
│     in Rotation                      │
│                                      │
│              [Weiter →]               │
└──────────────────────────────────────┘
```

**Unterschiede zu Superset:**
- **Kürze Rest Times zwischen Stationen:** 30/45/60/90s (default: 30s)
- **Längere Rest Times nach Runde:** 90/120/180/240s (default: 180s)
- Info-Text angepasst

---

#### **Step 2: Circuit-Stationen erstellen**

```
┌──────────────────────────────────────┐
│  Circuit Workout erstellen   [X]     │
├──────────────────────────────────────┤
│                                      │
│  Schritt 2 von 3                     │
│  ○────●────○                          │
│                                      │
│  CIRCUIT-GRUPPEN                     │
│                                      │
│  ┌─ Circuit 1 (3 Runden) ──────────┐ │
│  │ Station A: Kniebeugen  [Ändern] │ │
│  │    3 × 15 Wdh × 60kg             │ │
│  │                                  │ │
│  │ Station B: Push-ups    [Ändern] │ │
│  │    3 × 15 Wdh × 0kg              │ │
│  │                                  │ │
│  │ Station C: Rows        [Ändern] │ │
│  │    3 × 12 Wdh × 50kg             │ │
│  │                                  │ │
│  │ [+ Station hinzufügen]           │ │
│  │ [🗑️ Circuit löschen]             │ │
│  └──────────────────────────────────┘ │
│                                      │
│  [+ Weiteren Circuit hinzufügen]     │
│                                      │
│  ⚠️  Mindestens 3 Stationen pro      │
│      Circuit erforderlich            │
│                                      │
│  [← Zurück]        [Weiter →]        │
└──────────────────────────────────────┘
```

**Unterschiede zu Superset:**
- **Minimum 3 Stationen** statt 2 Übungen
- **"+ Station hinzufügen"** Button pro Circuit
- **Stations-Label:** "Station A/B/C/D/E..." statt "A1/A2"
- **Validation:**
  - Mind. 1 Circuit erforderlich
  - Mind. 3 Stationen pro Circuit
  - Alle Stationen müssen gleiche Rundenanzahl haben

---

### 4. ExerciseGroupBuilder (Shared Component)

**Zweck:** Wiederverwendbare Komponente für das Erstellen/Bearbeiten von Exercise Groups

```swift
struct ExerciseGroupBuilder: View {
    // Input
    let groupType: GroupType  // .superset oder .circuit
    let groupIndex: Int

    // Bindings
    @Binding var group: ExerciseGroup

    // Callbacks
    let onAddExercise: () -> Void
    let onEditExercise: (UUID) -> Void
    let onDeleteExercise: (UUID) -> Void
    let onDeleteGroup: () -> Void

    var body: some View {
        // Implementation...
    }
}

enum GroupType {
    case superset  // Exactly 2 exercises
    case circuit   // 3+ exercises
}
```

**Features:**
- Adaptiert sich an `GroupType` (Superset vs Circuit)
- Zeigt Übungen in der Gruppe
- "Ändern"-Button für jede Übung
- "+ Übung hinzufügen" Button (nur Circuit)
- "Gruppe löschen" Button
- Validation (2 für Superset, 3+ für Circuit)

---

## 🎨 Design-System Integration

### Farben
- **Primary:** #F77E2D (GymBo Orange)
- **Background:** System Grouped Background
- **Cards:** Secondary System Grouped Background
- **Text:** Primary / Secondary

### Typography
- **Titles:** .title2, .bold
- **Section Headers:** .subheadline, .semibold, .secondary, .uppercase
- **Body:** .body
- **Buttons:** .headline

### Components
- **Buttons:** 12pt corner radius, padding 16pt
- **Cards:** 12pt corner radius, padding 16pt
- **TextFields:** .plain style, 12pt corner radius, padding 12pt
- **Progress Indicator:** 3 Circles (●○○)

### Icons
- **Superset:** SF Symbol "arrow.left.arrow.right" oder custom
- **Circuit:** SF Symbol "arrow.triangle.2.circlepath"
- **Add Exercise:** "plus.circle.fill"
- **Delete:** "trash"
- **Edit:** "pencil"
- **Info:** "info.circle.fill"

---

## 🔄 Data Flow

### CreateSupersetWorkoutView

```
User Input (Step 1-2)
    ↓
ExerciseGroup[] (Local State)
    ↓
Step 3: Preview & Validation
    ↓
CreateSupersetWorkoutUseCase.execute(
    name: String,
    defaultRestTime: TimeInterval,
    exerciseGroups: [ExerciseGroup]
)
    ↓
WorkoutStore refreshes
    ↓
Navigate to WorkoutDetailView
```

### State Management

```swift
@State private var workoutName: String = ""
@State private var defaultRestTime: TimeInterval = 90
@State private var restAfterGroup: TimeInterval = 120
@State private var exerciseGroups: [ExerciseGroup] = []
@State private var currentStep: Int = 1  // 1, 2, 3
@State private var isLoading: Bool = false
@State private var errorMessage: String? = nil
```

---

## ✅ Validation Rules

### Superset Workout
- ✅ Name nicht leer
- ✅ defaultRestTime > 0
- ✅ restAfterGroup > 0
- ✅ Mind. 1 ExerciseGroup
- ✅ Jede Group hat genau 2 Übungen
- ✅ Beide Übungen haben gleiche targetSets
- ✅ targetSets > 0

### Circuit Workout
- ✅ Name nicht leer
- ✅ defaultRestTime > 0
- ✅ restAfterGroup > 0
- ✅ Mind. 1 ExerciseGroup
- ✅ Jede Group hat mind. 3 Übungen
- ✅ Alle Übungen haben gleiche targetSets
- ✅ targetSets > 0

---

## 🧪 Edge Cases & Error Handling

### Edge Cases

**1. User verlässt Sheet während Step 2:**
- **Verhalten:** Confirmation Dialog
- **Optionen:** "Verwerfen" / "Zurück"

**2. User ändert Sets-Anzahl von A1:**
- **Verhalten:** A2 automatisch synchronisieren
- **Feedback:** Subtiler Animation/Highlight

**3. User versucht Gruppe mit nur 1 Übung zu erstellen:**
- **Verhalten:** "Weiter"-Button disabled
- **Feedback:** Validation-Nachricht unter Gruppe

**4. User löscht alle Übungen aus einer Gruppe:**
- **Verhalten:** Gruppe wird automatisch gelöscht

### Error Handling

**Netzwerk-Fehler / Repository-Fehler:**
```swift
.alert("Fehler beim Erstellen", isPresented: $showError) {
    Button("OK") { }
} message: {
    Text(errorMessage ?? "Unbekannter Fehler")
}
```

**Validation-Fehler:**
- Inline unter betroffener Komponente
- Disabled "Weiter"/"Erstellen" Button
- Rote Border + Icon

---

## 🚀 Implementation Plan

### Phase 1: Core Components (2-3 Std)

**Files to create:**
1. `CreateSupersetWorkoutView.swift`
2. `CreateCircuitWorkoutView.swift`
3. `ExerciseGroupBuilder.swift`
4. `EditExerciseInGroupSheet.swift`

**Files to modify:**
1. `WorkoutCreationModeSheet.swift` (2 neue Buttons)
2. `HomeView.swift` (State für neue Sheets)

### Phase 2: Logic & Validation (2-3 Std)

- Implement State Management
- Validation Logic
- Exercise Picker Integration
- Use Case Calls

### Phase 3: Polish & Testing (1-2 Std)

- Haptic Feedback
- Animations
- Error Handling
- Edge Cases
- Manual Testing

---

## 🎯 Success Criteria

**Must Have:**
- ✅ User kann Superset-Workout mit 1+ Gruppen erstellen
- ✅ User kann Circuit-Workout mit 1+ Gruppen erstellen
- ✅ Validation verhindert fehlerhafte Workouts
- ✅ UI ist intuitiv und selbsterklärend
- ✅ Integration mit existierenden Views nahtlos

**Nice to Have:**
- ✅ Drag & Drop zum Reordern von Übungen
- ✅ Templates (z.B. "Upper Body Superset")
- ✅ Preview Animation (wie sich das Workout anfühlt)
- ✅ Tips & Best Practices inline

---

## 💬 Diskussionspunkte

### 1. Wizard vs. Single View?

**Option A: 3-Step Wizard (vorgeschlagen)**
- ✅ Pro: Übersichtlich, schrittweise
- ✅ Pro: Nutzer wird nicht überfordert
- ❌ Con: Mehr Klicks

**Option B: Single Long Form**
- ✅ Pro: Alles auf einen Blick
- ❌ Con: Kann überwältigend sein
- ❌ Con: Viel Scrolling

**Empfehlung:** Wizard (konsistent mit QuickSetupView)

---

### 2. Exercise Picker: Neu oder Reuse?

**Option A: Reuse existierenden ExercisePickerView**
- ✅ Pro: Weniger Code
- ✅ Pro: Konsistenz
- ❌ Con: Eventuell nicht optimal für Groups

**Option B: Neuer GroupExercisePickerView**
- ✅ Pro: Spezialisiert auf Group-Kontext
- ✅ Pro: Kann mehr Info zeigen (z.B. "Sets = Runden")
- ❌ Con: Code-Duplikation

**Empfehlung:** Reuse + Small Wrapper

---

### 3. Rundenanzahl: Global oder per Übung?

**Option A: Global für gesamte Gruppe (vorgeschlagen)**
- ✅ Pro: Einfacher (1 Input statt N)
- ✅ Pro: Matches Business Logic (alle gleich)
- ✅ Pro: Weniger Fehlerquelle
- ❌ Con: Weniger Flexibilität

**Option B: Individuell pro Übung**
- ✅ Pro: Maximale Flexibilität
- ❌ Con: Komplexer
- ❌ Con: Validation komplizierter
- ❌ Con: Matching Backend-Constraint schwieriger

**Empfehlung:** Global + Auto-Sync

---

### 4. Preview Step: Notwendig?

**Option A: Mit Preview (vorgeschlagen)**
- ✅ Pro: User kann Review machen
- ✅ Pro: Verhindert Fehler
- ✅ Pro: "Bestätigung" vor Speichern

**Option B: Ohne Preview**
- ✅ Pro: Schneller
- ❌ Con: Kein Final Check
- ❌ Con: Mehr Fehler

**Empfehlung:** Mit Preview

---

### 5. Templates: Später oder jetzt?

**Templates = Vordefinierte Workouts**
- "Upper Body Superset" (Brust/Rücken)
- "Full Body Circuit" (5 Stationen)
- etc.

**Empfehlung:** Später (Phase 2 Feature)

---

## 📸 Mockup-Referenzen

**Ähnliche Apps für Inspiration:**
- Strong App (Superset Creation)
- JEFIT (Circuit Builder)
- Fitbod (Workout Builder)

**GymBo Existing Views:**
- QuickSetupView (Wizard-Flow)
- CreateWorkoutView (Form Design)
- WorkoutDetailView (Exercise List)

---

## ✨ Final Notes

**Design Philosophy:**
- **Progressiv Disclosure:** Nicht alles auf einmal zeigen
- **Guided Experience:** User wird durch Prozess geführt
- **Fehler vermeiden:** Validation inline, nicht erst am Ende
- **Konsistenz:** Passt zu existierender App

**Alternative Approach:**
Wenn Wizard zu komplex ist, könnten wir auch mit einem **"Add Superset Group"**-Button in der Standard-Create-Workout-View starten (ähnlich wie "Add Exercise"). Das wäre inkrementeller und weniger Breaking Change.

---

**Fragen für Diskussion:**
1. Wizard-Flow OK oder zu viele Steps?
2. Exercise Picker Reuse oder neu?
3. Rundenanzahl Global oder Individual?
4. Preview Step notwendig?
5. Alternativer Ansatz: Integration in existierende CreateWorkoutView?

**Nächste Schritte:**
Nach Feedback → Implementation starten! 🚀
