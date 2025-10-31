# GymBo Test-Anleitung

**Quick Start Guide für das Ausführen und Schreiben von Tests**

---

## Schnellstart

### Tests ausführen (Xcode)

1. **Alle Tests ausführen**:
   ```
   Cmd + U
   ```

2. **Einzelne Test-Datei ausführen**:
   - Test Navigator öffnen: `Cmd + 5`
   - Play-Button neben Test-Datei klicken

3. **Einzelnen Test ausführen**:
   - Play-Button neben Test-Methode im Code klicken
   - Oder: Cursor in Test-Methode → `Ctrl + Option + Cmd + U`

### Tests ausführen (Terminal)

```bash
# Alle Tests
xcodebuild test -scheme GymBo -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet

# Nur Unit Tests
xcodebuild test -scheme GymBo -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:GymBoTests -quiet

# Nur UI Tests
xcodebuild test -scheme GymBo -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:GymBoUITests -quiet
```

---

## Test-Struktur verstehen

### Wo sind die Tests?

```
GymBo/
├── GymBo/                      # Produktionscode
│   ├── Domain/
│   ├── Data/
│   ├── Presentation/
│   └── Infrastructure/
├── GymBoTests/                 # Unit Tests ⭐
│   ├── Mocks/                  # Mock-Objekte
│   ├── Helpers/                # Test-Helpers
│   ├── UseCases/               # Use Case Tests
│   ├── Mappers/                # Mapper Tests
│   └── Entities/               # Entity Tests
├── GymBoUITests/               # UI Tests
└── Docs/                       # Dokumentation
    ├── TEST_DOKUMENTATION.md   # Umfangreiche Doku
    └── TEST_ANLEITUNG.md       # Diese Datei
```

### Was ist was?

