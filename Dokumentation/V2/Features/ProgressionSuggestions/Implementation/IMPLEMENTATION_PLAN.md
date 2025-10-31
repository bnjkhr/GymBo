# Detailed Implementation Plan: Progressionsvorschläge

## 🎯 Executive Summary

This document provides a step-by-step implementation plan for adding automatic progression suggestions to GymBo. The plan is designed for **zero breaking changes** and follows the existing V2 Clean Architecture pattern.

**Total Estimated Time**: 16-21 hours  
**MVP Completion**: Phases 1-4 (16-18 hours)  
**Risk Level**: Medium (manageable with proper testing)

---

## 📋 Prerequisites & Setup

### Required Environment
- Xcode 15.0+
- iOS 17.0+ target
- SwiftData enabled
- Git branch: `feature/progression-suggestions`

### Required Knowledge
- SwiftData migration patterns
- Clean Architecture (Domain/Data/Presentation)
- SwiftUI state management
- Existing GymBo codebase structure

---

## 🚀 Phase 1: Data Model & Schema V7 (4-5 hours)

### 1.1 Create SchemaV7.swift
**File**: `GymBo/Data/Migration/SchemaV7.swift`  
**Time**: 1.5 hours

**Steps**:
1. Copy SchemaV6.swift as starting point
2. Add `ProgressionSuggestionEntity` class
3. Ensure all existing entities remain unchanged
4. Add `ProgressionSuggestionEntity` to models array

```swift
// ProgressionSuggestionEntity - ALL FIELDS OPTIONAL WITH DEFAULTS
@Model
final class ProgressionSuggestionEntity {
    @Attribute(.unique) var id: UUID
    var exerciseId: UUID
    var sessionId: UUID
    var suggestedWeight: Double
    var suggestedReps: Int
    var suggestedSets: Int?
    var typeRaw: String
    var reasoning: [String]
    var confidenceRaw: String
    var generatedAt: Date
    var accepted: Bool
    var respondedAt: Date?
    
    init(/* parameters with defaults */) {
        // Initialize with safe defaults
    }
}
```

**Validation**:
- [ ] Schema compiles without errors
- [ ] All existing entities unchanged
- [ ] New entity has all required relationships

### 1.2 Update Migration Plan
**File**: `GymBo/Data/Migration/GymBoMigrationPlan.swift`  
**Time**: 30 minutes

**Steps**:
1. Add `SchemaV7.self` to schemas array
2. Add `migrateV6toV7` to stages array
3. Use lightweight migration (no custom logic needed)

```swift
// Add to schemas array:
SchemaV7.self,

// Add to stages array:
migrateV6toV7,

// Add migration stage:
static let migrateV6toV7 = MigrationStage.lightweight(
    fromVersion: SchemaV6.self,
    toVersion: SchemaV7.self
)
```

**Validation**:
- [ ] Migration plan compiles
- [ ] Lightweight migration selected (correct)

### 1.3 Create Domain ProgressionSuggestion
**File**: `GymBo/Domain/Entities/ProgressionSuggestion.swift`  
**Time**: 1 hour

**Steps**:
1. Create pure Swift struct (no framework dependencies)
2. Follow existing domain entity patterns
3. Include all MVP fields (simplified version)
4. Add Equatable, Identifiable conformance

```swift
struct DomainProgressionSuggestion: Identifiable, Equatable {
    let id: UUID
    let exerciseId: UUID
    let sessionId: UUID
    let suggestedWeight: Double
    let suggestedReps: Int
    let suggestedSets: Int?
    let type: ProgressionType
    let reasoning: [String]
    let confidence: ConfidenceLevel
    let generatedAt: Date
    var accepted: Bool
    var respondedAt: Date?
    
    enum ProgressionType: String, CaseIterable {
        case weightIncrease = "weight_increase"
        case repsIncrease = "reps_increase"
        case deload = "deload"
    }
    
    enum ConfidenceLevel: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
}
```

