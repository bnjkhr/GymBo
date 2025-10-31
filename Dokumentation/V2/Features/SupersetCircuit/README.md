# Superset & Circuit Training Feature

**Status:** ✅ Backend Complete - UI Pending
**Version:** GymBo v2.6.0+ (Schema V6)
**Implemented:** Session 33 (2025-10-30)
**Documented:** Session 34 (2025-10-31)

---

## 📚 Dokumentation

- **[USER_GUIDE.md](./USER_GUIDE.md)** - Vollständiger User Guide
  - Was ist Superset/Circuit Training?
  - Wie erstelle & nutze ich diese Workouts?
  - Beispiele & Use Cases
  - Architektur-Details
  - FAQ

---

## ⚡ Quick Overview

### Superset Training
Zwei Übungen **abwechselnd ohne Pause** ausführen:
- Beispiel: A1 (Bankdrücken) → A2 (Klimmzüge) → Pause → Repeat
- Ideal für: Zeitersparnis, antagonistische Muskelgruppen
- UI: `SupersetWorkoutView` mit `SupersetGroupCard`

### Circuit Training
Mehrere Stationen **in Rotation** ohne Pause:
- Beispiel: A (Squat) → B (Pushup) → C (Row) → D (Lunge) → E (Plank) → Pause → Repeat
- Ideal für: Ganzkörper-Training, Kardio-Effekt, HIIT
- UI: `CircuitWorkoutView` mit `CircuitGroupCard`

---

## 🏗️ Architektur

**Domain Layer:**
- `WorkoutType` Enum (`.superset`, `.circuit`, `.standard`)
- `ExerciseGroup` - Gruppiert Übungen
- `SessionExerciseGroup` - Runtime mit Round-Tracking
- 5 neue Use Cases

**Data Layer:**
- Schema V6 (ExerciseGroupEntity, SessionExerciseGroupEntity)
- 2 neue Mappers (ExerciseGroupMapper, SessionExerciseGroupMapper)

**Presentation Layer:**
- `SupersetWorkoutView` + `SupersetGroupCard`
- `CircuitWorkoutView` + `CircuitGroupCard`

---

## ✅ Was funktioniert

- ✅ Backend komplett implementiert
- ✅ SupersetWorkoutView & CircuitWorkoutView
- ✅ Round-Tracking (currentRound/totalRounds)
- ✅ Set-Completion in Gruppen
- ✅ Rest Timer nach Gruppen
- ✅ Validation (2 exercises für Superset, 3+ für Circuit)

## ⏳ Was fehlt

- [ ] UI für Workout-Erstellung (aktuell nur programmatisch)
- [ ] SupersetWorkoutCreationView
- [ ] CircuitWorkoutCreationView
- [ ] ExerciseGroupBuilder Component

Siehe [TODO.md](../../TODO.md) für Roadmap.

---

## 📖 Weitere Dokumentation

- [TECHNICAL_CONCEPT_V2.md](../../TECHNICAL_CONCEPT_V2.md) - Clean Architecture
- [TODO.md](../../TODO.md) - Feature Roadmap
- [CURRENT_STATE.md](../../CURRENT_STATE.md) - Implementation Status

---

**Letzte Aktualisierung:** 2025-10-31
**Maintainer:** Ben Kohler
