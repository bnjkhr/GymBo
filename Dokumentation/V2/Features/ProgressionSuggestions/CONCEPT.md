# Automatische Progressionsvorschläge - Konzept

**Status:** Konzept zur Diskussion
**Erstellt:** 2025-10-31
**Ziel:** Intelligente, kontextbasierte Progressionsvorschläge während des aktiven Workouts

---

## 1. Übersicht

### 1.1 Vision

Während des aktiven Workouts erhält der User **live** intelligente Vorschläge zur Progression basierend auf:
- Historischen Trainingsdaten
- Aktueller Performance im laufenden Workout
- Trainingserfahrung und -niveau
- Spezifischen Übungen und deren Charakteristiken

### 1.2 User Experience Flow

```
┌─────────────────────────────────────────────────────────┐
│ Active Workout - Bankdrücken (Satz 3/4)                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  💡 PROGRESSIONSVORSCHLAG                               │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Basierend auf deinen letzten 3 Workouts:         │ │
│  │                                                   │ │
│  │ 100kg → 102.5kg (+2.5kg)                         │ │
│  │                                                   │ │
│  │ ✓ Du hast 100kg die letzten 2x geschafft        │ │
│  │ ✓ Performance heute: Stark (alle Sätze clean)   │ │
│  │ ✓ Erfahrungslevel: Fortgeschritten              │ │
│  │                                                   │ │
│  │ [Übernehmen] [Später]                            │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  Satz 1: 100kg × 8 ✓                                   │
│  Satz 2: 100kg × 8 ✓                                   │
│  Satz 3: 100kg × 8 ✓                                   │
│  Satz 4: 100kg × 8 [In Progress]                       │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Progression Detection Engine

### 2.1 Wann werden Vorschläge generiert?

**Trigger-Momente:**

1. **Set Completion Check** (nach jedem abgehakten Satz)
   - Prüfen ob alle Sätze einer Übung completed
   - Falls ja → Progression berechnen

2. **Exercise Start** (beim ersten Satz einer Übung)
   - Zeige Vorschlag BEVOR User beginnt
   - "Heute versuchen wir 102.5kg statt 100kg"

3. **Manual Trigger** (optional)
   - Button "Progressionsvorschlag anzeigen"
   - User kann jederzeit Vorschläge abrufen

### 2.2 Progression Calculation Logic

**Input-Daten:**

```swift
struct ProgressionCalculationInput {
    // Current Exercise
    let exercise: Exercise
    let currentWeight: Double
    let currentReps: Int
    let currentSets: Int

    // Historical Data
    let lastWorkouts: [CompletedWorkout]  // Last 3-5 workouts
    let exerciseHistory: ExerciseHistory  // All-time stats

    // User Context
    let experienceLevel: ExperienceLevel  // Anfänger/Fortgeschritten/Profi
    let fitnessGoal: FitnessGoal         // Kraft/Hypertrophie/Ausdauer

    // Current Performance
    let allSetsCompleted: Bool
    let repsPerformance: [Int]           // Tatsächliche Wiederholungen pro Satz
    let perceivedDifficulty: Difficulty? // Optional: User-Rating
}
```

**Algorithmus:**

```swift
protocol ProgressionStrategy {
    func calculateSuggestion(input: ProgressionCalculationInput) -> ProgressionSuggestion?
}

// STRATEGIE 1: Linear Weight Progression (Standard für Kraft)
class LinearWeightProgression: ProgressionStrategy {
    func calculateSuggestion(input: Input) -> Suggestion? {
        // Bedingungen:
        // ✓ Alle Sätze completed in den letzten 2 Workouts
        // ✓ Gleiches Gewicht seit ≥2 Workouts
        // ✓ Keine gescheiterten Versuche

        if meetsProgressionCriteria(input) {
            let increment = determineIncrement(
                equipmentType: input.exercise.equipmentType,
                experienceLevel: input.experienceLevel
            )

            return Suggestion(
                newWeight: input.currentWeight + increment,
                newReps: input.currentReps,
                reasoning: [
                    "Du hast \(input.currentWeight)kg die letzten 2x geschafft",
                    "Zeit für +\(increment)kg Progression"
                ],
                confidence: .high
            )
        }
        return nil
    }