**Validation**:
- [ ] Struct compiles without framework imports
- [ ] Equatable and Identifiable work correctly
- [ ] All MVP fields included

### 1.4 Create ExerciseHistory
**File**: `GymBo/Domain/Entities/ExerciseHistory.swift`  
**Time**: 1 hour

**Steps**:
1. Create simplified version for MVP
2. Focus on recent sessions and basic stats
3. Add computed properties for progression detection
4. Include convenience methods

```swift
struct ExerciseHistory {
    let exerciseId: UUID
    let recentSessions: [ExerciseSession]
    let totalWorkouts: Int
    let lastProgressionDate: Date?
    
    var isProgressing: Bool {
        // Simple logic: progression in last 3 sessions
    }
    
    var isStagnating: Bool {
        // Simple logic: no progression in last 5 sessions
    }
    
    var successfulSessionsCount: Int {
        // Count sessions where all sets completed
    }
}

struct ExerciseSession {
    let date: Date
    let weight: Double
    let reps: [Int]
    let allSetsCompleted: Bool
}
```

**Validation**:
- [ ] ExerciseHistory computes correct values
- [ ] Edge cases handled (empty history, etc.)

### 1.5 Test Migration
**Time**: 1 hour

**Steps**:
1. Create test app with existing data
2. Run migration from V6 to V7
3. Verify all existing data intact
4. Verify new entity created successfully

**Validation**:
- [ ] Migration completes without errors
- [ ] Existing data preserved
- [ ] New entity functions correctly

---

## 🧠 Phase 2: Progression Engine (3-4 hours)

### 2.1 Create ProgressionEngine
**File**: `GymBo/Domain/Services/ProgressionEngine.swift`  
**Time**: 2 hours

**Steps**:
1. Create simple linear progression logic only
2. Use existing ExperienceLevel and FitnessGoal enums
3. Implement confidence calculation
4. Add reasoning generation

```swift
struct LinearProgressionEngine {
    
    func calculateSuggestion(
        for exercise: DomainSessionExercise,
        history: ExerciseHistory?,
        userLevel: ExperienceLevel,
        userGoal: FitnessGoal
    ) -> DomainProgressionSuggestion? {
        
        // MVP Logic:
        // 1. Check if suggestion should be generated
        // 2. Calculate weight or reps increase
        // 3. Determine confidence level
        // 4. Generate reasoning
        
        guard let history = history,
              history.successfulSessionsCount >= 3 else {
            return nil
        }
        
        switch userGoal {
        case .muscleGain:
            return calculateWeightSuggestion(exercise: exercise, history: history, level: userLevel)
        case .fitness, .weightLoss:
            return calculateRepsSuggestion(exercise: exercise, history: history)
        }
    }
    
    private func calculateWeightSuggestion(/* params */) -> DomainProgressionSuggestion? {
        // Linear weight progression: +2.5kg for intermediate, +5kg for beginner
    }
    
    private func calculateRepsSuggestion(/* params */) -> DomainProgressionSuggestion? {
        // Linear reps progression: +1-2 reps based on current reps
    }
    
    private func calculateConfidence(history: ExerciseHistory) -> ConfidenceLevel {
        // Simple confidence based on consistency
        if history.successfulSessionsCount >= 5 {
            return .high
        } else if history.successfulSessionsCount >= 3 {
            return .medium
        } else {
            return .low
        }
    }
}
```

**Validation**:
- [ ] Progression logic follows MVP rules
- [ ] Confidence calculation makes sense
- [ ] Edge cases handled (no history, etc.)

### 2.2 Create Unit Tests
**File**: `GymBoTests/Domain/Services/ProgressionEngineTests.swift`  
**Time**: 1.5 hours

