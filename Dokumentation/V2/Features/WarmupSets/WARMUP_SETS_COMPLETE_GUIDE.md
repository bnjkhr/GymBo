# Warmup Sets - Vollständige Dokumentation & Architektur

**Version:** 1.0  
**Status:** Production Ready  
**Letzte Aktualisierung:** 2025-10-30

---

## Inhaltsverzeichnis

1. [Feature Übersicht](#1-feature-übersicht)
2. [Architektur & Design](#2-architektur--design)
3. [Implementierungsdetails](#3-implementierungsdetails)
4. [Kritische Architektur-Regeln](#4-kritische-architektur-regeln)
5. [Gelöste Bugs & Fixes](#5-gelöste-bugs--fixes)
6. [Testing](#6-testing)
7. [Bekannte Limitierungen](#7-bekannte-limitierungen)
8. [Maintenance & Erweiterungen](#8-maintenance--erweiterungen)

---

## 1. Feature Übersicht

### Was sind Warmup Sets?

Warmup Sets sind automatisch berechnete Aufwärmsätze, die vor den eigentlichen Arbeitssätzen ausgeführt werden. Sie helfen dem Nutzer, sich schrittweise an das Arbeitsgewicht heranzutasten und reduzieren das Verletzungsrisiko.

### Funktionsumfang

- **Automatische Berechnung** basierend auf dem Arbeitsgewicht
- **3 Strategien** mit unterschiedlich vielen Aufwärmsätzen:
  - Conservative: 3 Warmup-Sätze (50%, 70%, 85%)
  - Moderate: 2 Warmup-Sätze (60%, 80%)
  - Aggressive: 1 Warmup-Satz (70%)
- **Intelligente Gewichtsrundung** auf 2.5kg (Standard-Gewichtsscheiben)
- **Edge Case Handling** für niedrige Gewichte (< 10kg)
- **Rest Timer Integration** - Warmup-Sätze haben die gleiche Pausenzeit wie Arbeitssätze
- **HealthKit Integration** - Warmup-Sätze werden korrekt in HealthKit gespeichert
- **Statistik-Unterstützung** - Backend kann Warmup-Sätze ein-/ausschließen

### User Flow

1. Nutzer erstellt Workout-Plan mit Übungen
2. Nutzer startet Workout
3. System bietet Warmup-Strategie für jede Übung an
4. Nutzer wählt Strategie oder überspringt
5. System berechnet und fügt Warmup-Sätze hinzu
6. Nutzer führt Warmup-Sätze aus (mit Rest Timer)
7. Nutzer führt Arbeitssätze aus
8. System speichert alles persistent (inklusive HealthKit)

---

## 2. Architektur & Design

### 2.1 Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer               │
│  - SessionView.swift                     │
│  - CompactExerciseCard.swift             │
│  - WorkoutSetRow.swift                   │
│  - WarmupStrategySheet.swift             │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Domain Layer                     │
│  - SessionStore.swift (State)            │
│  - StartSessionUseCase.swift             │
│  - CompleteSetUseCase.swift              │
│  - AddSetUseCase.swift                   │
│  - RemoveSetUseCase.swift                │
│  - WarmupCalculator.swift (Pure Logic)   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Data Layer                       │
│  - SessionRepository.swift               │
│  - SessionMapper.swift                   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Infrastructure Layer             │
│  - SwiftData (Schema V5)                 │
│  - HealthKit Integration                 │
└─────────────────────────────────────────┘
```

### 2.2 Domain Model

#### DomainSessionSet

```swift
struct DomainSessionSet: Identifiable, Codable {
    let id: UUID
    var weight: Double
    var reps: Int
    var completed: Bool
    var restTime: Int?
    var orderIndex: Int        // ⚠️ NUR für Sortierung!
    var isWarmup: Bool         // ⚠️ Primäres Flag für Logik!
    var completedAt: Date?
    
    // Neue Properties in Schema V5
    var targetWeight: Double?
    var targetReps: Int?
}
```

**Wichtige Konzepte:**

- `isWarmup`: **Primäres Flag** für alle Logik (Filterung, Gruppierung, etc.)
- `orderIndex`: **NUR für Display-Sortierung**, niemals für Logik verwenden!
- `restTime`: Wird von Arbeitssätzen kopiert (nicht nil für Warmup)
- `completed`: Boolean, wird durch CompleteSetUseCase getoggled

### 2.3 State Management

**SwiftUI @Observable Pattern (iOS 17+)**

```swift
@Observable
class SessionStore {
    var currentSession: DomainSession?  // ⚠️ Optional triggert SwiftUI updates
    
    // Optimistic UI Update Pattern
    func completeSet(exerciseId: UUID, setId: UUID) async {
        // 1. Sofort UI updaten (Optimistic)
        var currentCompletedState = false
        if let exercise = currentSession?.exercises.first(where: { $0.id == exerciseId }),
           let set = exercise.sets.first(where: { $0.id == setId }) {
            currentCompletedState = set.completed
        }
        let newCompletedState = !currentCompletedState
        updateLocalSet(exerciseId: exerciseId, setId: setId, completed: newCompletedState)
        
        // 2. Async Use Case ausführen
        await completeSetUseCase.execute(exerciseId: exerciseId, setId: setId)
        
        // 3. Von DB refreshen
        await refreshCurrentSession()
    }
}
```

**Force Refresh Pattern:**

```swift
private func updateLocalSet(exerciseId: UUID, setId: UUID, completed: Bool) {
    guard var session = currentSession else { return }
    
    // Modify session...
    
    // ⚠️ Force SwiftUI update für nested structs
    currentSession = nil
    currentSession = session
}
```

### 2.4 Batch Operations (Race Condition Prevention)

**Problem:** Iteratives Hinzufügen von Warmup-Sätzen führte zu Race Conditions:

```swift
// ❌ FALSCH: Race Condition!
for (exerciseId, warmupSets) in warmupData {
    await sessionStore.addWarmupSets(exerciseId, warmupSets)
    // ^ Jeder Call: modify -> save DB -> refresh DB
    // Concurrent modifications!
}
```

**Lösung:** Batch Operation mit Single DB Write

```swift
// ✅ RICHTIG: Batch Operation
func addWarmupSetsBatch(_ warmupData: [UUID: [WarmupCalculator.WarmupSet]]) async {
    // 1. Capture all data FIRST (sync)
    guard var session = currentSession else { return }
    
    // 2. Process ALL exercises in memory
    for (exerciseId, warmupSets) in warmupData {
        // Modify session object...
    }
    
    // 3. Single DB write
    do {
        try await sessionRepository.update(session)
    }
    
    // 4. Single UI refresh
    await refreshCurrentSession()
}
```

### 2.5 HealthKit Integration

**Problem:** HealthKit Task captured stale session copy

```swift
// ❌ FALSCH: Stale copy
Task {
    let healthKitId = try await healthKitService.startWorkout()
    session.healthKitSessionId = healthKitId  // ⚠️ session is OLD!
    try await repository.update(session)      // ⚠️ Overwrites warmup sets!
}
```

**Lösung:** Fetch current session from DB

```swift
// ✅ RICHTIG: Fetch current
Task {
    let healthKitId = try await healthKitService.startWorkout()
    
    // Fetch CURRENT session from DB
    guard var currentSession = try await repository.fetch(id: session.id) else {
        return
    }
    currentSession.healthKitSessionId = healthKitId
    try await repository.update(currentSession)
}
```

---

## 3. Implementierungsdetails

### 3.1 WarmupCalculator (Pure Logic)

**Strategie-Definitionen:**

```swift
enum WarmupStrategy: String, CaseIterable, Codable {
    case conservative  // 3 sets: 50%, 70%, 85%
    case moderate      // 2 sets: 60%, 80%
    case aggressive    // 1 set:  70%
}
```

**Berechnungslogik:**

```swift
static func calculateWarmupSets(
    workingWeight: Double,
    workingReps: Int,
    strategy: WarmupStrategy
) -> [WarmupSet] {
    // ⚠️ Edge Case: Keine Warmups für sehr leichte Gewichte
    guard workingWeight >= 10.0 else {
        return []
    }
    
    let percentages = getPercentages(for: strategy)
    
    return percentages.compactMap { percentage in
        let calculatedWeight = workingWeight * percentage
        let roundedWeight = round(calculatedWeight / 2.5) * 2.5
        
        // ⚠️ Skip sets zu nah am Arbeitsgewicht oder unter Minimum
        guard roundedWeight >= 2.5 && roundedWeight < workingWeight else {
            return nil
        }
        
        let reps = calculateWarmupReps(percentage: percentage, workingReps: workingReps)
        return WarmupSet(weight: roundedWeight, reps: reps, percentageOfMax: percentage)
    }
}
```

**Wiederholungsberechnung:**

```swift
private static func calculateWarmupReps(percentage: Double, workingReps: Int) -> Int {
    switch percentage {
    case 0..<0.6:   return min(workingReps + 2, 10)  // Leicht: mehr Wiederholungen
    case 0.6..<0.8: return max(workingReps - 1, 5)   // Mittel: weniger Wiederholungen
    default:        return max(workingReps - 2, 3)   // Schwer: deutlich weniger
    }
}
```

### 3.2 SessionStore - Warmup Creation

**Single Exercise Warmup:**

```swift
func addWarmupSets(exerciseId: UUID, _ warmupSets: [WarmupCalculator.WarmupSet]) async {
    guard var session = currentSession else { return }
    
    guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else {
        return
    }
    
    var exercise = session.exercises[exerciseIndex]
    
    // ⚠️ Duplicate Prevention
    if exercise.sets.contains(where: { $0.isWarmup }) {
        print("⚠️ Warmup sets already exist. Skipping.")
        return
    }
    
    // ⚠️ Copy restTime from working sets
    let workingSetRestTime = exercise.sets.first(where: { !$0.isWarmup })?.restTime
    
    // Create warmup sets
    let newSets = warmupSets.enumerated().map { index, warmupSet in
        DomainSessionSet(
            weight: warmupSet.weight,
            reps: warmupSet.reps,
            completed: false,
            restTime: workingSetRestTime,  // ✅ Has rest time
            orderIndex: index,             // ✅ Sequential from 0
            isWarmup: true,                // ✅ Flag set
            targetWeight: warmupSet.weight,
            targetReps: warmupSet.reps
        )
    }
    
    // ⚠️ Shift orderIndex of existing working sets
    var workingSets = exercise.sets.filter { !$0.isWarmup }
    let warmupCount = newSets.count
    for i in 0..<workingSets.count {
        workingSets[i].orderIndex += warmupCount
    }
    
    // Combine: warmup + working
    exercise.sets = newSets + workingSets
    session.exercises[exerciseIndex] = exercise
    
    // Save to DB
    do {
        try await sessionRepository.update(session)
        await refreshCurrentSession()
    }
}
```

**Batch Warmup (Race Condition Safe):**

```swift
func addWarmupSetsBatch(_ warmupData: [UUID: [WarmupCalculator.WarmupSet]]) async {
    guard var session = currentSession else { return }
    
    // ⚠️ Capture all data FIRST (before any async operations)
    for (exerciseId, warmupSets) in warmupData {
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else {
            continue
        }
        
        var exercise = session.exercises[exerciseIndex]
        
        // Duplicate prevention
        if exercise.sets.contains(where: { $0.isWarmup }) {
            continue
        }
        
        let workingSetRestTime = exercise.sets.first(where: { !$0.isWarmup })?.restTime
        
        let newSets = warmupSets.enumerated().map { index, warmupSet in
            DomainSessionSet(
                weight: warmupSet.weight,
                reps: warmupSet.reps,
                completed: false,
                restTime: workingSetRestTime,
                orderIndex: index,
                isWarmup: true,
                targetWeight: warmupSet.weight,
                targetReps: warmupSet.reps
            )
        }
        
        var workingSets = exercise.sets.filter { !$0.isWarmup }
        let warmupCount = newSets.count
        for i in 0..<workingSets.count {
            workingSets[i].orderIndex += warmupCount
        }
        
        exercise.sets = newSets + workingSets
        session.exercises[exerciseIndex] = exercise
    }
    
    // ⚠️ Single DB write for ALL exercises
    do {
        try await sessionRepository.update(session)
    }
    
    // ⚠️ Single UI refresh
    await refreshCurrentSession()
}
```

### 3.3 AddSetUseCase - OrderIndex Management

```swift
func execute(exerciseId: UUID, weight: Double?, reps: Int?) async throws {
    guard var session = try await sessionRepository.fetch(id: sessionId) else {
        throw SessionError.sessionNotFound
    }
    
    guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else {
        throw SessionError.exerciseNotFound
    }
    
    // ⚠️ CRITICAL: Use MAX orderIndex, not array count!
    let maxOrderIndex = session.exercises[exerciseIndex].sets.map { $0.orderIndex }.max() ?? -1
    
    let finalWeight = weight ?? session.exercises[exerciseIndex].sets.last?.weight ?? 0.0
    let finalReps = reps ?? session.exercises[exerciseIndex].sets.last?.reps ?? 0
    
    let newSet = DomainSessionSet(
        weight: finalWeight,
        reps: finalReps,
        completed: false,
        restTime: session.exercises[exerciseIndex].sets.last?.restTime,
        orderIndex: maxOrderIndex + 1,  // ✅ Always at end
        isWarmup: false,                // ✅ New sets are always working sets
        targetWeight: finalWeight,
        targetReps: finalReps
    )
    
    session.exercises[exerciseIndex].sets.append(newSet)
    try await sessionRepository.update(session)
}
```

### 3.4 RemoveSetUseCase - Reindexing

```swift
func execute(exerciseId: UUID, setId: UUID) async throws {
    guard var session = try await sessionRepository.fetch(id: sessionId) else {
        throw SessionError.sessionNotFound
    }
    
    guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else {
        throw SessionError.exerciseNotFound
    }
    
    guard let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) else {
        throw SessionError.setNotFound
    }
    
    // Remove set
    session.exercises[exerciseIndex].sets.remove(at: setIndex)
    
    // ⚠️ CRITICAL: Re-index remaining sets
    session.exercises[exerciseIndex].sets.sort { $0.orderIndex < $1.orderIndex }
    for (newIndex, _) in session.exercises[exerciseIndex].sets.enumerated() {
        session.exercises[exerciseIndex].sets[newIndex].orderIndex = newIndex
    }
    
    try await sessionRepository.update(session)
}
```

### 3.5 CompleteSetUseCase - Toggle Logic

```swift
func execute(exerciseId: UUID, setId: UUID) async throws {
    guard var session = try await sessionRepository.fetch(id: sessionId) else {
        throw SessionError.sessionNotFound
    }
    
    guard let exerciseIndex = session.exercises.firstIndex(where: { $0.id == exerciseId }) else {
        throw SessionError.exerciseNotFound
    }
    
    guard let setIndex = session.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setId }) else {
        throw SessionError.setNotFound
    }
    
    // ⚠️ TOGGLE completion state
    session.exercises[exerciseIndex].sets[setIndex].completed.toggle()
    
    // Set timestamp
    if session.exercises[exerciseIndex].sets[setIndex].completed {
        session.exercises[exerciseIndex].sets[setIndex].completedAt = Date()
    } else {
        session.exercises[exerciseIndex].sets[setIndex].completedAt = nil
    }
    
    try await sessionRepository.update(session)
}
```

---

## 4. Kritische Architektur-Regeln

### ⚠️ MANDATORY RULES - MUST BE FOLLOWED

#### Regel 1: isWarmup ist Primary Flag

**ALWAYS:**
```swift
// ✅ Warmup-Sets filtern
let warmupSets = exercise.sets.filter { $0.isWarmup }
let workingSets = exercise.sets.filter { !$0.isWarmup }

// ✅ Warmup-Sets zählen
let warmupCount = exercise.sets.filter { $0.isWarmup }.count

// ✅ Check ob Warmups existieren
if exercise.sets.contains(where: { $0.isWarmup }) {
    // Duplicate prevention
}
```

**NEVER:**
```swift
// ❌ FALSCH: Annahme dass Warmups niedrigere Indizes haben
let warmupSets = exercise.sets.filter { $0.orderIndex < 3 }

// ❌ FALSCH: Implizite orderIndex-Logik
let workingSets = exercise.sets.filter { $0.orderIndex >= warmupCount }
```

**Begründung:** `orderIndex` kann durch Set-Deletion/Reindexing sich ändern. `isWarmup` ist immutable nach Creation.

#### Regel 2: orderIndex NUR für Display

**ALWAYS:**
```swift
// ✅ Für UI Sortierung
let sortedSets = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }

// ✅ ForEach mit sortiert
ForEach(exercise.sets.sorted { $0.orderIndex < $1.orderIndex }) { set in
    WorkoutSetRow(set: set)
}
```

**NEVER:**
```swift
// ❌ FALSCH: orderIndex für Logik verwenden
if set.orderIndex < 3 {
    // Assume warmup
}

// ❌ FALSCH: Gruppierung nach orderIndex
let groups = Dictionary(grouping: sets) { $0.orderIndex < 5 }
```

**Begründung:** `orderIndex` ist ein Display-Hint, kein semantisches Flag.

#### Regel 3: Reindexing nach JEDEM Delete

**ALWAYS:**
```swift
// ✅ Nach jedem Delete reindexieren
session.exercises[exerciseIndex].sets.remove(at: setIndex)

// MANDATORY: Re-index
session.exercises[exerciseIndex].sets.sort { $0.orderIndex < $1.orderIndex }
for (newIndex, _) in session.exercises[exerciseIndex].sets.enumerated() {
    session.exercises[exerciseIndex].sets[newIndex].orderIndex = newIndex
}
```

**NEVER:**
```swift
// ❌ FALSCH: Delete ohne Reindexing
session.exercises[exerciseIndex].sets.remove(at: setIndex)
try await repository.update(session)  // ⚠️ Lücken im orderIndex!
```

**Begründung:** Ohne Reindexing entstehen Lücken (0, 1, 3, 5, ...), was zu visuellen Bugs und falscher Sortierung führt.

#### Regel 4: Max OrderIndex für neue Sets

**ALWAYS:**
```swift
// ✅ Max orderIndex finden
let maxOrderIndex = exercise.sets.map { $0.orderIndex }.max() ?? -1
let newSet = DomainSessionSet(
    orderIndex: maxOrderIndex + 1,
    ...
)
```

**NEVER:**
```swift
// ❌ FALSCH: Array count verwenden
let newSet = DomainSessionSet(
    orderIndex: exercise.sets.count,  // ⚠️ Falsch nach Deletions!
    ...
)
```

**Begründung:** Nach Deletions ist `array.count` ≠ `max(orderIndex)`. Beispiel: Nach Delete von Index 2 hat Array 3 Elemente, aber max orderIndex ist 3, nicht 2.

#### Regel 5: Duplicate Prevention

**ALWAYS:**
```swift
// ✅ Check vor Warmup-Erstellung
if exercise.sets.contains(where: { $0.isWarmup }) {
    print("⚠️ Warmup sets already exist. Skipping.")
    return
}
```

**NEVER:**
```swift
// ❌ FALSCH: Blind Warmups hinzufügen
let newSets = warmupSets.map { /* create */ }
exercise.sets.insert(contentsOf: newSets, at: 0)  // ⚠️ Keine Duplicate-Check!
```

**Begründung:** User könnte versehentlich zweimal Warmup-Strategie wählen, was zu duplizierten Warmup-Sets führt.

---

## 5. Gelöste Bugs & Fixes

### Bug #1: Warmup Sets verschwinden nach Erstellung

**Severity:** Critical  
**Status:** Fixed

**Symptome:**
- Warmup-Sets erscheinen kurz, verschwinden dann
- Logs zeigen `setNotFound` Fehler
- Sets sind nicht in DB persistent

**Root Cause:**
Race Condition in `applyWarmupStrategyToSession()`:

```swift
// ❌ RACE CONDITION
for (exerciseId, warmupSets) in warmupData {
    await sessionStore.addWarmupSets(exerciseId, warmupSets)
    // ^ Jeder Call: modify -> save DB -> refresh DB
    // Concurrent modifications während Iteration!
}
```

**Fix:**
Batch Operation mit Single DB Write:

```swift
// ✅ FIX
func addWarmupSetsBatch(_ warmupData: [UUID: [WarmupCalculator.WarmupSet]]) async {
    // 1. Capture all data FIRST
    // 2. Process ALL in memory
    // 3. Single DB write
    // 4. Single UI refresh
}
```

**Test:**
1. Start workout mit 3 Übungen
2. Wähle Warmup-Strategie für alle
3. Verify: Warmup-Sets bleiben sichtbar
4. Kill app, restart
5. Verify: Warmup-Sets sind persistent

### Bug #2: Set Completion Toggle funktioniert nicht

**Severity:** Critical  
**Status:** Fixed

**Symptome:**
- Erster und zweiter Warmup-Satz können abgehakt werden
- Dritter Warmup-Satz toggelt zwischen completed/uncompleted

**Root Cause:**
Mismatch zwischen Optimistic Update und UseCase:

```swift
// ❌ Optimistic Update: SETZT auf true
updateLocalSet(exerciseId: exerciseId, setId: setId, completed: true)

// ❌ UseCase: TOGGLET
session.exercises[exerciseIndex].sets[setIndex].completed.toggle()
```

**Fix:**
Optimistic Update auch togglen:

```swift
// ✅ FIX
var currentCompletedState = false
if let exercise = currentSession?.exercises.first(where: { $0.id == exerciseId }),
   let set = exercise.sets.first(where: { $0.id == setId }) {
    currentCompletedState = set.completed
}
let newCompletedState = !currentCompletedState
updateLocalSet(exerciseId: exerciseId, setId: setId, completed: newCompletedState)
```

**Test:**
1. Hake ersten Warmup-Satz ab → ✓
2. Hake zweiten Warmup-Satz ab → ✓
3. Hake dritten Warmup-Satz ab → ✓
4. Tippe nochmal auf dritten → Haken verschwindet
5. Verify: Toggle funktioniert für alle Sets

### Bug #3: HealthKit überschreibt Warmup-Sets

**Severity:** Critical  
**Status:** Fixed

**Symptome:**
- Warmup-Sets verschwinden nach ~2 Sekunden
- Logs zeigen: Session updated with HealthKit ID → 0 warmup sets

**Root Cause:**
HealthKit Task captured stale session copy:

```swift
// ❌ STALE COPY
Task {
    let healthKitId = try await healthKitService.startWorkout()
    session.healthKitSessionId = healthKitId  // ⚠️ 'session' ist OLD!
    try await repository.update(session)      // ⚠️ Überschreibt Warmup-Sets!
}
```

**Fix:**
Fetch current session from DB:

```swift
// ✅ FIX
Task {
    let healthKitId = try await healthKitService.startWorkout()
    
    // ⚠️ Fetch CURRENT session from DB
    guard var currentSession = try await repository.fetch(id: session.id) else {
        return
    }
    currentSession.healthKitSessionId = healthKitId
    try await repository.update(currentSession)
}
```

**Test:**
1. Start workout mit Warmup-Strategie
2. Warte 5 Sekunden
3. Verify: Warmup-Sets bleiben sichtbar
4. Check Logs: "Session updated with HealthKit ID" → Sets noch da

### Bug #4: UI zeigt Haken nicht sofort

**Severity:** High  
**Status:** Fixed

**Symptome:**
- Set wird abgehakt, aber Haken erscheint nicht
- Nach Tippen auf "Skip" oder anderen Button erscheint Haken
- UI updatet sich verzögert

**Root Cause:**
SwiftUI @Observable erkennt nested struct changes nicht:

```swift
// ❌ Nested change nicht detected
currentSession?.exercises[index].sets[setIndex].completed = true
```

**Fix:**
Force UI update durch nil-assignment:

```swift
// ✅ FIX
private func updateLocalSet(exerciseId: UUID, setId: UUID, completed: Bool) {
    guard var session = currentSession else { return }
    
    // Modify session...
    
    // ⚠️ Force SwiftUI update
    currentSession = nil
    currentSession = session
}
```

**Test:**
1. Tippe Warmup-Set an
2. Verify: Haken erscheint SOFORT
3. Keine weiteren UI Interactions nötig

### Bug #5: Rest Timer startet nicht bei Warmup-Sets

**Severity:** High  
**Status:** Fixed

**Symptome:**
- Rest Timer startet bei Arbeitssätzen
- Rest Timer startet NICHT bei Warmup-Sätzen

**Root Cause:**
Warmup-Sets hatten `restTime = nil`:

```swift
// ❌ Kein restTime
let newSets = warmupSets.map { warmupSet in
    DomainSessionSet(
        weight: warmupSet.weight,
        reps: warmupSet.reps,
        // ⚠️ restTime fehlt!
    )
}
```

**Fix:**
RestTime von Arbeitssätzen kopieren:

```swift
// ✅ FIX
let workingSetRestTime = exercise.sets.first(where: { !$0.isWarmup })?.restTime

let newSets = warmupSets.map { warmupSet in
    DomainSessionSet(
        weight: warmupSet.weight,
        reps: warmupSet.reps,
        restTime: workingSetRestTime,  // ✅ Copied from working set
        isWarmup: true
    )
}
```

**Test:**
1. Complete Warmup-Set
2. Verify: Rest Timer erscheint und zählt runter
3. Verify: Rest Time = Rest Time der Arbeitssätze

### Bug #6: OrderIndex Corruption nach Add

**Severity:** Medium  
**Status:** Fixed

**Symptome:**
- Nach Delete eines Sets und Add eines neuen Sets: falsche Sortierung
- Neuer Set erscheint in Mitte statt am Ende

**Root Cause:**
`array.count` ≠ `max(orderIndex)` nach Deletions:

```swift
// ❌ FALSCH
let currentSetCount = session.exercises[exerciseIndex].sets.count
let newSet = DomainSessionSet(
    orderIndex: currentSetCount  // ⚠️ Falsch nach Deletions!
)
```

**Fix:**
Max orderIndex finden:

```swift
// ✅ FIX
let maxOrderIndex = session.exercises[exerciseIndex].sets.map { $0.orderIndex }.max() ?? -1
let newSet = DomainSessionSet(
    orderIndex: maxOrderIndex + 1  // ✅ Immer am Ende
)
```

**Test:**
1. Exercise mit 5 Sets (orderIndex: 0,1,2,3,4)
2. Delete Set #2 (orderIndex bleibt: 0,1,3,4)
3. Add neuen Set
4. Verify: orderIndex = 5 (nicht 4!)
5. Verify: Neuer Set erscheint am Ende

### Bug #7: OrderIndex Gaps nach Delete

**Severity:** Medium  
**Status:** Fixed

**Symptome:**
- Nach mehreren Deletions: orderIndex hat Lücken (0, 1, 3, 5, 7)
- Visuelle Inkonsistenzen möglich

**Root Cause:**
Kein Reindexing nach Delete:

```swift
// ❌ KEIN REINDEXING
session.exercises[exerciseIndex].sets.remove(at: setIndex)
try await repository.update(session)  // ⚠️ Lücken bleiben!
```

**Fix:**
Reindex nach jedem Delete:

```swift
// ✅ FIX
session.exercises[exerciseIndex].sets.remove(at: setIndex)

// ⚠️ MANDATORY: Re-index
session.exercises[exerciseIndex].sets.sort { $0.orderIndex < $1.orderIndex }
for (newIndex, _) in session.exercises[exerciseIndex].sets.enumerated() {
    session.exercises[exerciseIndex].sets[newIndex].orderIndex = newIndex
}
```

**Test:**
1. Exercise mit 5 Sets (0,1,2,3,4)
2. Delete Set #1 → Re-index → (0,1,2,3)
3. Delete Set #2 → Re-index → (0,1,2)
4. Verify: Keine Lücken, sequential 0,1,2

### Bug #8: Low Weight Edge Case

**Severity:** Low  
**Status:** Fixed

**Symptome:**
- Bei Gewichten < 10kg: Alle Warmup-Sätze haben gleiches Gewicht
- Z.B. 7.5kg → Warmup: 5kg, 5kg, 5kg

**Root Cause:**
Rounding und Minimum-Logic nach Percentage:

```swift
// ❌ EDGE CASE
let calculatedWeight = 7.5 * 0.5 = 3.75
let roundedWeight = round(3.75 / 2.5) * 2.5 = 2.5
let finalWeight = max(roundedWeight, 5.0) = 5.0  // ⚠️ Immer 5kg!
```

**Fix:**
Skip Warmup für sehr leichte Gewichte:

```swift
// ✅ FIX
guard workingWeight >= 10.0 else {
    return []  // No warmup needed for very light weights
}

return percentages.compactMap { percentage in
    let calculatedWeight = workingWeight * percentage
    let roundedWeight = round(calculatedWeight / 2.5) * 2.5
    
    // Skip sets too close to working weight or below minimum
    guard roundedWeight >= 2.5 && roundedWeight < workingWeight else {
        return nil
    }
    
    return WarmupSet(...)
}
```

**Test:**
1. Exercise mit 7.5kg Arbeitsgewicht
2. Wähle Conservative (3 warmup)
3. Verify: KEINE Warmup-Sets generiert (zu leicht)
4. Exercise mit 50kg
5. Verify: 3 Warmup-Sets mit unterschiedlichen Gewichten

### Bug #9: Duplicate Warmup Sets möglich

**Severity:** Low  
**Status:** Fixed

**Symptome:**
- User könnte Warmup-Strategie zweimal wählen
- Führt zu duplizierten Warmup-Sets

**Root Cause:**
Keine Duplicate-Check:

```swift
// ❌ KEINE PRÜFUNG
func addWarmupSets(exerciseId: UUID, _ warmupSets: [...]) async {
    // Blind warmup sets hinzufügen
}
```

**Fix:**
Safety Check vor Hinzufügen:

```swift
// ✅ FIX
if exercise.sets.contains(where: { $0.isWarmup }) {
    print("⚠️ Warmup sets already exist. Skipping.")
    return
}
```

**Test:**
1. Start workout
2. Wähle Warmup-Strategie (Conservative)
3. Verify: 3 Warmup-Sets
4. Tippe nochmal auf Warmup-Button
5. Verify: KEINE neuen Warmup-Sets, Toast "Already exists"

---

## 6. Testing

### 6.1 Test Plan (17 Scenarios)

#### Data Persistence Tests

**Test 1: Warmup Sets werden korrekt gespeichert**
- Start workout, wähle Conservative
- Kill app, restart
- **Expected:** Warmup-Sets sind persistent, korrekte Gewichte/Reps

**Test 2: Set completion wird gespeichert**
- Complete 2 Warmup-Sets
- Kill app, restart
- **Expected:** 2 Sets als completed angezeigt

**Test 3: HealthKit überschreibt nicht**
- Warte 5 Sekunden nach Start
- **Expected:** Warmup-Sets bleiben sichtbar

#### UI/UX Tests

**Test 4: UI zeigt Haken sofort**
- Tippe Set an
- **Expected:** Haken erscheint sofort, kein Delay

**Test 5: Warmup-Indikator sichtbar**
- **Expected:** Warmup-Sets haben visuellen Indikator (Badge)

**Test 6: Sortierung korrekt**
- **Expected:** Warmup-Sets vor Arbeitssätzen

#### Rest Timer Tests

**Test 7: Rest Timer startet bei Warmup**
- Complete Warmup-Set
- **Expected:** Rest Timer erscheint und zählt runter

**Test 8: Rest Time = Working Set Rest Time**
- **Expected:** Gleiche Pausenzeit wie Arbeitssätze

**Test 9: Skip funktioniert**
- **Expected:** Timer kann geskipped werden

#### HealthKit Tests

**Test 10: Warmup-Sets in HealthKit**
- Nach workout Ende: Check Health app
- **Expected:** Warmup-Sets als Sätze gespeichert

**Test 11: Korrekte Gesamtdauer**
- **Expected:** Workout-Dauer inkludiert Warmup-Zeit

#### Statistics Tests

**Test 12: Backend unterstützt includeWarmupSets**
- API Call mit `includeWarmupSets=false`
- **Expected:** Nur Arbeitssätze in Statistik

**Test 13: Volume berechnet korrekt**
- **Expected:** Volume = Sum(weight * reps) für gewählte Set-Types

#### Edge Cases Tests

**Test 14: Low weight (<10kg)**
- Exercise mit 7.5kg
- **Expected:** Keine Warmup-Sets generiert

**Test 15: Duplicate Prevention**
- Zweimal Warmup-Strategie wählen
- **Expected:** Keine duplizierten Warmup-Sets

**Test 16: OrderIndex nach Delete**
- Delete Set #2, dann Add neuer Set
- **Expected:** Neuer Set am Ende, keine Lücken

**Test 17: Reindexing korrekt**
- Delete mehrere Sets
- **Expected:** OrderIndex sequential (0,1,2,...)

### 6.2 Regression Tests

Nach jeder Änderung testen:

1. **Batch Operation:** Warmup für alle Exercises gleichzeitig
2. **HealthKit Timing:** Warmup-Sets überleben HealthKit-Update
3. **Toggle Logic:** Alle Sets togglebar (nicht nur erste 2)
4. **UI Refresh:** Haken erscheint sofort
5. **Rest Timer:** Startet bei Warmup und Working Sets

### 6.3 Performance Tests

- **Large Session:** 10 Exercises, je 3 Warmup + 5 Working = 80 Sets
- **Batch Creation:** Warmup für alle 10 Exercises gleichzeitig
- **Expected:** < 1 Sekunde für Batch-Operation

---

## 7. Bekannte Limitierungen

### 7.1 Funktionale Limitierungen

1. **Keine nachträgliche Warmup-Entfernung**
   - Einmal hinzugefügte Warmup-Sets können nur einzeln gelöscht werden
   - Kein "Remove all warmup" Button
   - **Workaround:** Sets einzeln löschen

2. **Keine per-Exercise Warmup-Strategie**
   - Aktuell: Eine Strategie für alle Exercises
   - Gewünscht: Bodyweight-Exercises ohne Warmup
   - **Workaround:** Warmup-Strategie skippen für manche Exercises

3. **Keine Warmup-Editierung**
   - Gewichte/Reps von Warmup-Sets können nicht angepasst werden
   - **Workaround:** Delete + Re-create mit anderer Strategie

4. **Statistik Toggle nicht in UI**
   - Backend unterstützt `includeWarmupSets` Parameter
   - UI hat noch keinen Toggle
   - **Workaround:** Manuell in API Request

### 7.2 Technische Limitierungen

1. **Force Refresh Pattern ist Workaround**
   - `currentSession = nil` ist nicht ideal
   - **Better Solution:** SwiftUI @Published für nested changes
   - **Risk:** Performance bei vielen Sets

2. **RestTime Copying Logic**
   - Assumes first working set has restTime
   - Edge Case: Wenn User alle Arbeitssätze löscht
   - **Risk:** Warmup-Sets ohne restTime

3. **Migration nicht rückwärts-kompatibel**
   - Schema V4 → V5 (isWarmup hinzugefügt)
   - Alte App-Versionen können neue DB nicht lesen
   - **Mitigation:** `isWarmup` default = false in SchemaV4

### 7.3 UX Verbesserungen

1. **Strategy Tooltips fehlen**
   - User weiß nicht was Conservative/Moderate/Aggressive bedeutet
   - **Suggestion:** Info-Button mit Erklärung

2. **Kein visuelles Feedback bei Duplicate**
   - Safety Check ist silent
   - **Suggestion:** Toast "Warmup already added"

3. **Keine Warmup-Preview**
   - User sieht nicht welche Sets hinzugefügt werden vor Bestätigung
   - **Suggestion:** Preview-Sheet vor Apply

---

## 8. Maintenance & Erweiterungen

### 8.1 Code Locations

**Core Logic:**
- `/GymBo/Domain/UseCases/Session/WarmupCalculator.swift` - Pure calculation logic
- `/GymBo/Presentation/Stores/SessionStore.swift` - State management & batch operations

**Use Cases:**
- `/GymBo/Domain/UseCases/Session/StartSessionUseCase.swift` - HealthKit integration
- `/GymBo/Domain/UseCases/Session/CompleteSetUseCase.swift` - Toggle logic
- `/GymBo/Domain/UseCases/Session/AddSetUseCase.swift` - OrderIndex management
- `/GymBo/Domain/UseCases/Session/RemoveSetUseCase.swift` - Reindexing

**UI:**
- `/GymBo/Presentation/Views/Session/SessionView.swift` - Main view
- `/GymBo/Presentation/Views/Session/Components/CompactExerciseCard.swift` - Exercise card
- `/GymBo/Presentation/Views/Session/Components/WorkoutSetRow.swift` - Set row
- `/GymBo/Presentation/Views/Session/Components/WarmupStrategySheet.swift` - Strategy picker

**Data:**
- `/GymBo/Data/SwiftData/Schema/SchemaV5.swift` - Current schema
- `/GymBo/Data/Mappers/SessionMapper.swift` - Domain ↔ Entity mapping

### 8.2 Erweiterungs-Roadmap

#### Phase 1: UX Verbesserungen (Low Risk)

1. **Strategy Tooltips**
   - Add info button zu WarmupStrategySheet
   - Show explanation popover
   - **Effort:** 1-2h

2. **Duplicate Prevention Toast**
   - Show toast wenn warmup bereits existiert
   - **Effort:** 30min

3. **Warmup Preview**
   - Preview-Sheet vor Apply
   - Show calculated weights/reps
   - **Effort:** 2-3h

#### Phase 2: Funktionale Erweiterungen (Medium Risk)

1. **Remove All Warmup Button**
   - Button in CompactExerciseCard
   - Delete alle Sets mit `isWarmup = true`
   - Reindex remaining sets
   - **Effort:** 2-3h
   - **Risk:** Accidental deletion

2. **Statistics Toggle UI**
   - Toggle in StatisticsView
   - Persist in UserDefaults
   - Pass to backend API
   - **Effort:** 3-4h
   - **Risk:** Backend changes

3. **Per-Exercise Warmup Control**
   - Allow skip warmup für einzelne Exercises
   - UI: Checkbox "Include warmup" per Exercise
   - **Effort:** 4-5h
   - **Risk:** Complex UI logic

#### Phase 3: Architektur Verbesserungen (High Risk)

1. **SwiftUI @Published für nested changes**
   - Replace force refresh pattern
   - Use @Published oder Combine
   - **Effort:** 6-8h
   - **Risk:** Breaking SwiftUI updates

2. **Warmup Set Editierung**
   - Allow edit weight/reps von Warmup-Sets
   - UI: Long press → Edit sheet
   - **Effort:** 5-6h
   - **Risk:** Complex state management

3. **Dynamic RestTime Logic**
   - Handle edge case: Alle Arbeitssätze gelöscht
   - Fallback zu Exercise default restTime
   - **Effort:** 2-3h
   - **Risk:** Complex logic

### 8.3 Refactoring Opportunities

1. **Extract OrderIndex Management**
   - Create `OrderIndexManager` utility
   - Centralize reindexing logic
   - **Benefit:** DRY, easier testing

2. **Extract Set Operations**
   - Create `SetOperationsService`
   - Combine Add/Remove/Complete logic
   - **Benefit:** Single source of truth

3. **Extract HealthKit Integration**
   - Move HealthKit logic aus StartSessionUseCase
   - Create dedicated `HealthKitSessionService`
   - **Benefit:** Separation of concerns

### 8.4 Monitoring & Debugging

**Log Points für Production:**

1. **Warmup Creation:**
```swift
print("📊 Created \(warmupSets.count) warmup sets for exercise \(exerciseName)")
```

2. **Duplicate Prevention:**
```swift
print("⚠️ Warmup sets already exist for exercise \(exerciseName). Skipping.")
```

3. **HealthKit Update:**
```swift
print("✅ Session updated with HealthKit ID: \(healthKitId)")
```

4. **OrderIndex Issues:**
```swift
print("⚠️ OrderIndex gap detected: \(orderIndices)")
```

**Analytics Events:**

1. `warmup_strategy_selected` - Track welche Strategien populär sind
2. `warmup_completed` - Track completion rate
3. `warmup_skipped` - Track skip rate
4. `warmup_duplicate_prevented` - Track duplicate attempts

### 8.5 Breaking Changes zu vermeiden

**DO NOT:**

1. Rename `isWarmup` property → Breaking für alle existierenden Sessions
2. Change `orderIndex` to zero-indexed → Breaking für Display logic
3. Remove `restTime` from Warmup-Sets → Breaking für Timer
4. Change Warmup calculation logic drastisch → User expectations

**If you must make breaking changes:**

1. Create new Schema version (V6)
2. Add migration logic in SwiftData
3. Test migration mit alten Sessions
4. Document migration in release notes

---

## Changelog

### Version 1.0 (2025-10-30)

**Initial Release - Production Ready**

**Features:**
- Automatische Warmup-Set Berechnung
- 3 Strategien (Conservative, Moderate, Aggressive)
- Intelligente Gewichtsrundung auf 2.5kg
- Rest Timer Integration
- HealthKit Integration
- Statistics Backend Support

**Bug Fixes:**
- #1: Race Condition bei Warmup-Erstellung (Batch Operation)
- #2: Toggle Logic Mismatch (Optimistic Update gefixt)
- #3: HealthKit überschreibt Warmup-Sets (Fetch current session)
- #4: UI zeigt Haken nicht sofort (Force refresh pattern)
- #5: Rest Timer startet nicht (RestTime copying)
- #6: OrderIndex Corruption nach Add (Max orderIndex + 1)
- #7: OrderIndex Gaps nach Delete (Reindexing)
- #8: Low Weight Edge Case (Skip warmup < 10kg)
- #9: Duplicate Prevention (Safety checks)

**Documentation:**
- Comprehensive architecture guide
- 5 mandatory architecture rules
- 17 test scenarios
- Bug reports with fixes
- Refactoring roadmap

---

## Kontakt & Support

**Dokumentation:** `/Dokumentation/V2/Features/WarmupSets/`  
**Issues:** GitHub Issues  
**Architektur-Fragen:** @Architecture Team

**Wichtige Regeln nochmal:**
1. ALWAYS use `isWarmup` for filtering (NEVER `orderIndex`)
2. `orderIndex` is ONLY for display order
3. Reindex after EVERY deletion
4. New sets: `max(orderIndex) + 1`
5. Check for duplicates before adding warmup

---

**Status: ✅ Production Ready**