    private func determineIncrement(
        equipmentType: EquipmentType,
        experienceLevel: ExperienceLevel
    ) -> Double {
        switch (equipmentType, experienceLevel) {
        case (.langhantel, .anfaenger):
            return 5.0  // Größere Sprünge für Anfänger
        case (.langhantel, .fortgeschritten):
            return 2.5  // Kleinere Sprünge für Fortgeschrittene
        case (.langhantel, .profi):
            return 1.25 // Microloading für Profis
        case (.kurzhantel, _):
            return 2.0  // Kleinere Increments bei KH
        case (.maschine, _):
            return 5.0  // Maschinen: Größere Increments
        default:
            return 2.5  // Default
        }
    }
}

// STRATEGIE 2: Rep Progression (Hypertrophie)
class RepProgression: ProgressionStrategy {
    func calculateSuggestion(input: Input) -> Suggestion? {
        // Bedingungen:
        // ✓ Gewicht seit 3+ Workouts gleich
        // ✓ Wiederholungen konstant erreicht
        // ✓ Fitness Goal: Hypertrophie

        if input.fitnessGoal == .hypertrophie {
            let targetReps = input.currentReps + 2

            return Suggestion(
                newWeight: input.currentWeight,
                newReps: targetReps,
                reasoning: [
                    "Gleiches Gewicht, mehr Volumen",
                    "Ziel: \(targetReps) Wiederholungen"
                ],
                confidence: .medium
            )
        }
        return nil
    }
}

// STRATEGIE 3: Deload Detection
class DeloadDetection: ProgressionStrategy {
    func calculateSuggestion(input: Input) -> Suggestion? {
        // Bedingungen:
        // ✓ Letzte 2+ Workouts: Sätze NICHT completed
        // ✓ Performance sinkt
        // ✓ Gewicht bleibt gleich/steigt

        let failedWorkouts = input.lastWorkouts.filter { !$0.allSetsCompleted }.count

        if failedWorkouts >= 2 {
            let deloadWeight = input.currentWeight * 0.9  // 10% Reduktion

            return Suggestion(
                newWeight: deloadWeight,
                newReps: input.currentReps,
                reasoning: [
                    "Letzte Workouts nicht completed",
                    "Deload empfohlen: -10% Gewicht"
                ],
                confidence: .high,
                type: .deload
            )
        }
        return nil
    }
}

// STRATEGIE 4: Smart Progression (KI-basiert)
class SmartProgression: ProgressionStrategy {
    func calculateSuggestion(input: Input) -> Suggestion? {
        // Analysiert Patterns über Zeit:
        // - Trainingsfrequenz
        // - Consistency
        // - Schlafmuster (falls Apple Health integration)
        // - Saison (Winter: mehr Kraft, Sommer: mehr Definition)

        let progressionRate = analyzeHistoricalProgressionRate(input.exerciseHistory)
        let readinessScore = calculateReadinessScore(input)

        if readinessScore > 0.7 {
            // User ist bereit für Progression
            return generateSmartSuggestion(
                currentWeight: input.currentWeight,
                progressionRate: progressionRate,
                readinessScore: readinessScore
            )
        }
        return nil
    }
}
```

### 2.3 Strategie-Auswahl

```swift
class ProgressionEngine {
    private let strategies: [ProgressionStrategy] = [
        DeloadDetection(),           // Priorität 1 (Safety first!)
        LinearWeightProgression(),   // Priorität 2 (Standard)
        RepProgression(),            // Priorität 3 (Alternative)
        SmartProgression()           // Priorität 4 (Advanced)
    ]