**Test Cases**:
```swift
class ProgressionEngineTests: XCTestCase {
    
    func testLinearWeightProgression_Basic() {
        // Test basic weight increase scenario
    }
    
    func testLinearWeightProgression_DifferentLevels() {
        // Test progression for beginner vs intermediate vs advanced
    }
    
    func testLinearRepsProgression() {
        // Test reps increase scenario
    }
    
    func testConfidenceCalculation() {
        // Test confidence levels based on session history
    }
    
    func testNoHistory() {
        // Test behavior when no exercise history available
    }
    
    func testInsufficientHistory() {
        // Test behavior when < 3 successful sessions
    }
}
```

**Validation**:
- [ ] All unit tests pass
- [ ] Edge cases covered
- [ ] Logic matches MVP requirements

---

## 🔧 Phase 3: Use Cases & Repositories (3-4 hours)

### 3.1 Create Repository Protocol
**File**: `GymBo/Domain/RepositoryProtocols/ProgressionSuggestionRepositoryProtocol.swift`  
**Time**: 30 minutes

**Steps**:
1. Follow existing repository patterns
2. Define CRUD operations needed for MVP
3. Keep interface minimal

```swift
protocol ProgressionSuggestionRepositoryProtocol {
    func save(_ suggestion: DomainProgressionSuggestion) async throws
    func fetch(id: UUID) async throws -> DomainProgressionSuggestion?
    func fetchForExercise(exerciseId: UUID, limit: Int) async throws -> [DomainProgressionSuggestion]
    func update(_ suggestion: DomainProgressionSuggestion) async throws
}
```

### 3.2 Create Use Case: Generate Suggestion
**File**: `GymBo/Domain/UseCases/GenerateProgressionSuggestionUseCase.swift`  
**Time**: 1.5 hours

**Steps**:
1. Use existing repository patterns
2. Integrate with ProgressionEngine
3. Handle all error cases gracefully
4. Follow async/await patterns

```swift
protocol GenerateProgressionSuggestionUseCaseProtocol {
    func execute(exerciseId: UUID, sessionId: UUID) async throws -> DomainProgressionSuggestion?
}

struct GenerateProgressionSuggestionUseCase: GenerateProgressionSuggestionUseCaseProtocol {
    
    private let sessionRepository: SessionRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let progressionEngine: LinearProgressionEngine
    private let suggestionRepository: ProgressionSuggestionRepositoryProtocol
    
    func execute(exerciseId: UUID, sessionId: UUID) async throws -> DomainProgressionSuggestion? {
        do {
            // 1. Get current exercise from session
            guard let session = try await sessionRepository.fetch(id: sessionId),
                  let exercise = session.exercises.first(where: { $0.exerciseId == exerciseId }) else {
                return nil
            }
            
            // 2. Get user profile for level and goals
            let userProfile = try await userProfileRepository.fetch()
            
            // 3. Get exercise history
            let history = try await buildExerciseHistory(exerciseId: exerciseId)
            
            // 4. Calculate suggestion
            guard let suggestion = progressionEngine.calculateSuggestion(
                for: exercise,
                history: history,
                userLevel: userProfile.experienceLevel ?? .intermediate,
                userGoal: userProfile.fitnessGoal ?? .fitness
            ) else {
                return nil
            }
            
            // 5. Save suggestion
            try await suggestionRepository.save(suggestion)
            
            return suggestion
            
        } catch {
            print("⚠️ Failed to generate progression suggestion: \(error)")
            return nil
        }
    }
    
    private func buildExerciseHistory(exerciseId: UUID) async throws -> ExerciseHistory {
        // Build exercise history from session data
        // For MVP: simplify to recent successful sessions
    }
}
```

### 3.3 Create Use Case: Accept Suggestion
**File**: `GymBo/Domain/UseCases/AcceptProgressionSuggestionUseCase.swift`  
**Time**: 1.5 hours

**Steps**:
1. Update suggestion as accepted
2. Apply suggestion to current session
3. Update exercise in session
4. Save changes

