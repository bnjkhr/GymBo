# Apple Health Integration - Implementierungsvorschlag
**GymBo V2 - HealthKit Integration gemäß Clean Architecture**

**Version:** 1.1  
**Erstellt:** 2025-10-27  
**Aktualisiert:** 2025-10-27  
**Status:** 🚧 IN PROGRESS

## ⚠️ Wichtige Entscheidungen

- **Apple Watch Support:** NICHT implementieren (vorerst)
- **Heart Rate Streaming:** Wird SPÄTER in Live Activity integriert (nicht jetzt)
- **Fokus:** Körpermaße-Import (Gewicht & Größe) für bessere Kalorienberechnung  

---

## Inhaltsverzeichnis

1. [Übersicht & Ziele](#übersicht--ziele)
2. [Was wird mit Apple Health synchronisiert?](#was-wird-mit-apple-health-synchronisiert)
3. [Architektur-Design](#architektur-design)
4. [Implementierungs-Schichten](#implementierungs-schichten)
5. [Datenfluss-Diagramme](#datenfluss-diagramme)
6. [User Flows & UX](#user-flows--ux)
7. [Berechtigungen & Privacy](#berechtigungen--privacy)
8. [Implementierungs-Roadmap](#implementierungs-roadmap)
9. [Testing-Strategie](#testing-strategie)
10. [Edge Cases & Error Handling](#edge-cases--error-handling)

---

## Übersicht & Ziele

### 🎯 Hauptziele

1. **Automatische Workout-Synchronisation** - Jede Session wird automatisch als HKWorkout in Apple Health gespeichert
2. **Herzfrequenz-Tracking** - Live-Herzfrequenz während des Trainings (falls Apple Watch verbunden)
3. **Kalorien-Export** - Geschätzte aktive Energie basierend auf Workout-Intensität
4. **Körpermaße-Import** - Gewicht & Größe aus Health-App importieren (optional)
5. **Seamless Integration** - User merkt kaum, dass Sync läuft (fire-and-forget)

### ✅ Was funktioniert bereits (v1.x)?

Laut Konzept (`TECHNICAL_CONCEPT_V2.md`) hat v1.x bereits:
- ✅ HealthKit Integration (automatisch, transparent)
- ✅ Rest Timer mit HealthKit-Anbindung

**Zu klären:** Aktueller Stand der v1.x Implementation prüfen

### 🆕 Was neu in V2?

- **Clean Architecture Pattern** - HealthKit als Infrastructure Layer
- **Protocol-basierte Abstraktion** - Testbar & austauschbar
- **Robustes Error Handling** - Graceful degradation bei fehlenden Permissions
- **Optimierte Performance** - Background sync, keine UI-Blockierung
- **Erweiterte Metrics** - Mehr Datentypen (Herzfrequenz-Variabilität, VO2max optional)

---

## Was wird mit Apple Health synchronisiert?

### 📤 Export (GymBo → Health)

| Datentyp | HKQuantityType | Wann | Priorität |
|----------|----------------|------|-----------|
| **Workout Session** | `HKWorkoutTypeIdentifier` | Nach Workout-Ende | 🔴 High |
| **Aktive Energie** | `activeEnergyBurned` | Nach Workout-Ende | 🔴 High |
| **Herzfrequenz** | `heartRate` | Live während Workout (Watch) | 🟡 Medium |
| **Trainingszeit** | (Teil von HKWorkout) | Nach Workout-Ende | 🔴 High |
| **Trainingsvolumen** | Metadata in HKWorkout | Nach Workout-Ende | 🟢 Low |

### 📥 Import (Health → GymBo)

| Datentyp | HKQuantityType | Wann | Priorität | UI-Location |
|----------|----------------|------|-----------|-------------|
| **Körpergewicht** | `bodyMass` | Bei Onboarding + manuell | 🟡 Medium | Profile |
| **Körpergröße** | `height` | Bei Onboarding | 🟢 Low | Profile |
| **Ruhepuls** | `restingHeartRate` | Optional für Analytics | 🟢 Low | Statistics |

### 🔄 Bidirektional

Aktuell: **Nur Export**  
Zukunft (v2.2+): Import von externen Workouts (z.B. Apple Fitness+) zur Streak-Berechnung

---

## Architektur-Design

### 🏗️ Clean Architecture Layers

```
┌──────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                        │
│                                                               │
│  SessionStore                                                │
│  ├─ startSession()                                           │
│  ├─ endSession()                                             │
│  └─ observeHeartRate() [Watch]                              │
│         │                                                     │
├─────────┼─────────────────────────────────────────────────────┤
│         ▼                                                     │
│                      DOMAIN LAYER                             │
│                                                               │
│  StartSessionUseCase                                         │
│  ├─ Dependencies: HealthKitServiceProtocol                  │
│  └─ Execute: Start HKWorkout + persist session              │
│                                                               │
│  EndSessionUseCase                                           │
│  ├─ Dependencies: HealthKitServiceProtocol                  │
│  └─ Execute: End HKWorkout + save metrics                   │
│                                                               │
│  ImportBodyMetricsUseCase [NEW]                             │
│  └─ Execute: Fetch weight/height from Health               │
│         │                                                     │
├─────────┼─────────────────────────────────────────────────────┤
│         ▼                                                     │
│                       DATA LAYER                              │
│                                                               │
│  HealthKitRepository [NEW]                                   │
│  ├─ fetchBodyMass() async -> Result<Double, Error>         │
│  ├─ fetchHeight() async -> Result<Double, Error>           │
│  └─ saveWorkout(session) async -> Result<Void, Error>      │
│         │                                                     │
├─────────┼─────────────────────────────────────────────────────┤
│         ▼                                                     │
│                   INFRASTRUCTURE LAYER                        │
│                                                               │
│  HealthKitService                                            │
│  ├─ HKHealthStore                                           │
│  ├─ HKWorkoutSession                                        │
│  ├─ HKLiveWorkoutBuilder                                    │
│  └─ HKObserverQuery (Heart Rate)                           │
└──────────────────────────────────────────────────────────────┘
```

### 🎯 Dependency Flow

```
SessionStore (Presentation)
    ↓ calls
StartSessionUseCase (Domain)
    ↓ depends on (Protocol)
HealthKitServiceProtocol (Domain)
    ↑ implemented by
HealthKitService (Infrastructure)
    ↓ uses
HKHealthStore (HealthKit Framework)
```

**Vorteil:** Domain Layer kennt nur Protocols → 100% testbar ohne echtes HealthKit!

---

## Implementierungs-Schichten

### 1️⃣ Domain Layer (Protocols & Use Cases)

#### Protocol: HealthKitServiceProtocol

```swift
// Domain/Services/HealthKitServiceProtocol.swift

/// Protocol für HealthKit-Integration (in Domain Layer)
/// Implementation in Infrastructure Layer
protocol HealthKitServiceProtocol {
    
    // MARK: - Permissions
    
    /// Request read/write permissions für alle benötigten Datentypen
    func requestAuthorization() async -> Result<Void, HealthKitError>
    
    /// Check ob Permissions bereits erteilt
    func isAuthorized() -> Bool
    
    // MARK: - Workout Session
    
    /// Start HKWorkoutSession (für Live Activities & Background support)
    func startWorkoutSession(
        type: WorkoutActivityType,
        startDate: Date
    ) async -> Result<String, HealthKitError> // Returns session ID
    
    /// End HKWorkoutSession und speichere finales Workout
    func endWorkoutSession(
        sessionId: String,
        endDate: Date,
        totalEnergyBurned: Double, // kcal
        totalDistance: Double?, // meters (optional)
        metadata: [String: Any]
    ) async -> Result<Void, HealthKitError>
    
    /// Pause workout (für Pause-Feature)
    func pauseWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError>
    
    /// Resume workout
    func resumeWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError>
    
    // MARK: - Heart Rate Streaming (Apple Watch)
    
    /// Live Heart Rate während Workout (AsyncStream für SwiftUI)
    func observeHeartRate() -> AsyncStream<Int>
    
    // MARK: - Body Metrics Import
    
    /// Fetch latest body weight from Health
    func fetchBodyMass() async -> Result<Double, HealthKitError> // kg
    
    /// Fetch height from Health
    func fetchHeight() async -> Result<Double, HealthKitError> // cm
    
    // MARK: - Query Historical Data
    
    /// Fetch resting heart rate (für Analytics)
    func fetchRestingHeartRate() async -> Result<Int, HealthKitError> // bpm
}

/// Domain-level error type
enum HealthKitError: LocalizedError {
    case notAvailableOnDevice // iPad, Mac
    case permissionDenied
    case dataNotAvailable
    case sessionAlreadyActive
    case sessionNotFound
    case saveFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailableOnDevice:
            return "Apple Health ist auf diesem Gerät nicht verfügbar"
        case .permissionDenied:
            return "Bitte erlaube Zugriff auf Apple Health in den Einstellungen"
        case .dataNotAvailable:
            return "Keine Daten in Apple Health verfügbar"
        case .sessionAlreadyActive:
            return "Es läuft bereits eine aktive Health-Session"
        case .sessionNotFound:
            return "Health-Session nicht gefunden"
        case .saveFailed(let error):
            return "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
}

/// Workout type mapping (Domain → HealthKit)
enum WorkoutActivityType {
    case traditionalStrengthTraining
    case functionalStrengthTraining
    case coreTraining
    case flexibility
    case other
    
    // Mapped in Infrastructure Layer to HKWorkoutActivityType
}
```

#### Use Case: StartSessionUseCase (erweitert)

```swift
// Domain/UseCases/Session/StartSessionUseCase.swift

protocol StartSessionUseCaseProtocol {
    func execute(workoutId: UUID) async -> Result<WorkoutSession, SessionError>
}

final class StartSessionUseCase: StartSessionUseCaseProtocol {
    
    private let workoutRepository: WorkoutRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol // ← NEW
    
    init(
        workoutRepository: WorkoutRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.workoutRepository = workoutRepository
        self.sessionRepository = sessionRepository
        self.healthKitService = healthKitService
    }
    
    func execute(workoutId: UUID) async -> Result<WorkoutSession, SessionError> {
        // 1. Fetch workout
        guard case .success(let workout) = await workoutRepository.fetch(id: workoutId) else {
            return .failure(.workoutNotFound)
        }
        
        // 2. Check no active session
        guard await sessionRepository.activeSession() == nil else {
            return .failure(.sessionAlreadyActive)
        }
        
        // 3. Create domain session
        let session = WorkoutSession.create(from: workout)
        
        // 4. Persist session
        guard case .success = await sessionRepository.save(session) else {
            return .failure(.persistenceFailed)
        }
        
        // 5. Start HealthKit session (fire-and-forget, non-blocking)
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            let result = await self.healthKitService.startWorkoutSession(
                type: .traditionalStrengthTraining,
                startDate: session.startDate
            )
            
            if case .success(let sessionId) = result {
                // Store HealthKit session ID in session for later
                var updatedSession = session
                updatedSession.healthKitSessionId = sessionId
                _ = await self.sessionRepository.update(updatedSession)
                
                print("✅ HealthKit session started: \(sessionId)")
            } else if case .failure(let error) = result {
                // Log but don't fail the workout
                print("⚠️ HealthKit session failed to start: \(error)")
            }
        }
        
        return .success(session)
    }
}
```

**Key Decision:** HealthKit Start ist **non-blocking**!
- Workout startet sofort, auch wenn HealthKit Permission fehlt
- User kann trainieren, auch wenn Health-App nicht erreichbar
- Fehler werden geloggt, aber User nicht gestört

#### Use Case: EndSessionUseCase (erweitert)

```swift
// Domain/UseCases/Session/EndSessionUseCase.swift

final class EndSessionUseCase: EndSessionUseCaseProtocol {
    
    private let sessionRepository: SessionRepositoryProtocol
    private let healthKitService: HealthKitServiceProtocol
    
    func execute(sessionId: UUID) async -> Result<CompletedSession, SessionError> {
        // 1. Fetch active session
        guard var session = await sessionRepository.fetch(id: sessionId) else {
            return .failure(.sessionNotFound)
        }
        
        // 2. Mark as completed
        session.endDate = Date()
        session.status = .completed
        
        // 3. Calculate metrics
        let duration = session.duration // seconds
        let totalVolume = session.totalVolume // kg
        let exerciseCount = session.exercises.count
        
        // 4. Estimate calories (simple formula)
        let estimatedCalories = calculateCalories(
            duration: duration,
            volume: totalVolume,
            exerciseCount: exerciseCount
        )
        
        session.estimatedCalories = estimatedCalories
        
        // 5. Persist updated session
        guard case .success = await sessionRepository.update(session) else {
            return .failure(.persistenceFailed)
        }
        
        // 6. Save to HealthKit (background, non-blocking)
        if let healthKitSessionId = session.healthKitSessionId {
            Task.detached(priority: .background) { [weak self] in
                guard let self = self else { return }
                
                let metadata: [String: Any] = [
                    "totalVolume": totalVolume,
                    "exerciseCount": exerciseCount,
                    "workoutName": session.workoutName
                ]
                
                let result = await self.healthKitService.endWorkoutSession(
                    sessionId: healthKitSessionId,
                    endDate: session.endDate!,
                    totalEnergyBurned: estimatedCalories,
                    totalDistance: nil,
                    metadata: metadata
                )
                
                if case .success = result {
                    print("✅ HealthKit workout saved")
                } else if case .failure(let error) = result {
                    print("⚠️ HealthKit save failed: \(error)")
                }
            }
        }
        
        return .success(session.toCompleted())
    }
    
    // MARK: - Helpers
    
    /// Simplified calorie estimation
    /// Source: MET (Metabolic Equivalent of Task) for strength training
    /// MET for strength training: ~6.0 (moderate) to 8.0 (vigorous)
    private func calculateCalories(
        duration: TimeInterval,
        volume: Double,
        exerciseCount: Int
    ) -> Double {
        let hours = duration / 3600.0
        let met: Double = 6.0 // Conservative estimate
        let bodyWeight: Double = 80.0 // TODO: Get from user profile
        
        // Formula: Calories = MET × body weight (kg) × time (hours)
        let calories = met * bodyWeight * hours
        
        return calories
    }
}
```

#### Use Case: ImportBodyMetricsUseCase (NEW)

```swift
// Domain/UseCases/Profile/ImportBodyMetricsUseCase.swift

protocol ImportBodyMetricsUseCaseProtocol {
    func execute() async -> Result<BodyMetrics, HealthKitError>
}

struct BodyMetrics {
    let weight: Double // kg
    let height: Double // cm
    let lastUpdated: Date
}

final class ImportBodyMetricsUseCase: ImportBodyMetricsUseCaseProtocol {
    
    private let healthKitService: HealthKitServiceProtocol
    private let profileRepository: ProfileRepositoryProtocol
    
    init(
        healthKitService: HealthKitServiceProtocol,
        profileRepository: ProfileRepositoryProtocol
    ) {
        self.healthKitService = healthKitService
        self.profileRepository = profileRepository
    }
    
    func execute() async -> Result<BodyMetrics, HealthKitError> {
        // Fetch both in parallel
        async let weightResult = healthKitService.fetchBodyMass()
        async let heightResult = healthKitService.fetchHeight()
        
        let (weight, height) = await (weightResult, heightResult)
        
        guard case .success(let weightValue) = weight else {
            return .failure(.dataNotAvailable)
        }
        
        guard case .success(let heightValue) = height else {
            return .failure(.dataNotAvailable)
        }
        
        let metrics = BodyMetrics(
            weight: weightValue,
            height: heightValue,
            lastUpdated: Date()
        )
        
        // Update user profile (background)
        Task {
            var profile = await profileRepository.fetch()
            profile.weight = weightValue
            profile.height = heightValue
            _ = await profileRepository.save(profile)
        }
        
        return .success(metrics)
    }
}
```

---

### 2️⃣ Infrastructure Layer (HealthKit Implementation)

#### HealthKitService Implementation

```swift
// Infrastructure/HealthKit/HealthKitService.swift

import HealthKit

final class HealthKitService: HealthKitServiceProtocol {
    
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    private var activeWorkoutBuilder: HKLiveWorkoutBuilder?
    private var activeWorkoutSession: HKWorkoutSession?
    private var heartRateContinuation: AsyncStream<Int>.Continuation?
    
    // MARK: - Init
    
    init() {
        self.healthStore = HKHealthStore()
    }
    
    // MARK: - Permissions
    
    func requestAuthorization() async -> Result<Void, HealthKitError> {
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            return .failure(.notAvailableOnDevice)
        }
        
        // Define data types to read/write
        let typesToWrite: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .height)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        ]
        
        // Request authorization
        do {
            try await healthStore.requestAuthorization(
                toShare: typesToWrite,
                read: typesToRead
            )
            return .success(())
        } catch {
            return .failure(.permissionDenied)
        }
    }
    
    func isAuthorized() -> Bool {
        let status = healthStore.authorizationStatus(
            for: HKWorkoutType.workoutType()
        )
        return status == .sharingAuthorized
    }
    
    // MARK: - Workout Session
    
    func startWorkoutSession(
        type: WorkoutActivityType,
        startDate: Date
    ) async -> Result<String, HealthKitError> {
        // Check if session already active
        guard activeWorkoutSession == nil else {
            return .failure(.sessionAlreadyActive)
        }
        
        // Map domain type to HKWorkoutActivityType
        let hkActivityType = type.toHKWorkoutActivityType()
        
        // Create configuration
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = hkActivityType
        configuration.locationType = .indoor
        
        do {
            // Create session
            let session = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: configuration
            )
            
            // Create builder
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            
            // Start session
            session.startActivity(with: startDate)
            try await builder.beginCollection(at: startDate)
            
            // Store references
            self.activeWorkoutSession = session
            self.activeWorkoutBuilder = builder
            
            return .success(session.identifier.uuidString)
            
        } catch {
            return .failure(.saveFailed(underlying: error))
        }
    }
    
    func endWorkoutSession(
        sessionId: String,
        endDate: Date,
        totalEnergyBurned: Double,
        totalDistance: Double?,
        metadata: [String: Any]
    ) async -> Result<Void, HealthKitError> {
        guard let session = activeWorkoutSession,
              let builder = activeWorkoutBuilder,
              session.identifier.uuidString == sessionId else {
            return .failure(.sessionNotFound)
        }
        
        do {
            // End collection
            try await builder.endCollection(at: endDate)
            
            // End session
            session.end()
            
            // Finalize workout
            let workout = try await builder.finishWorkout()
            
            // Add metadata (optional)
            let metadataToSave = metadata.compactMapValues { $0 as? String }
            if !metadataToSave.isEmpty {
                try await healthStore.addMetadata(
                    metadataToSave,
                    to: workout
                )
            }
            
            // Clean up
            self.activeWorkoutSession = nil
            self.activeWorkoutBuilder = nil
            
            return .success(())
            
        } catch {
            return .failure(.saveFailed(underlying: error))
        }
    }
    
    func pauseWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
        guard let session = activeWorkoutSession,
              session.identifier.uuidString == sessionId else {
            return .failure(.sessionNotFound)
        }
        
        session.pause()
        return .success(())
    }
    
    func resumeWorkoutSession(sessionId: String) async -> Result<Void, HealthKitError> {
        guard let session = activeWorkoutSession,
              session.identifier.uuidString == sessionId else {
            return .failure(.sessionNotFound)
        }
        
        session.resume()
        return .success(())
    }
    
    // MARK: - Heart Rate Streaming
    
    func observeHeartRate() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.heartRateContinuation = continuation
            
            let heartRateType = HKQuantityType.quantityType(
                forIdentifier: .heartRate
            )!
            
            let query = HKAnchoredObjectQuery(
                type: heartRateType,
                predicate: nil,
                anchor: nil,
                limit: HKObjectQueryNoLimit
            ) { query, samples, deletedObjects, anchor, error in
                guard let samples = samples as? [HKQuantitySample] else { return }
                
                let heartRates = samples.compactMap { sample -> Int? in
                    let unit = HKUnit.count().unitDivided(by: .minute())
                    return Int(sample.quantity.doubleValue(for: unit))
                }
                
                if let latest = heartRates.last {
                    continuation.yield(latest)
                }
            }
            
            query.updateHandler = { query, samples, deletedObjects, anchor, error in
                guard let samples = samples as? [HKQuantitySample] else { return }
                
                let heartRates = samples.compactMap { sample -> Int? in
                    let unit = HKUnit.count().unitDivided(by: .minute())
                    return Int(sample.quantity.doubleValue(for: unit))
                }
                
                if let latest = heartRates.last {
                    continuation.yield(latest)
                }
            }
            
            self.healthStore.execute(query)
            
            continuation.onTermination = { @Sendable _ in
                self.healthStore.stop(query)
            }
        }
    }
    
    // MARK: - Body Metrics
    
    func fetchBodyMass() async -> Result<Double, HealthKitError> {
        let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )
        
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { query, samples, error in
            // Handle result
        }
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(returning: .failure(.saveFailed(underlying: error)))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: .failure(.dataNotAvailable))
                    return
                }
                
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: .success(kg))
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchHeight() async -> Result<Double, HealthKitError> {
        let heightType = HKQuantityType.quantityType(forIdentifier: .height)!
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(returning: .failure(.saveFailed(underlying: error)))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: .failure(.dataNotAvailable))
                    return
                }
                
                let cm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                continuation.resume(returning: .success(cm))
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchRestingHeartRate() async -> Result<Int, HealthKitError> {
        let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(returning: .failure(.saveFailed(underlying: error)))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: .failure(.dataNotAvailable))
                    return
                }
                
                let unit = HKUnit.count().unitDivided(by: .minute())
                let bpm = Int(sample.quantity.doubleValue(for: unit))
                continuation.resume(returning: .success(bpm))
            }
            
            healthStore.execute(query)
        }
    }
}

// MARK: - Helpers

extension WorkoutActivityType {
    func toHKWorkoutActivityType() -> HKWorkoutActivityType {
        switch self {
        case .traditionalStrengthTraining:
            return .traditionalStrengthTraining
        case .functionalStrengthTraining:
            return .functionalStrengthTraining
        case .coreTraining:
            return .coreTraining
        case .flexibility:
            return .flexibility
        case .other:
            return .other
        }
    }
}
```

---

### 3️⃣ Presentation Layer (UI Integration)

#### SessionStore (erweitert)

```swift
// Presentation/Stores/SessionStore.swift

@MainActor
final class SessionStore: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var state: State = .idle
    @Published private(set) var activeSession: WorkoutSession?
    @Published private(set) var currentHeartRate: Int? = nil // NEW: Live HR
    @Published private(set) var healthKitAvailable: Bool = false // NEW
    @Published private(set) var healthKitAuthorized: Bool = false // NEW
    
    // MARK: - Dependencies
    
    private let startSessionUseCase: StartSessionUseCaseProtocol
    private let endSessionUseCase: EndSessionUseCaseProtocol
    private let healthKitService: HealthKitServiceProtocol
    
    private var heartRateTask: Task<Void, Never>?
    
    init(
        startSessionUseCase: StartSessionUseCaseProtocol,
        endSessionUseCase: EndSessionUseCaseProtocol,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.startSessionUseCase = startSessionUseCase
        self.endSessionUseCase = endSessionUseCase
        self.healthKitService = healthKitService
        
        // Check HealthKit availability
        self.healthKitAvailable = HKHealthStore.isHealthDataAvailable()
        self.healthKitAuthorized = healthKitService.isAuthorized()
    }
    
    // MARK: - Public Interface
    
    func startSession(workoutId: UUID) async {
        state = .starting
        
        let result = await startSessionUseCase.execute(workoutId: workoutId)
        
        switch result {
        case .success(let session):
            activeSession = session
            state = .active
            
            // Start heart rate observation (if Watch connected)
            startHeartRateObservation()
            
        case .failure(let error):
            state = .error(error)
        }
    }
    
    func endSession() async {
        guard let session = activeSession else { return }
        
        state = .ending
        
        // Stop heart rate observation
        heartRateTask?.cancel()
        heartRateTask = nil
        
        let result = await endSessionUseCase.execute(sessionId: session.id)
        
        switch result {
        case .success(let completedSession):
            activeSession = nil
            currentHeartRate = nil
            state = .completed(completedSession)
            
        case .failure(let error):
            state = .error(error)
        }
    }
    
    // MARK: - HealthKit Integration
    
    func requestHealthKitPermission() async {
        let result = await healthKitService.requestAuthorization()
        
        if case .success = result {
            healthKitAuthorized = true
        }
    }
    
    private func startHeartRateObservation() {
        guard healthKitAuthorized else { return }
        
        heartRateTask = Task {
            for await heartRate in healthKitService.observeHeartRate() {
                await MainActor.run {
                    self.currentHeartRate = heartRate
                }
            }
        }
    }
}
```

#### ProfileStore (NEW)

```swift
// Presentation/Stores/ProfileStore.swift

@MainActor
final class ProfileStore: ObservableObject {
    
    @Published private(set) var profile: UserProfile?
    @Published private(set) var bodyMetrics: BodyMetrics?
    @Published private(set) var isImportingFromHealth = false
    
    private let profileRepository: ProfileRepositoryProtocol
    private let importBodyMetricsUseCase: ImportBodyMetricsUseCaseProtocol
    
    init(
        profileRepository: ProfileRepositoryProtocol,
        importBodyMetricsUseCase: ImportBodyMetricsUseCaseProtocol
    ) {
        self.profileRepository = profileRepository
        self.importBodyMetricsUseCase = importBodyMetricsUseCase
    }
    
    func importFromHealthKit() async {
        isImportingFromHealth = true
        defer { isImportingFromHealth = false }
        
        let result = await importBodyMetricsUseCase.execute()
        
        if case .success(let metrics) = result {
            bodyMetrics = metrics
        }
    }
}
```

---

### 4️⃣ UI Components

#### HealthKit Permission Sheet

```swift
// Presentation/Views/Onboarding/HealthKitPermissionView.swift

struct HealthKitPermissionView: View {
    
    @EnvironmentObject var sessionStore: SessionStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            // Title
            Text("Apple Health Integration")
                .font(.title)
                .fontWeight(.bold)
            
            // Benefits
            VStack(alignment: .leading, spacing: 16) {
                benefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Automatisches Tracking",
                    subtitle: "Alle Workouts werden automatisch in Health gespeichert"
                )
                
                benefitRow(
                    icon: "heart.fill",
                    title: "Herzfrequenz",
                    subtitle: "Live-Herzfrequenz mit Apple Watch (optional)"
                )
                
                benefitRow(
                    icon: "flame.fill",
                    title: "Kalorien",
                    subtitle: "Verbrannte Kalorien werden exportiert"
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        await sessionStore.requestHealthKitPermission()
                        dismiss()
                    }
                } label: {
                    Text("Zugriff erlauben")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appOrange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Später")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appOrange)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
```

#### Heart Rate Badge (in Active Workout)

```swift
// Presentation/Views/ActiveWorkout/Components/HeartRateBadge.swift

struct HeartRateBadge: View {
    
    let heartRate: Int?
    
    var body: some View {
        if let hr = heartRate {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .symbolEffect(.pulse, options: .repeating)
                
                Text("\(hr)")
                    .font(.headline)
                    .monospacedDigit()
                
                Text("BPM")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
        }
    }
}

// Usage in ActiveWorkoutSheetView
struct ActiveWorkoutSheetView: View {
    @EnvironmentObject var sessionStore: SessionStore
    
    var body: some View {
        VStack {
            // Header with Heart Rate
            HStack {
                Text("Push Day")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HeartRateBadge(heartRate: sessionStore.currentHeartRate)
            }
            .padding()
            
            // Rest of workout UI...
        }
    }
}
```

---

## Datenfluss-Diagramme

### 📊 Workout Start Flow mit HealthKit

```
┌─────────────────────────────────────────────────────────────┐
│  USER: Taps "Start Workout" Button                          │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  SessionStore.startSession(workoutId)                        │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  StartSessionUseCase.execute()                               │
│  ├─ 1. Fetch workout from WorkoutRepository                 │
│  ├─ 2. Create WorkoutSession                                │
│  ├─ 3. Save to SessionRepository (SwiftData)                │
│  └─ 4. Start HealthKit session (background)                 │
└────────────┬────────────────────────────────────────────────┘
             │
             ├───────────────────┬─────────────────────────────┐
             │                   │                             │
             ▼                   ▼                             ▼
┌──────────────────┐  ┌────────────────────┐  ┌──────────────────┐
│  SwiftData       │  │  HealthKitService  │  │  UI Update       │
│  Session saved   │  │  startWorkout()    │  │  state = .active │
└──────────────────┘  └────────────┬───────┘  └──────────────────┘
                                   │
                                   ▼
                      ┌────────────────────────┐
                      │  HKWorkoutSession      │
                      │  ├─ Start timer        │
                      │  ├─ Begin collection   │
                      │  └─ Return sessionId   │
                      └────────────────────────┘
```

### 📊 Workout End Flow mit HealthKit

```
┌─────────────────────────────────────────────────────────────┐
│  USER: Taps "End Workout" Button                            │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  SessionStore.endSession()                                   │
└────────────┬────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│  EndSessionUseCase.execute()                                 │
│  ├─ 1. Mark session as completed                            │
│  ├─ 2. Calculate calories                                   │
│  ├─ 3. Update SessionRepository                             │
│  └─ 4. End HealthKit session (background)                   │
└────────────┬────────────────────────────────────────────────┘
             │
             ├───────────────────┬─────────────────────────────┐
             │                   │                             │
             ▼                   ▼                             ▼
┌──────────────────┐  ┌────────────────────┐  ┌──────────────────┐
│  SwiftData       │  │  HealthKitService  │  │  UI Update       │
│  Session updated │  │  endWorkoutSession │  │  Show summary    │
└──────────────────┘  └────────────┬───────┘  └──────────────────┘
                                   │
                                   ▼
                      ┌────────────────────────┐
                      │  HKWorkout saved       │
                      │  ├─ Duration           │
                      │  ├─ Calories           │
                      │  ├─ Metadata (volume)  │
                      │  └─ Visible in Health  │
                      └────────────────────────┘
```

---

## User Flows & UX

### 🎯 Onboarding Flow

```
App Launch (First Time)
    ↓
Welcome Screen
    ↓
Basic Info (Name, Experience)
    ↓
┌────────────────────────────────────┐
│ HealthKit Permission Request       │
│ (Optional - can skip)              │
│                                    │
│ [✓] Workout tracking              │
│ [✓] Heart rate                    │
│ [✓] Calories                      │
│ [✓] Import weight/height          │
│                                    │
│ [Allow Access]  [Maybe Later]     │
└────────────────────────────────────┘
    ↓
Home Screen (Ready to start)
```

**Key Points:**
- ✅ Optional - User kann skippen
- ✅ Contextual - Beim Onboarding, nicht mitten im Workout
- ✅ Value First - Benefits klar kommunizieren

### 🏋️ During Workout

```
Active Workout View
┌──────────────────────────────────────┐
│  Push Day                 ❤️ 142 BPM │ ← Live Heart Rate (if Watch)
│  ────────────────────────────────────│
│  Exercise 1 of 8                     │
│  Bankdrücken                         │
│  [Set list...]                       │
└──────────────────────────────────────┘
```

**Behavior:**
- Heart rate updates every 2-3 seconds (smoothed)
- No interruption if HealthKit unavailable
- Badge hidden if no Watch connected

### 📊 After Workout

```
Workout Summary
┌──────────────────────────────────────┐
│  Push Day - Completed ✅              │
│  ────────────────────────────────────│
│  Duration: 42:15                     │
│  Volume: 2,450 kg                    │
│  Calories: 245 kcal                  │
│  ────────────────────────────────────│
│  ❤️ Avg HR: 142 bpm                 │
│  Max HR: 178 bpm                     │
│  ────────────────────────────────────│
│  ✓ Saved to Apple Health             │ ← Confirmation
│  [View in Health App] →              │
└──────────────────────────────────────┘
```

### ⚙️ Settings Flow

```
Profile Tab → Settings
┌──────────────────────────────────────┐
│  Apple Health                        │
│  ────────────────────────────────────│
│  Status: Connected ✓                 │
│                                      │
│  [Import Weight & Height from Health]│
│  [View Workouts in Health App]       │
│  [Reconnect] (if permission denied)  │
│  ────────────────────────────────────│
│  Import Body Metrics                 │
│  Weight: 82.5 kg (from Health)       │
│  Height: 180 cm (from Health)        │
│  Last synced: Today, 14:30           │
└──────────────────────────────────────┘
```

---

## Berechtigungen & Privacy

### 📜 Info.plist Entries (Required)

```xml
<!-- Info.plist -->

<key>NSHealthShareUsageDescription</key>
<string>GymBo benötigt Zugriff auf deine Gesundheitsdaten, um Gewicht und Herzfrequenz zu importieren.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>GymBo möchte deine Workouts und verbrannten Kalorien in Apple Health speichern.</string>
```

### 🔐 Permission Handling

**Read Permissions:**
- Heart Rate (für Live-Tracking)
- Body Mass (für Import)
- Height (für Import)
- Resting Heart Rate (für Analytics)

**Write Permissions:**
- Workouts (HKWorkout)
- Active Energy Burned (kcal)

### 🎯 Privacy Best Practices

1. **Minimum Necessary Data** - Nur abfragen, was wirklich genutzt wird
2. **Contextual Requests** - Nicht beim App-Start, sondern bei Bedarf
3. **Graceful Degradation** - App funktioniert auch ohne HealthKit
4. **Transparent Communication** - User weiß, was und warum synchronisiert wird
5. **User Control** - Jederzeit in Settings deaktivierbar

---

## Implementierungs-Roadmap

### 🚀 Phase 1: Core Integration (Priority: 🔴 High - 8-10 Std)

**Scope:** Grundlegende HealthKit-Integration ohne UI

**Tasks:**
- [x] `HealthKitServiceProtocol` im Domain Layer
- [x] `HealthKitService` Implementation (Infrastructure)
- [x] `WorkoutActivityType` enum + mapping
- [x] Error handling (`HealthKitError`)
- [x] Extend `StartSessionUseCase` mit HealthKit
- [x] Extend `EndSessionUseCase` mit HealthKit
- [x] Session Entity: Add `healthKitSessionId` field
- [x] DI Container: Register `HealthKitService`

**Testing:**
- [ ] Unit Tests für Use Cases (mit Mock)
- [ ] Integration Test (echter HKHealthStore im Simulator)
- [ ] Test ohne Permissions (Graceful degradation)

**Deliverable:** Workouts werden automatisch in Health gespeichert (no UI yet)

---

### 🚀 Phase 2: Permissions & Onboarding (Priority: 🔴 High - 3-4 Std)

**Scope:** User kann Permissions erteilen

**Tasks:**
- [ ] `HealthKitPermissionView.swift` (Onboarding Sheet)
- [ ] Add to Onboarding Flow (optional step)
- [ ] Settings: HealthKit Status + Reconnect Button
- [ ] Info.plist: Add usage descriptions
- [ ] SessionStore: Add `healthKitAvailable` & `healthKitAuthorized`

**Testing:**
- [ ] Test Onboarding Flow (Grant/Deny/Skip)
- [ ] Test Settings Reconnect

**Deliverable:** User sieht Permission Request & kann HealthKit aktivieren

---

### 🚀 Phase 3: Heart Rate Streaming (Priority: 🟡 Medium - 4-5 Std)

**Scope:** Live-Herzfrequenz während Workout (Apple Watch required)

**Tasks:**
- [ ] `observeHeartRate()` in `HealthKitService`
- [ ] SessionStore: Add `currentHeartRate` @Published
- [ ] `HeartRateBadge.swift` Component
- [ ] Integrate in `ActiveWorkoutSheetView`
- [ ] Test with Apple Watch (Simulator + real device)

**Testing:**
- [ ] Test mit Apple Watch verbunden
- [ ] Test ohne Apple Watch (Badge hidden)
- [ ] Test Permission denied (Graceful)

**Deliverable:** Live Heart Rate Badge in Active Workout View

---

### 🚀 Phase 4: Body Metrics Import (Priority: 🟡 Medium - 3-4 Std)

**Scope:** Import Gewicht & Größe aus Health

**Tasks:**
- [ ] `ImportBodyMetricsUseCase.swift`
- [ ] `ProfileStore.swift` (NEW)
- [ ] `ProfileView.swift` - Add HealthKit Import Button
- [ ] `fetchBodyMass()` & `fetchHeight()` in `HealthKitService`
- [ ] UserProfile Entity: Add `weight` & `height` fields

**Testing:**
- [ ] Test Import (mit vorhandenen Daten)
- [ ] Test Import (keine Daten verfügbar)
- [ ] Test Permission denied

**Deliverable:** User kann Körpermaße aus Health importieren

---

### 🚀 Phase 5: Polish & Analytics (Priority: 🟢 Low - 2-3 Std)

**Scope:** Zusätzliche Features & Analytics

**Tasks:**
- [ ] Workout Summary: "✓ Saved to Apple Health" Badge
- [ ] Settings: "View in Health App" Link (deep link)
- [ ] Statistics View: Import Resting HR (optional)
- [ ] Error logging & monitoring
- [ ] Performance optimization (batch queries)

**Testing:**
- [ ] Test deep link to Health App
- [ ] Performance: Large workout count (100+ sessions)

**Deliverable:** Polierte UX + zusätzliche Features

---

## Testing-Strategie

### 🧪 Unit Tests (Domain Layer)

```swift
// DomainTests/UseCases/StartSessionUseCaseTests.swift

final class StartSessionUseCaseTests: XCTestCase {
    
    var sut: StartSessionUseCase!
    var mockHealthKitService: MockHealthKitService!
    
    override func setUp() {
        mockHealthKitService = MockHealthKitService()
        // ... other mocks
        
        sut = StartSessionUseCase(
            workoutRepository: mockWorkoutRepo,
            sessionRepository: mockSessionRepo,
            healthKitService: mockHealthKitService
        )
    }
    
    func test_startSession_callsHealthKitService() async {
        // Given
        mockWorkoutRepo.fetchResult = .success(.fixture())
        mockSessionRepo.activeSessionResult = nil
        mockHealthKitService.startSessionResult = .success("session-123")
        
        // When
        _ = await sut.execute(workoutId: UUID())
        
        // Then
        XCTAssertEqual(mockHealthKitService.startSessionCallCount, 1)
    }
    
    func test_startSession_whenHealthKitFails_stillStartsWorkout() async {
        // Given
        mockHealthKitService.startSessionResult = .failure(.permissionDenied)
        
        // When
        let result = await sut.execute(workoutId: UUID())
        
        // Then
        XCTAssertTrue(result.isSuccess, "Workout should start even if HealthKit fails")
    }
}

// Mock
final class MockHealthKitService: HealthKitServiceProtocol {
    var startSessionCallCount = 0
    var startSessionResult: Result<String, HealthKitError> = .success("mock-id")
    
    func startWorkoutSession(type: WorkoutActivityType, startDate: Date) async -> Result<String, HealthKitError> {
        startSessionCallCount += 1
        return startSessionResult
    }
    
    // ... implement other methods
}
```

### 🧪 Integration Tests (mit realem HealthKit)

```swift
// IntegrationTests/HealthKitIntegrationTests.swift

final class HealthKitIntegrationTests: XCTestCase {
    
    var healthKitService: HealthKitService!
    
    override func setUp() async throws {
        healthKitService = HealthKitService()
        
        // Request permissions (only runs once)
        _ = await healthKitService.requestAuthorization()
    }
    
    func test_startAndEndWorkout_savesToHealth() async throws {
        // Start workout
        let startResult = await healthKitService.startWorkoutSession(
            type: .traditionalStrengthTraining,
            startDate: Date()
        )
        
        guard case .success(let sessionId) = startResult else {
            XCTFail("Failed to start session")
            return
        }
        
        // Wait 2 seconds
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // End workout
        let endResult = await healthKitService.endWorkoutSession(
            sessionId: sessionId,
            endDate: Date(),
            totalEnergyBurned: 250.0,
            totalDistance: nil,
            metadata: ["test": "integration"]
        )
        
        XCTAssertTrue(endResult.isSuccess)
    }
    
    func test_fetchBodyMass_returnsValue() async throws {
        let result = await healthKitService.fetchBodyMass()
        
        // May fail if no data in Health
        if case .success(let weight) = result {
            XCTAssertGreaterThan(weight, 0)
        }
    }
}
```

### 🧪 UI Tests (End-to-End)

```swift
// UITests/HealthKitUITests.swift

final class HealthKitUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        app.launchArguments = ["--uitesting", "--mock-healthkit-authorized"]
        app.launch()
    }
    
    func test_onboarding_showsHealthKitPermission() {
        // Navigate to onboarding
        app.buttons["Get Started"].tap()
        
        // Should show HealthKit permission screen
        XCTAssertTrue(app.staticTexts["Apple Health Integration"].exists)
        XCTAssertTrue(app.buttons["Zugriff erlauben"].exists)
        XCTAssertTrue(app.buttons["Später"].exists)
    }
    
    func test_workout_showsHeartRateBadge() {
        // Start workout
        app.buttons["Push Day"].tap()
        app.buttons["Start Workout"].tap()
        
        // Should show heart rate badge (if authorized)
        XCTAssertTrue(app.staticTexts["BPM"].exists)
    }
}
```

---

## Edge Cases & Error Handling

### ⚠️ Edge Cases

| Edge Case | Behavior | Implementation |
|-----------|----------|----------------|
| **HealthKit not available** (iPad) | App funktioniert normal, HealthKit-Features disabled | Check `HKHealthStore.isHealthDataAvailable()` |
| **Permission denied** | App funktioniert normal, kein Health-Sync | Graceful degradation, Store `.healthKitAuthorized = false` |
| **No Apple Watch** | Heart Rate Badge hidden | Check if `heartRate` is nil |
| **App Force Quit during Workout** | HealthKit Session läuft weiter! | Cleanup beim nächsten App-Start |
| **No body metrics in Health** | Import returns error | Show "Keine Daten verfügbar" message |
| **Network unavailable** | Health-Sync ist lokal, kein Problem | No impact |
| **Low battery during Workout** | HealthKit stoppt automatisch | OS handles, app notified via delegate |

### 🛡️ Error Recovery

```swift
// Graceful degradation example

func startSession(workoutId: UUID) async {
    // Start workout (always succeeds)
    let result = await startSessionUseCase.execute(workoutId: workoutId)
    
    // HealthKit fails silently in background
    // User can still train!
}

// Error notification (optional)
if !healthKitAuthorized {
    // Show banner: "Health-Sync deaktiviert - in Einstellungen aktivieren"
    showHealthKitDisabledBanner()
}
```

### 🔍 Debugging & Logging

```swift
// Structured logging für HealthKit

AppLogger.healthKit.info("HealthKit session started", metadata: [
    "sessionId": "\(sessionId)",
    "workoutType": "\(type)"
])

AppLogger.healthKit.error("HealthKit save failed", metadata: [
    "error": "\(error.localizedDescription)",
    "sessionId": "\(sessionId)"
])
```

---

## Zusammenfassung

### ✅ Was wird implementiert?

1. **Automatisches Workout-Tracking** - Jede Session → HKWorkout
2. **Live-Herzfrequenz** - Apple Watch Integration (optional)
3. **Kalorien-Export** - Geschätzte Werte basierend auf Workout
4. **Körpermaße-Import** - Gewicht & Größe aus Health (optional)
5. **Permission Handling** - Onboarding + Settings

### 🎯 Architektur-Highlights

- ✅ **Clean Architecture** - HealthKit in Infrastructure Layer
- ✅ **Protocol-based** - 100% testbar ohne echtes HealthKit
- ✅ **Non-blocking** - HealthKit-Fehler blockieren Workout nicht
- ✅ **Graceful Degradation** - App funktioniert auch ohne HealthKit
- ✅ **Performance** - Background sync, keine UI-Blockierung

### 📊 Aufwand-Schätzung

| Phase | Priorität | Aufwand | Status |
|-------|-----------|---------|--------|
| Core Integration | 🔴 High | 8-10 Std | 📋 Geplant |
| Permissions & Onboarding | 🔴 High | 3-4 Std | 📋 Geplant |
| Heart Rate Streaming | 🟡 Medium | 4-5 Std | 📋 Geplant |
| Body Metrics Import | 🟡 Medium | 3-4 Std | 📋 Geplant |
| Polish & Analytics | 🟢 Low | 2-3 Std | 📋 Geplant |

**Total:** ~20-26 Stunden

### 🚀 Nächste Schritte

1. **Review dieses Dokuments** - Feedback & Adjustments
2. **Phase 1 starten** - Core Integration implementieren
3. **Testing** - Unit Tests + Integration Tests
4. **UI Integration** - Permissions + Heart Rate Badge
5. **User Testing** - Mit echter Apple Watch testen

---

**Last Updated:** 2025-10-27