    func getSuggestion(for input: ProgressionCalculationInput) -> ProgressionSuggestion? {
        // Versuche Strategien in Reihenfolge
        for strategy in strategies {
            if let suggestion = strategy.calculateSuggestion(input: input) {
                return suggestion
            }
        }
        return nil
    }
}
```

---

## 3. Data Model

### 3.1 Domain Entities

```swift
// Domain/Entities/ProgressionSuggestion.swift

/// Represents a suggested progression for an exercise
struct ProgressionSuggestion: Identifiable {
    let id: UUID

    /// Exercise this suggestion is for
    let exerciseId: UUID

    /// Suggested new weight
    let suggestedWeight: Double

    /// Suggested new reps
    let suggestedReps: Int

    /// Suggested new sets (optional, usually stays same)
    let suggestedSets: Int?

    /// Type of progression
    let type: ProgressionType

    /// Reasoning for this suggestion (user-facing text)
    let reasoning: [String]

    /// Confidence level (affects UI presentation)
    let confidence: ConfidenceLevel

    /// When this suggestion was generated
    let generatedAt: Date

    /// Whether user accepted this suggestion
    var accepted: Bool = false

    /// When user accepted/rejected this suggestion
    var respondedAt: Date?
}

enum ProgressionType {
    case weightIncrease      // Standard weight progression
    case repIncrease         // More reps, same weight
    case volumeIncrease      // More sets
    case deload              // Reduce weight (recovery)
    case maintain            // Stay at current level
    case technique           // Suggest form improvement over weight
}

enum ConfidenceLevel {
    case high      // >80% success probability
    case medium    // 60-80% success probability
    case low       // <60% success probability

    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .yellow
        }
    }
}
```

### 3.2 Exercise History Extension

```swift
// Domain/Entities/ExerciseHistory.swift

/// Historical performance data for an exercise
struct ExerciseHistory {
    let exerciseId: UUID

    /// Last 10 workout sessions for this exercise
    let recentSessions: [ExerciseSession]

    /// All-time stats
    let totalWorkouts: Int
    let personalRecord: PersonalRecord?
    let averageWeight: Double
    let averageReps: Double

    /// Progression metrics
    let weeklyProgressionRate: Double  // kg/week
    let consistencyScore: Double       // 0.0-1.0
    let lastProgressionDate: Date?

    /// Computed properties
    var isProgressing: Bool {
        weeklyProgressionRate > 0
    }

    var isStagnating: Bool {
        // No progression in last 4 weeks
        guard let lastProgression = lastProgressionDate else { return true }
        return Date().timeIntervalSince(lastProgression) > 28 * 24 * 60 * 60
    }
}

struct ExerciseSession {
    let date: Date
    let weight: Double
    let reps: [Int]  // Reps per set
    let allSetsCompleted: Bool
    let perceivedDifficulty: Int?  // 1-10 scale (optional)
}

struct PersonalRecord {
    let weight: Double
    let reps: Int
    let date: Date
    let estimatedOneRepMax: Double
}
```

---

## 4. Use Cases

### 4.1 Generate Progression Suggestion

```swift
// Domain/UseCases/Progression/GenerateProgressionSuggestionUseCase.swift

protocol GenerateProgressionSuggestionUseCase {
    func execute(
        exerciseId: UUID,
        sessionId: UUID
    ) async throws -> ProgressionSuggestion?
}

final class DefaultGenerateProgressionSuggestionUseCase: GenerateProgressionSuggestionUseCase {
    private let sessionRepository: SessionRepositoryProtocol
    private let exerciseRepository: ExerciseRepositoryProtocol
    private let progressionEngine: ProgressionEngine

    func execute(
        exerciseId: UUID,
        sessionId: UUID
    ) async throws -> ProgressionSuggestion? {
        // 1. Fetch current session
        guard let session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound
        }