```swift
protocol AcceptProgressionSuggestionUseCaseProtocol {
    func execute(suggestionId: UUID, sessionId: UUID, exerciseId: UUID) async throws -> DomainWorkoutSession
}

struct AcceptProgressionSuggestionUseCase: AcceptProgressionSuggestionUseCaseProtocol {
    
    private let suggestionRepository: ProgressionSuggestionRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol
    
    func execute(suggestionId: UUID, sessionId: UUID, exerciseId: UUID) async throws -> DomainWorkoutSession {
        
        // 1. Get suggestion
        guard var suggestion = try await suggestionRepository.fetch(id: suggestionId) else {
            throw ProgressionError.suggestionNotFound
        }
        
        // 2. Mark as accepted
        suggestion.accepted = true
        suggestion.respondedAt = Date()
        try await suggestionRepository.update(suggestion)
        
        // 3. Get and update session
        guard var session = try await sessionRepository.fetch(id: sessionId) else {
            throw ProgressionError.sessionNotFound
        }
        
        // 4. Find and update exercise
        guard let exerciseIndex = session.exercises.firstIndex(where: { $0.exerciseId == exerciseId }) else {
            throw ProgressionError.exerciseNotFound
        }
        
        var exercise = session.exercises[exerciseIndex]
        
        // Apply suggestion to exercise
        exercise.sets = exercise.sets.map { set in
            var updatedSet = set
            updatedSet.weight = suggestion.suggestedWeight
            if suggestion.suggestedReps > 0 {
                updatedSet.reps = suggestion.suggestedReps
            }
            return updatedSet
        }
        
        session.exercises[exerciseIndex] = exercise
        
        // 5. Save updated session
        let updatedSession = try await sessionRepository.update(session)
        
        return updatedSession
    }
}

enum ProgressionError: Error {
    case suggestionNotFound
    case sessionNotFound
    case exerciseNotFound
}
```

### 3.4 Create Repository Implementation
**File**: `GymBo/Data/Repositories/SwiftDataProgressionSuggestionRepository.swift`  
**Time**: 1 hour

**Steps**:
1. Follow existing repository patterns
2. Implement all protocol methods
3. Handle SwiftData operations correctly
4. Add proper error handling

### 3.5 Create Mapper
**File**: `GymBo/Data/Mappers/ProgressionSuggestionMapper.swift`  
**Time**: 30 minutes

**Steps**:
1. Convert between Domain and Entity
2. Handle all enum conversions
3. Ensure no data loss

**Validation**:
- [ ] All use cases compile
- [ ] Repository pattern consistent with existing code
- [ ] Error handling comprehensive
- [ ] Async/await used correctly

---

## 🎨 Phase 4: UI Integration (4-5 hours)

### 4.1 Create Progression Suggestion Card
**File**: `GymBo/Presentation/Views/ActiveWorkout/Components/ProgressionSuggestionCard.swift`  
**Time**: 2 hours

**Steps**:
1. Follow existing card component patterns
2. Use existing color scheme and typography
3. Add acceptance/dismissal actions
4. Include confidence badge

```swift
struct ProgressionSuggestionCard: View {
    
    let suggestion: DomainProgressionSuggestion
    let currentWeight: Double
    let currentReps: Int
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Progressionsvorschlag")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                ConfidenceBadge(level: suggestion.confidence)
            }
            
            // Suggestion content
            VStack(alignment: .leading, spacing: 12) {
                if suggestion.type == .weightIncrease {
                    weightSuggestionView
                } else if suggestion.type == .repsIncrease {
                    repsSuggestionView
                }
                
                // Reasoning
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warum dieser Vorschlag?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(suggestion.reasoning, id: \.self) { reason in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption2)
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button("Jetzt übernehmen") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Ignorieren") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var weightSuggestionView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Gewicht erhöhen")
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack {
                    Text("\(currentWeight, specifier: "%.1f")")
                        .strikethrough()
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("\(suggestion.suggestedWeight, specifier: "%.1f") kg")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
            }
            Spacer()
        }
    }
    
    private var repsSuggestionView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Wiederholungen erhöhen")
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack {
                    Text("\(currentReps)")
                        .strikethrough()
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("\(suggestion.suggestedReps) Reps")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
            }
            Spacer()
        }
    }
}

struct ConfidenceBadge: View {
    let level: DomainProgressionSuggestion.ConfidenceLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.caption2)
            Text(confidenceText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(confidenceColor.opacity(0.2))
        .foregroundColor(confidenceColor)
        .cornerRadius(12)
    }
    
    private var confidenceIcon: String {
        switch level {
        case .high: return "checkmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "questionmark.circle.fill"
        }
    }
    
    private var confidenceText: String {
        switch level {
        case .high: return "Hoch"
        case .medium: return "Mittel"
        case .low: return "Niedrig"
        }
    }
    
    private var confidenceColor: Color {
        switch level {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}
```