| Ordner | Inhalt | Anzahl Tests |
|--------|--------|--------------|
| **Mocks/** | Mock-Objekte für Dependencies | - |
| **Helpers/** | TestDataFactory für Test-Daten | - |
| **UseCases/** | Tests für Business Logic | 63+ |
| **Mappers/** | Tests für Domain↔Data Konvertierung | 25+ |
| **Entities/** | Tests für Domain Entities | 40+ |
| **UI Tests** | End-to-End Tests | 5+ |

---

## Einen Test schreiben

### Schritt 1: Test-Datei erstellen

**Wo**: `GymBoTests/UseCases/[YourUseCase]Tests.swift`

```swift
import XCTest
@testable import GymBo

@MainActor  // Wenn async/await verwendet wird
final class YourUseCaseTests: XCTestCase {

    // MARK: - Properties
    var sut: DefaultYourUseCase!  // sut = System Under Test
    var mockRepository: MockSessionRepository!

    // MARK: - Setup & Teardown
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockSessionRepository()
        sut = DefaultYourUseCase(repository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // Tests hier schreiben...
}
```

### Schritt 2: Test-Methode schreiben

**Namenskonvention**: `test[Method]_[Scenario]_[ExpectedResult]`

```swift
func testExecute_WithValidInput_SucceedsAndSavesData() async throws {
    // Given: Test-Daten vorbereiten
    let session = TestDataFactory.createActiveSession()
    mockRepository.addSession(session)

    // When: Aktion ausführen
    try await sut.execute(sessionId: session.id)

    // Then: Ergebnis überprüfen
    XCTAssertEqual(mockRepository.updateCallCount, 1)
    XCTAssertEqual(mockRepository.lastUpdatedSession?.id, session.id)
}
```

### Schritt 3: Verschiedene Szenarien testen

**Erfolgsfall**:
```swift
func testExecute_WithValidData_Succeeds() async throws {
    // Test happy path
}
```

**Fehlerfall**:
```swift
func testExecute_WithInvalidId_ThrowsError() async {
    do {
        try await sut.execute(invalidId: UUID())
        XCTFail("Should throw error")
    } catch let error as UseCaseError {
        if case .notFound = error {
            // Erfolg - erwarteter Fehler
        } else {
            XCTFail("Wrong error type")
        }
    }
}
```

**Edge Case**:
```swift
func testExecute_WithEmptyData_HandlesGracefully() async throws {
    // Test mit extremen/ungewöhnlichen Werten
}
```

---

## Häufige Test-Patterns

### Pattern 1: Use Case Test mit Mock

```swift
func testCompleteSet_WithValidIds_CompletesSet() async throws {
    // 1. Test-Daten erstellen
    let session = TestDataFactory.createActiveSession(exerciseCount: 1, setsPerExercise: 3)
    let setId = session.exercises[0].sets[0].id

    // 2. Mock vorbereiten
    mockSessionRepository.addSession(session)

    // 3. Use Case ausführen
    try await sut.execute(
        sessionId: session.id,
        exerciseId: session.exercises[0].id,
        setId: setId
    )

    // 4. Repository-Aufrufe überprüfen
    XCTAssertEqual(mockSessionRepository.updateCallCount, 1)

    // 5. Datenänderungen überprüfen
    let updatedSession = mockSessionRepository.lastUpdatedSession
    XCTAssertNotNil(updatedSession)
    XCTAssertTrue(updatedSession!.exercises[0].sets[0].completed)
}
```

### Pattern 2: Error Handling Test

```swift
func testExecute_WithRepositoryError_ThrowsCorrectError() async {
    // Mock zu werfen konfigurieren
    mockRepository.saveError = RepositoryError.saveFailed("DB Error")

    // Versuchen auszuführen und Fehler erwarten
    do {
        try await sut.execute(data: testData)
        XCTFail("Should throw error")
    } catch let error as UseCaseError {
        // Fehlertyp überprüfen
        if case .saveFailed(let underlyingError) = error {
            XCTAssertTrue(underlyingError.localizedDescription.contains("DB Error"))
        } else {
            XCTFail("Wrong error type: \(error)")
        }
    } catch {
        XCTFail("Unexpected error: \(error)")
    }
}
```

### Pattern 3: Round-Trip Test (Mapper)

```swift
func testRoundTrip_PreservesAllData() {
    // 1. Domain-Objekt erstellen
    let originalSession = TestDataFactory.createCompletedSession()

    // 2. Domain → Entity konvertieren
    let entity = sut.toEntity(originalSession)

    // 3. Entity → Domain konvertieren
    let roundTripSession = sut.toDomain(entity)

    // 4. Vergleichen
    XCTAssertEqual(roundTripSession.id, originalSession.id)
    XCTAssertEqual(roundTripSession.workoutName, originalSession.workoutName)
    XCTAssertEqual(roundTripSession.exercises.count, originalSession.exercises.count)
    // ... weitere Felder überprüfen
}
```

### Pattern 4: Entity Value Semantics Test

```swift
func testValueType_CopyDoesNotAffectOriginal() {
    // 1. Original erstellen
    var original = TestDataFactory.createSessionSet(completed: false)

    // 2. Kopie erstellen und modifizieren
    var copy = original
    copy.toggleCompletion()
    copy.weight = 80.0

    // 3. Original sollte unverändert sein
    XCTAssertFalse(original.completed)
    XCTAssertEqual(original.weight, 60.0)

    // 4. Kopie sollte geändert sein
    XCTAssertTrue(copy.completed)
    XCTAssertEqual(copy.weight, 80.0)
}
```

---

## Test Data Factory verwenden

### Einfache Objekte

```swift
// Workout erstellen
let workout = TestDataFactory.createWorkout(
    name: "Push Day",
    defaultRestTime: 90
)

// Exercise erstellen
let exercise = TestDataFactory.createExercise(
    name: "Bench Press",
    muscleGroup: "Chest"
)

// Session erstellen
let session = TestDataFactory.createSession(
    workoutName: "Push Day",
    state: .active
)
```

### Komplexe Szenarien

```swift
// Vollständiges Workout mit Exercises
let workout = TestDataFactory.createCompleteWorkout(
    name: "Push Day",
    exerciseCount: 5  // Erstellt Workout mit 5 Exercises
)

// Aktive Session mit Sets
let session = TestDataFactory.createActiveSession(
    workoutName: "Push Day",
    exerciseCount: 3,      // 3 Exercises
    setsPerExercise: 4     // Je 4 Sets
)

// Completed Session (alle Sets completed)
let session = TestDataFactory.createCompletedSession(
    workoutName: "Push Day",
    exerciseCount: 3,
    setsPerExercise: 4,
    startDate: Date().addingTimeInterval(-3600),
    endDate: Date()
)
```

### Custom Configuration

```swift
// Session Set mit spezifischen Werten
let set = TestDataFactory.createSessionSet(
    weight: 80.0,
    reps: 8,
    completed: true,
    completedAt: Date(),
    orderIndex: 0,
    isWarmup: false,
    restTime: 120
)

// Session Exercise mit custom Sets
let sets = [
    TestDataFactory.createSessionSet(weight: 60, reps: 10),
    TestDataFactory.createSessionSet(weight: 65, reps: 8),
    TestDataFactory.createSessionSet(weight: 70, reps: 6)
]
let exercise = TestDataFactory.createSessionExercise(
    exerciseName: "Bench Press",
    sets: sets
)
```

---

## Mocks konfigurieren

### Repository Mock - Normal Usage

```swift
// 1. Mock erstellen
let mockRepo = MockSessionRepository()

// 2. Test-Daten hinzufügen
let session = TestDataFactory.createActiveSession()
mockRepo.addSession(session)

// 3. Use Case nutzt Mock
let result = try await useCase.execute(sessionId: session.id)

// 4. Aufrufe überprüfen
XCTAssertEqual(mockRepo.fetchCallCount, 1)
XCTAssertEqual(mockRepo.lastFetchedId, session.id)
```

### Repository Mock - Error Injection

```swift
// Mock zu werfen konfigurieren
mockRepo.updateError = RepositoryError.updateFailed("DB Error")

// Use Case wird Fehler werfen
do {
    try await useCase.execute()
    XCTFail("Should throw")
} catch {
    // Erwarteter Fehler
}
```

### Service Mock - Custom Return Values

```swift
// HealthKit Mock konfigurieren
let mockHealthKit = MockHealthKitService()
mockHealthKit.isHealthKitAvailable = true
mockHealthKit.startWorkoutSessionResult = .success(UUID())

// FeatureFlag Mock konfigurieren
let mockFeatureFlags = MockFeatureFlagService()
mockFeatureFlags.enableFlag(.dynamicIsland)
mockFeatureFlags.enableFlag(.liveActivities)
```

---

## XCTest Assertions

### Häufig verwendete Assertions

```swift
// Gleichheit
XCTAssertEqual(actual, expected, "Beschreibung")
XCTAssertNotEqual(actual, unexpected)

// Wahrheit
XCTAssertTrue(condition, "Sollte true sein")
XCTAssertFalse(condition, "Sollte false sein")

// Nil-Checks
XCTAssertNil(value, "Sollte nil sein")
XCTAssertNotNil(value, "Sollte nicht nil sein")

// Numerische Vergleiche
XCTAssertGreaterThan(5, 3)
XCTAssertLessThan(3, 5)
XCTAssertGreaterThanOrEqual(5, 5)
XCTAssertLessThanOrEqual(5, 5)

// Floating Point (mit Genauigkeit)
XCTAssertEqual(3.14159, 3.14, accuracy: 0.01)

// Collection Checks
XCTAssertTrue(array.isEmpty)
XCTAssertEqual(array.count, 5)
XCTAssertTrue(array.contains(element))

// Error Handling
XCTAssertThrowsError(try someFunction())
XCTAssertNoThrow(try someFunction())

// Fail (wenn Code nicht erreicht werden sollte)
XCTFail("Dieser Code sollte nicht erreicht werden")
```

### Benutzerdefinierte Fehlermeldungen

```swift
// Immer hilfreiche Fehlermeldungen hinzufügen!
XCTAssertEqual(
    session.exercises.count,
    3,
    "Session sollte 3 Exercises haben, hat aber \(session.exercises.count)"
)
```

---

## Debugging von Tests

### Test im Debug-Mode ausführen

1. **Breakpoint setzen** im Test oder im Produktionscode
2. **Test debuggen**:
   - Rechtsklick auf Test → "Debug test[MethodName]"
   - Oder: `Ctrl + Option + Cmd + U` mit Cursor im Test

### Logs anzeigen

```swift
// In Tests
print("DEBUG: Session ID = \(session.id)")
dump(session)  // Zeigt vollständige Objektstruktur

// In Produktionscode
AppLogger.debug("Session started: \(sessionId)")
```

### Test-Output anzeigen

**In Xcode**:
- Report Navigator: `Cmd + 9`
- Test-Output anzeigen: Test auswählen → Log Tab

**Im Terminal**:
```bash
# Verbose Output
xcodebuild test -scheme GymBo -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Nur Fehler
xcodebuild test -scheme GymBo -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet
```

---

## Test Coverage anzeigen

### In Xcode

1. **Test mit Coverage ausführen**:
   - Scheme bearbeiten: `Cmd + <`
   - Test → Options → "Gather coverage for targets" aktivieren
   - Test ausführen: `Cmd + U`

2. **Coverage Report öffnen**:
   - Report Navigator: `Cmd + 9`
   - Coverage Tab auswählen
   - Dateien zeigen Coverage-Prozentsatz

3. **Detaillierte Coverage**:
   - Rechtsklick auf Datei → "Show in Report Navigator"
   - Grüne Zeilen = getestet
   - Rote Zeilen = nicht getestet

### Im Terminal

```bash
# Tests mit Coverage ausführen
xcodebuild test \
  -scheme GymBo \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath ./TestResults.xcresult

# Coverage Report anzeigen
xcrun xccov view --report ./TestResults.xcresult

# Coverage als JSON exportieren
xcrun xccov view --report --json ./TestResults.xcresult > coverage.json
```

---

## Tipps & Tricks

### Schneller Tests schreiben

1. **Test-Snippet erstellen**:
   ```
   Xcode → Preferences → Code Snippets
   ```
   Snippet für Given-When-Then Pattern

2. **TestDataFactory nutzen**: Keine komplexen Objekte manuell erstellen

3. **Mocks wiederverwenden**: Alle Use Cases können dieselben Mocks nutzen

### Tests schneller machen

1. **UI Tests minimieren** - Sie sind 10-100x langsamer als Unit Tests
2. **Parallele Ausführung nutzen** (Standard in Xcode)
3. **Unnötige Waits entfernen**
4. **Mocks statt echte DB/Network verwenden**

### Tests lesbarer machen

```swift
// ❌ Schlecht - Schwer zu verstehen
func test1() async throws {
    let s = f.c()
    try await u.e(i: s.i)
    XCTAssertEqual(r.c, 1)
}

// ✅ Gut - Klar und verständlich
func testCompleteSet_WithValidIds_UpdatesRepository() async throws {
    // Given: A session with an incomplete set
    let session = TestDataFactory.createActiveSession()
    mockRepository.addSession(session)

    // When: Completing the set
    try await useCase.execute(sessionId: session.id)

    // Then: Repository should be updated once
    XCTAssertEqual(mockRepository.updateCallCount, 1)
}
```

### Flaky Tests vermeiden

**Häufige Ursachen**:
- Race Conditions
- Shared State
- Zeitabhängiger Code

**Lösungen**:
- `async/await` statt Callbacks
- `setUp/tearDown` korrekt nutzen
- Mocks für Time-dependent Code
- Tests isolieren

---

## Häufige Fehler

### Fehler 1: Mock nicht zurückgesetzt

```swift
// ❌ Problem
override func tearDown() {
    sut = nil
    // Mock nicht zurückgesetzt!
}

// ✅ Lösung
override func tearDown() async throws {
    mockRepository.reset()  // ⭐ Wichtig!
    sut = nil
    try await super.tearDown()
}
```

### Fehler 2: Async Test ohne await

```swift
// ❌ Schlecht
func testAsync() {
    sut.execute()  // Kein await - Test endet sofort!
    XCTAssertTrue(mockRepo.saveCallCount > 0)  // Wird immer fehlschlagen
}

// ✅ Gut
func testAsync() async throws {
    try await sut.execute()
    XCTAssertEqual(mockRepo.saveCallCount, 1)
}
```

### Fehler 3: Falsche Error Handling

```swift
// ❌ Schlecht
func testError() async throws {
    try await sut.execute(invalidId: UUID())  // Wirft Error, Test schlägt fehl
}

// ✅ Gut
func testError() async {
    do {
        try await sut.execute(invalidId: UUID())
        XCTFail("Should throw error")
    } catch {
        // Error wird erwartet - Test erfolgreich
    }
}
```

### Fehler 4: Tests beeinflussen sich gegenseitig

```swift
// ❌ Problem: Shared State
class MyTests: XCTestCase {
    static var sharedRepo = MockRepository()  // Shared!

    func testA() {
        sharedRepo.addSession(...)  // Beeinflusst Test B!
    }

    func testB() {
        // Sieht Session von Test A
    }
}

// ✅ Lösung: Jeder Test eigene Instanz
class MyTests: XCTestCase {
    var mockRepo: MockRepository!

    override func setUp() async throws {
        mockRepo = MockRepository()  // Neue Instanz pro Test
    }
}
```

---

## Checkliste für neue Tests

Bevor Sie einen Test als fertig markieren:

- [ ] Test hat klaren Namen (`test[Method]_[Scenario]_[Result]`)
- [ ] Test verwendet Given-When-Then Struktur
- [ ] Test hat hilfreiche Fehlermeldungen in Assertions
- [ ] Test ist isoliert (keine Shared State)
- [ ] Mocks werden in `tearDown` zurückgesetzt
- [ ] Test ist deterministisch (kein Random, kein aktuelles Datum)
- [ ] Test ist schnell (< 1 Sekunde)
- [ ] Test testet nur eine Sache
- [ ] Test deckt Success Case ab
- [ ] Test deckt Error Cases ab
- [ ] Test deckt Edge Cases ab

---

## Beispiel: Kompletter Test

```swift
import XCTest
@testable import GymBo

@MainActor
final class CompleteSetUseCaseTests: XCTestCase {

    // MARK: - Properties

    var sut: DefaultCompleteSetUseCase!
    var mockSessionRepository: MockSessionRepository!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockSessionRepository = MockSessionRepository()
        sut = DefaultCompleteSetUseCase(sessionRepository: mockSessionRepository)
    }

    override func tearDown() async throws {
        mockSessionRepository.reset()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Tests

    func testExecute_WithValidIds_CompletesSet() async throws {
        // Given: A session with an incomplete set
        let session = TestDataFactory.createActiveSession(
            exerciseCount: 1,
            setsPerExercise: 3
        )
        let exerciseId = session.exercises[0].id
        let setId = session.exercises[0].sets[0].id
        mockSessionRepository.addSession(session)

        // When: Completing the set
        try await sut.execute(
            sessionId: session.id,
            exerciseId: exerciseId,
            setId: setId
        )

        // Then: Set should be marked as completed
        XCTAssertEqual(
            mockSessionRepository.updateCallCount,
            1,
            "Should update session exactly once"
        )

        let updatedSession = mockSessionRepository.lastUpdatedSession
        XCTAssertNotNil(updatedSession, "Should have updated session")

        let updatedSet = updatedSession?.exercises[0].sets[0]
        XCTAssertEqual(
            updatedSet?.completed,
            true,
            "Set should be marked as completed"
        )
        XCTAssertNotNil(
            updatedSet?.completedAt,
            "Completion timestamp should be set"
        )
    }

    func testExecute_WithInvalidSessionId_ThrowsError() async {
        // Given: No session in repository
        let sessionId = UUID()
        let exerciseId = UUID()
        let setId = UUID()

        // When/Then: Should throw sessionNotFound error
        do {
            try await sut.execute(
                sessionId: sessionId,
                exerciseId: exerciseId,
                setId: setId
            )
            XCTFail("Should throw sessionNotFound error")
        } catch let error as UseCaseError {
            if case .sessionNotFound(let id) = error {
                XCTAssertEqual(
                    id,
                    sessionId,
                    "Error should contain correct session ID"
                )
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
```

---

## Weitere Ressourcen

### Dokumentation
- `TEST_DOKUMENTATION.md` - Umfangreiche Dokumentation mit allen Details
- Diese Datei - Praktische Anleitung zum Ausführen und Schreiben von Tests

### Beispiel-Tests
Schauen Sie sich vorhandene Tests als Beispiele an:
- `CompleteSetUseCaseTests.swift` - Einfacher Use Case Test
- `StartSessionUseCaseTests.swift` - Komplexerer Use Case mit mehreren Dependencies
- `SessionMapperTests.swift` - Mapper Tests mit Round-Trip
- `SessionSetTests.swift` - Entity Tests mit Value Semantics

### Apple Dokumentation
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

---

## Hilfe bekommen

### Test schlägt fehl?

1. **Error-Message lesen** - Oft steht die Lösung dort
2. **Breakpoint setzen** - Test im Debug-Mode laufen lassen
3. **Logs anschauen** - `print()` oder `dump()` nutzen
4. **Mock überprüfen** - Wird `reset()` in `tearDown` aufgerufen?
5. **Dokumentation lesen** - `TEST_DOKUMENTATION.md` hat mehr Details

### Neue Tests schreiben?

1. **Beispiele anschauen** - Vorhandene Tests als Vorlage nutzen
2. **Pattern verwenden** - Given-When-Then Struktur
3. **TestDataFactory nutzen** - Keine komplexen Objekte manuell erstellen
4. **Klein anfangen** - Erst Success Case, dann Edge Cases

---

**Viel Erfolg beim Testen! 🧪**

Die Tests sind Ihr Sicherheitsnetz - je mehr Sie haben, desto sicherer können Sie Änderungen machen!