        // 2. Find exercise in session
        guard let sessionExercise = session.exercises.first(where: {
            $0.exerciseId == exerciseId
        }) else {
            throw UseCaseError.exerciseNotFound
        }

        // 3. Fetch exercise metadata
        guard let exercise = try await exerciseRepository.fetch(id: exerciseId) else {
            throw UseCaseError.exerciseNotFound
        }

        // 4. Build progression input
        let input = ProgressionCalculationInput(
            exercise: exercise,
            currentWeight: sessionExercise.sets.first?.weight ?? 0,
            currentReps: sessionExercise.sets.first?.reps ?? 0,
            currentSets: sessionExercise.sets.count,
            lastWorkouts: try await fetchLastWorkouts(exerciseId: exerciseId),
            exerciseHistory: try await buildExerciseHistory(exerciseId: exerciseId),
            experienceLevel: .fortgeschritten, // TODO: From UserProfile
            fitnessGoal: .kraft,                // TODO: From UserProfile
            allSetsCompleted: sessionExercise.sets.allSatisfy { $0.completed },
            repsPerformance: sessionExercise.sets.map { $0.reps }
        )

        // 5. Calculate suggestion
        let suggestion = progressionEngine.getSuggestion(for: input)

        // 6. Persist suggestion (for analytics)
        if let suggestion = suggestion {
            try await saveProgressionSuggestion(suggestion)
        }

        return suggestion
    }
}
```

### 4.2 Accept Progression Suggestion

```swift
// Domain/UseCases/Progression/AcceptProgressionSuggestionUseCase.swift

protocol AcceptProgressionSuggestionUseCase {
    func execute(
        suggestionId: UUID,
        sessionId: UUID,
        exerciseId: UUID
    ) async throws -> DomainWorkoutSession
}

final class DefaultAcceptProgressionSuggestionUseCase: AcceptProgressionSuggestionUseCase {
    private let sessionRepository: SessionRepositoryProtocol
    private let workoutRepository: WorkoutRepositoryProtocol
    private let suggestionRepository: ProgressionSuggestionRepositoryProtocol

    func execute(
        suggestionId: UUID,
        sessionId: UUID,
        exerciseId: UUID
    ) async throws -> DomainWorkoutSession {
        // 1. Fetch suggestion
        guard let suggestion = try await suggestionRepository.fetch(id: suggestionId) else {
            throw UseCaseError.suggestionNotFound
        }

        // 2. Fetch current session
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw UseCaseError.sessionNotFound
        }

        // 3. Find exercise in session
        guard let exerciseIndex = session.exercises.firstIndex(where: {
            $0.exerciseId == exerciseId
        }) else {
            throw UseCaseError.exerciseNotFound
        }

        // 4. Update ALL sets in this exercise with new values
        for setIndex in 0..<session.exercises[exerciseIndex].sets.count {
            session.exercises[exerciseIndex].sets[setIndex].weight = suggestion.suggestedWeight
            session.exercises[exerciseIndex].sets[setIndex].reps = suggestion.suggestedReps
        }

        // 5. Mark suggestion as accepted
        var acceptedSuggestion = suggestion
        acceptedSuggestion.accepted = true
        acceptedSuggestion.respondedAt = Date()
        try await suggestionRepository.update(acceptedSuggestion)

        // 6. Update workout template permanently (optional behavior)
        try await updateWorkoutTemplate(
            workoutId: session.workoutId,
            exerciseId: exerciseId,
            newWeight: suggestion.suggestedWeight,
            newReps: suggestion.suggestedReps
        )

        // 7. Persist session
        try await sessionRepository.update(session)

        return session
    }
}
```

---

## 5. UI Components

### 5.1 Progression Suggestion Card

```swift
// Presentation/Views/ActiveWorkout/Components/ProgressionSuggestionCard.swift