### 4.2 Integrate into ActiveWorkoutSheetView
**File**: `GymBo/Presentation/Views/ActiveWorkout/ActiveWorkoutSheetView.swift`  
**Time**: 2 hours

**Steps**:
1. Add @State variables for suggestion management
2. Add suggestion check after exercise completion
3. Insert suggestion card in appropriate location
4. Handle acceptance/dismissal actions

```swift
// Add to existing ActiveWorkoutSheetView
@State private var progressionSuggestion: DomainProgressionSuggestion?
@State private var showProgressionCard = false
@State private var currentExerciseId: UUID?

// Add to existing body (after exercise completion check)
if showProgressionCard, let suggestion = progressionSuggestion {
    ProgressionSuggestionCard(
        suggestion: suggestion,
        currentWeight: currentExerciseWeight,
        currentReps: currentExerciseReps,
        onAccept: {
            Task {
                await acceptProgressionSuggestion(suggestion)
            }
        },
        onDismiss: {
            withAnimation {
                showProgressionCard = false
                progressionSuggestion = nil
            }
        }
    )
    .padding(.horizontal)
    .transition(.move(edge: .bottom).combined(with: .opacity))
}

// Add new methods
private func checkForProgressionSuggestion(exerciseId: UUID) async {
    guard let sessionId = sessionStore.currentSession?.id else { return }
    
    do {
        let useCase = GenerateProgressionSuggestionUseCase(
            sessionRepository: sessionRepository,
            userProfileRepository: userProfileRepository,
            progressionEngine: LinearProgressionEngine(),
            suggestionRepository: suggestionRepository
        )
        
        if let suggestion = try await useCase.execute(exerciseId: exerciseId, sessionId: sessionId) {
            await MainActor.run {
                self.progressionSuggestion = suggestion
                self.currentExerciseId = exerciseId
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.showProgressionCard = true
                }
            }
        }
    } catch {
        print("⚠️ Failed to check for progression suggestion: \(error)")
    }
}

private func acceptProgressionSuggestion(_ suggestion: DomainProgressionSuggestion) async {
    guard let sessionId = sessionStore.currentSession?.id,
          let exerciseId = currentExerciseId else { return }
    
    do {
        let useCase = AcceptProgressionSuggestionUseCase(
            suggestionRepository: suggestionRepository,
            sessionRepository: sessionRepository
        )
        
        let updatedSession = try await useCase.execute(
            suggestionId: suggestion.id,
            sessionId: sessionId,
            exerciseId: exerciseId
        )
        
        await MainActor.run {
            sessionStore.setCurrentSession(updatedSession)
            withAnimation {
                showProgressionCard = false
                progressionSuggestion = nil
            }
        }
    } catch {
        print("⚠️ Failed to accept progression suggestion: \(error)")
    }
}
```

### 4.3 Update SessionStore
**File**: `GymBo/Presentation/Stores/SessionStore.swift`  
**Time**: 1 hour

**Steps**:
1. Add methods for progression suggestions
2. Integrate with existing session management
3. Ensure thread safety