struct ProgressionSuggestionCard: View {
    let suggestion: ProgressionSuggestion
    let currentWeight: Double
    let currentReps: Int
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.appOrange)
                Text("PROGRESSIONSVORSCHLAG")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                // Confidence Badge
                ConfidenceBadge(level: suggestion.confidence)
            }

            // Progression Display
            HStack(alignment: .center, spacing: 8) {
                // Current
                VStack(alignment: .leading) {
                    Text("Aktuell")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(formatWeight(currentWeight))kg × \(currentReps)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                // Arrow
                Image(systemName: "arrow.right")
                    .foregroundStyle(.appOrange)
                    .font(.title3)

                // Suggested
                VStack(alignment: .leading) {
                    Text("Vorschlag")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(formatWeight(suggestion.suggestedWeight))kg × \(suggestion.suggestedReps)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.appOrange)
                }

                Spacer()

                // Delta Badge
                if suggestion.suggestedWeight > currentWeight {
                    Text("+\(formatWeight(suggestion.suggestedWeight - currentWeight))kg")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                }
            }

            // Reasoning
            VStack(alignment: .leading, spacing: 6) {
                ForEach(suggestion.reasoning, id: \.self) { reason in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(reason)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button("Später") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .tint(.secondary)

                Button("Übernehmen") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .tint(.appOrange)
            }
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

struct ConfidenceBadge: View {
    let level: ConfidenceLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(level.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(level.color.opacity(0.15))
        .cornerRadius(8)
    }

    private var label: String {
        switch level {
        case .high: return "Sehr empfohlen"
        case .medium: return "Empfohlen"
        case .low: return "Optional"
        }
    }
}
```

### 5.2 Integration in ActiveWorkoutSheetView

```swift
// Presentation/Views/ActiveWorkout/ActiveWorkoutSheetView.swift

struct ActiveWorkoutSheetView: View {
    @State private var progressionSuggestion: ProgressionSuggestion?
    @State private var showProgressionCard: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timer Section
                TimerSection(...)

                // PROGRESSION SUGGESTION CARD (if available)
                if showProgressionCard, let suggestion = progressionSuggestion {
                    ProgressionSuggestionCard(
                        suggestion: suggestion,
                        currentWeight: getCurrentWeight(),
                        currentReps: getCurrentReps(),
                        onAccept: {
                            Task {
                                await acceptSuggestion(suggestion)
                            }
                        },
                        onDismiss: {
                            withAnimation {
                                showProgressionCard = false
                            }
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Exercise Cards
                ForEach(visibleExercises) { exercise in
                    CompactExerciseCard(...)
                }
            }
        }
        .onChange(of: sessionStore.currentSession?.exercises) { oldValue, newValue in
            Task {
                await checkForProgressionSuggestion()
            }
        }
    }

    private func checkForProgressionSuggestion() async {
        // Triggered after each set completion
        guard let session = sessionStore.currentSession else { return }

        // Find just-completed exercise
        for exercise in session.exercises {
            let allSetsCompleted = exercise.sets.allSatisfy { $0.completed }

            if allSetsCompleted && !exercise.isFinished {
                // Generate suggestion
                if let suggestion = await generateSuggestion(for: exercise.exerciseId) {
                    withAnimation {
                        progressionSuggestion = suggestion
                        showProgressionCard = true
                    }
                    break  // Only one suggestion at a time
                }
            }
        }
    }
}
```

---

## 6. Persistence Layer

### 6.1 SwiftData Entity

```swift
// Data/SwiftDataEntities.swift

@Model
final class ProgressionSuggestionEntity {
    var id: UUID
    var exerciseId: UUID
    var sessionId: UUID
    var suggestedWeight: Double
    var suggestedReps: Int
    var suggestedSets: Int?
    var typeRaw: String  // ProgressionType as String
    var reasoning: [String]
    var confidenceRaw: String  // ConfidenceLevel as String
    var generatedAt: Date
    var accepted: Bool
    var respondedAt: Date?

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        sessionId: UUID,
        suggestedWeight: Double,
        suggestedReps: Int,
        suggestedSets: Int? = nil,
        typeRaw: String,
        reasoning: [String],
        confidenceRaw: String,
        generatedAt: Date = Date(),
        accepted: Bool = false,
        respondedAt: Date? = nil
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.sessionId = sessionId
        self.suggestedWeight = suggestedWeight
        self.suggestedReps = suggestedReps
        self.suggestedSets = suggestedSets
        self.typeRaw = typeRaw
        self.reasoning = reasoning
        self.confidenceRaw = confidenceRaw
        self.generatedAt = generatedAt
        self.accepted = accepted
        self.respondedAt = respondedAt
    }
}
```

### 6.2 Repository

```swift
// Data/Repositories/SwiftDataProgressionSuggestionRepository.swift

protocol ProgressionSuggestionRepositoryProtocol {
    func save(_ suggestion: ProgressionSuggestion) async throws
    func fetch(id: UUID) async throws -> ProgressionSuggestion?
    func fetchForExercise(exerciseId: UUID, limit: Int) async throws -> [ProgressionSuggestion]
    func update(_ suggestion: ProgressionSuggestion) async throws
    func fetchAcceptanceRate(exerciseId: UUID) async throws -> Double
}

final class SwiftDataProgressionSuggestionRepository: ProgressionSuggestionRepositoryProtocol {
    private let modelContext: ModelContext
    private let mapper: ProgressionSuggestionMapper

    // ... implementation

    func fetchAcceptanceRate(exerciseId: UUID) async throws -> Double {
        // Useful metric: How often does user accept suggestions for this exercise?
        let descriptor = FetchDescriptor<ProgressionSuggestionEntity>(
            predicate: #Predicate { $0.exerciseId == exerciseId }
        )

        let all = try modelContext.fetch(descriptor)
        guard !all.isEmpty else { return 0.0 }

        let accepted = all.filter { $0.accepted }.count
        return Double(accepted) / Double(all.count)
    }
}
```

---

## 7. Settings & Preferences

### 7.1 User Preferences

```swift
// Domain/Entities/ProgressionPreferences.swift

struct ProgressionPreferences {
    /// Enable/disable automatic suggestions
    var enabled: Bool = true

    /// Show suggestions at exercise start vs. exercise completion
    var timing: SuggestionTiming = .onCompletion

    /// Minimum confidence level to show suggestions
    var minConfidence: ConfidenceLevel = .medium

    /// Auto-accept high-confidence suggestions (skip UI)
    var autoAcceptHighConfidence: Bool = false

    /// Conservative vs. aggressive progression
    var progressionStyle: ProgressionStyle = .balanced
}

enum SuggestionTiming {
    case onExerciseStart   // Before first set
    case onCompletion      // After all sets completed
    case both              // Show twice
}

enum ProgressionStyle {
    case conservative  // Smaller increments, safer
    case balanced      // Standard approach
    case aggressive    // Larger increments, faster progression
}
```

### 7.2 Settings UI

```swift
// Presentation/Views/Settings/ProgressionSettingsView.swift

struct ProgressionSettingsView: View {
    @State private var preferences: ProgressionPreferences

    var body: some View {
        Form {
            Section("Automatische Vorschläge") {
                Toggle("Progressionsvorschläge", isOn: $preferences.enabled)

                if preferences.enabled {
                    Picker("Zeitpunkt", selection: $preferences.timing) {
                        Text("Vor der Übung").tag(SuggestionTiming.onExerciseStart)
                        Text("Nach der Übung").tag(SuggestionTiming.onCompletion)
                        Text("Beides").tag(SuggestionTiming.both)
                    }

                    Picker("Progressionsstil", selection: $preferences.progressionStyle) {
                        Text("Konservativ").tag(ProgressionStyle.conservative)
                        Text("Ausgewogen").tag(ProgressionStyle.balanced)
                        Text("Aggressiv").tag(ProgressionStyle.aggressive)
                    }
                }
            }

            Section("Erweitert") {
                Toggle("Hohe Konfidenz auto-akzeptieren", isOn: $preferences.autoAcceptHighConfidence)

                Picker("Min. Konfidenz", selection: $preferences.minConfidence) {
                    Text("Niedrig").tag(ConfidenceLevel.low)
                    Text("Mittel").tag(ConfidenceLevel.medium)
                    Text("Hoch").tag(ConfidenceLevel.high)
                }
            }
        }
        .navigationTitle("Progression")
    }
}
```

---

## 8. Analytics & Insights

### 8.1 Progression Analytics Entity

```swift
// Domain/Entities/ProgressionAnalytics.swift