```swift
// Add to SessionStore
func generateProgressionSuggestion(exerciseId: UUID) async throws -> DomainProgressionSuggestion? {
    guard let sessionId = currentSession?.id else { return nil }
    
    let useCase = GenerateProgressionSuggestionUseCase(
        sessionRepository: sessionRepository,
        userProfileRepository: userProfileRepository,
        progressionEngine: LinearProgressionEngine(),
        suggestionRepository: suggestionRepository
    )
    
    return try await useCase.execute(exerciseId: exerciseId, sessionId: sessionId)
}

func acceptProgressionSuggestion(_ suggestion: DomainProgressionSuggestion) async throws {
    guard let sessionId = currentSession?.id,
          let exercise = currentSession?.exercises.first(where: { $0.exerciseId == suggestion.exerciseId }) else {
        throw SessionStoreError.sessionNotAvailable
    }
    
    let useCase = AcceptProgressionSuggestionUseCase(
        suggestionRepository: suggestionRepository,
        sessionRepository: sessionRepository
    )
    
    let updatedSession = try await useCase.execute(
        suggestionId: suggestion.id,
        sessionId: sessionId,
        exerciseId: exercise.exerciseId
    )
    
    setCurrentSession(updatedSession)
}
```

**Validation**:
- [ ] Card appears correctly after exercise completion
- [ ] Acceptance updates session correctly
- [ ] Dismissal removes card properly
- [ ] Animations work smoothly
- [ ] No memory leaks or performance issues

---

## ⚙️ Phase 5: Settings (Optional, 2-3 hours)

### 5.1 Create Progression Preferences
**File**: `GymBo/Domain/Entities/ProgressionPreferences.swift`  
**Time**: 1 hour

### 5.2 Create Settings UI
**File**: `GymBo/Presentation/Views/Settings/ProgressionSettingsView.swift`  
**Time**: 2 hours

---

## 🧪 Testing Strategy

### Unit Tests
- ProgressionEngineTests.swift (2 hours)
- UseCase tests (1.5 hours)
- Repository tests (1 hour)

### Integration Tests
- End-to-end flow (1 hour)
- Migration tests (1 hour)

### UI Tests
- Card appearance and interaction (1 hour)

---

## 📊 Quality Gates & Checkpoints

### After Each Phase:
1. **Code Review**: All changes reviewed against patterns
2. **Unit Tests**: All new tests pass (>90% coverage)
3. **Integration**: Existing functionality unaffected
4. **Performance**: No regressions in app launch/memory

### Before Release:
1. **Migration Testing**: V6→V7 migration successful
2. **End-to-End Testing**: Complete user flow works
3. **Device Testing**: Tested on multiple iOS versions
4. **Performance Profiling**: No blocking operations

---

## 🚨 Risk Mitigation

### High-Risk Areas:
- Schema migration (test thoroughly)
- UI integration in complex view (incremental changes)
- Performance with large datasets (lazy loading)

### Mitigation Strategies:
- Implement feature flags for gradual rollout
- Add extensive logging for debugging
- Create fallback mechanisms for edge cases
- Monitor performance metrics in production

---

## 📝 Documentation Requirements

### Code Documentation:
- All new files with proper headers
- Complex logic with inline comments
- Public APIs with documentation comments

### Architecture Documentation:
- Update component diagrams
- Document new data flows
- Add migration guide for future developers

---

## 🔄 Deployment Strategy

### Phase 1-4: Internal Testing
- Feature branch testing
- QA team validation
- Performance benchmarking

### Release: Gradual Rollout
- Feature flag controlled
- Monitor crash reports
- User feedback collection
- Performance metrics tracking

---

## 📞 Support Information

### Who to Contact:
- **Architecture Questions**: Lead iOS Developer
- **UI/UX Questions**: Product Designer
- **Testing Questions**: QA Team Lead

### Debugging Resources:
- Session logs with timestamps
- Crash report templates
- Performance profiling guides
- Migration rollback procedures

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-31  
**Next Review**: After Phase 1 completion  
**Approvals**: Pending architecture review