struct ProgressionAnalytics {
    let exerciseId: UUID

    /// Total suggestions generated
    let totalSuggestions: Int

    /// Suggestions accepted by user
    let acceptedSuggestions: Int

    /// Acceptance rate (0.0-1.0)
    var acceptanceRate: Double {
        guard totalSuggestions > 0 else { return 0.0 }
        return Double(acceptedSuggestions) / Double(totalSuggestions)
    }

    /// Average weight progression per week
    let avgWeightProgressionPerWeek: Double

    /// Last progression date
    let lastProgressionDate: Date?

    /// Success rate of accepted suggestions
    /// (Did user complete all sets after accepting suggestion?)
    let suggestionSuccessRate: Double
}
```

### 8.2 Analytics View

```swift
// Presentation/Views/Analytics/ProgressionAnalyticsView.swift

struct ProgressionAnalyticsView: View {
    let analytics: ProgressionAnalytics

    var body: some View {
        VStack(spacing: 20) {
            // Acceptance Rate Card
            StatCard(
                title: "Vorschläge akzeptiert",
                value: "\(Int(analytics.acceptanceRate * 100))%",
                subtitle: "\(analytics.acceptedSuggestions)/\(analytics.totalSuggestions) Vorschläge",
                color: .green
            )

            // Progression Rate Card
            StatCard(
                title: "Progression pro Woche",
                value: "+\(formatWeight(analytics.avgWeightProgressionPerWeek))kg",
                subtitle: "Durchschnitt letzte 4 Wochen",
                color: .blue
            )

            // Success Rate Card
            StatCard(
                title: "Erfolgsrate",
                value: "\(Int(analytics.suggestionSuccessRate * 100))%",
                subtitle: "Akzeptierte Vorschläge erfolgreich",
                color: .orange
            )
        }
    }
}
```

---

## 9. Implementation Roadmap

### Phase 1: Foundation (4-6 Stunden)
- ✅ ProgressionSuggestion Domain Entity
- ✅ ProgressionCalculationInput struct
- ✅ Basic ProgressionEngine with LinearWeightProgression strategy
- ✅ GenerateProgressionSuggestionUseCase
- ✅ SwiftData Entity & Repository

### Phase 2: UI Integration (3-4 Stunden)
- ✅ ProgressionSuggestionCard component
- ✅ Integration in ActiveWorkoutSheetView
- ✅ AcceptProgressionSuggestionUseCase
- ✅ SessionStore methods for progression

### Phase 3: Advanced Strategies (4-5 Stunden)
- ✅ RepProgression strategy
- ✅ DeloadDetection strategy
- ✅ ExerciseHistory entity & fetching logic
- ✅ Historical workout analysis

### Phase 4: Settings & Preferences (2-3 Stunden)
- ✅ ProgressionPreferences entity
- ✅ Settings UI
- ✅ UserDefaults persistence
- ✅ Toggle auto-accept high confidence

### Phase 5: Analytics (3-4 Stunden)
- ✅ ProgressionAnalytics entity
- ✅ Analytics calculations
- ✅ Analytics view in Profile
- ✅ Acceptance rate tracking

### Phase 6: Polish & Testing (2-3 Stunden)
- ✅ Unit tests for progression strategies
- ✅ Integration tests for use cases
- ✅ UI testing
- ✅ Edge case handling

**Geschätzte Gesamtdauer:** 18-25 Stunden

---

## 10. Technical Considerations

### 10.1 Performance

**Caching Strategy:**
- Cache ExerciseHistory in memory (avoid repeated DB queries)
- Invalidate cache after each workout completion
- Background processing for history calculation

**Lazy Loading:**
- Generate suggestions on-demand, not upfront
- Only calculate when exercise is completed
- Debounce rapid set completions (wait 1s before generating)

### 10.2 Migration Strategy

**Schema V7 Migration:**
```swift
// Add ProgressionSuggestionEntity to ModelContainer
let schema = Schema([
    SessionEntity.self,
    WorkoutEntity.self,
    ExerciseEntity.self,
    ProgressionSuggestionEntity.self  // NEW
])

// Lightweight migration (no breaking changes)
let migrationPlan = GymBoMigrationPlan()
```

**Backward Compatibility:**
- Feature works WITHOUT historical data (graceful degradation)
- If no history → only basic suggestions based on current session
- Progressive enhancement as user builds history

### 10.3 Data Privacy

**Local-First:**
- All calculations happen on-device
- No external API calls
- No data sent to server

**User Control:**
- Can disable feature completely
- Can delete suggestion history
- Transparent reasoning (why this suggestion?)

---

## 11. Open Questions für Diskussion

### 11.1 UX Fragen
1. **Timing:** Vorschlag VOR oder NACH der Übung zeigen?
   - VOR: "Heute versuchen wir 102.5kg"
   - NACH: "Nächstes Mal 102.5kg probieren"

2. **Persistenz:** Vorschlag automatisch im Workout-Template speichern?
   - JA: User muss nie manuell ändern
   - NEIN: User behält Kontrolle über Template

3. **Frequency:** Wie oft Vorschläge zeigen?
   - Jedes Workout?
   - Nur wenn Progression möglich?
   - Max. 1x pro Übung pro Woche?

### 11.2 Algorithmus Fragen
1. **Deload Trigger:** Wie aggressiv soll Deload Detection sein?
   - Nach 2 gescheiterten Workouts?
   - Nach 3 gescheiterten Workouts?
   - User-konfigurierbar?

2. **Equipment-spezifische Increments:** Stimmen die Werte?
   - Langhantel Anfänger: 5kg
   - Langhantel Fortgeschritten: 2.5kg
   - Langhantel Profi: 1.25kg
   - Oder lieber prozentual? (z.B. +2%)

3. **Confidence Calculation:** Was definiert "high confidence"?
   - 3+ erfolgreiche Workouts mit gleichem Gewicht?
   - Oder zusätzlich: Consistency-Score, Trainingsfrequenz?

### 11.3 Feature Scope
1. **MVP:** Was ist das absolute Minimum für V1?
   - Nur LinearWeightProgression?
   - Nur für Standard-Workouts (kein Superset/Circuit)?
   - Nur manuelle Akzeptanz (kein auto-accept)?

2. **Nice-to-Have:** Was kommt später?
   - SmartProgression mit ML?
   - Integration mit Apple Health (Schlaf, HRV)?
   - Social Features (Vergleich mit anderen Usern)?

---

## 12. Next Steps

### Für die Diskussion vorbereiten:
1. **UX Flow** durchgehen (Wireframes/Mockups?)
2. **Algorithmus-Parameter** festlegen (Increments, Confidence-Schwellen)
3. **MVP Scope** definieren (Was muss in V1, was kann warten?)
4. **Timeline** abschätzen (Wann soll das live gehen?)

### Technische Entscheidungen:
1. Schema V7 Migration planen
2. Use Case Dependencies klären
3. Testing-Strategie festlegen

---

**Fragen? Anmerkungen? Lass uns das besprechen!** 🚀
