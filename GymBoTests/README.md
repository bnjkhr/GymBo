# GymBo Tests

**130+ automatisierte Tests für die GymBo Fitness-Tracking App**

---

## Quick Start

### Tests ausführen

```bash
# In Xcode: Cmd + U

# Im Terminal:
xcodebuild test -scheme GymBo -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet
```

### Dokumentation

- **📖 [TEST_DOKUMENTATION.md](../Docs/TEST_DOKUMENTATION.md)** - Umfangreiche Dokumentation
- **🚀 [TEST_ANLEITUNG.md](../Docs/TEST_ANLEITUNG.md)** - Praktische Anleitung

---

## Test-Übersicht

### Statistiken

- **130+ Tests** insgesamt
- **~85% Coverage** im Domain Layer
- **Alle Tests grün** ✅
- **Test-Ausführungszeit**: < 10 Sekunden

### Test-Kategorien

| Kategorie | Anzahl Tests | Coverage |
|-----------|--------------|----------|
| Use Cases | 63+ | ~85% |
| Mapper | 25+ | ~70% |
| Entities | 40+ | ~90% |
| UI Tests | 5+ | ~5% |

---

## Struktur

```
GymBoTests/
├── Mocks/                      # Mock-Objekte
│   ├── MockSessionRepository.swift
│   ├── MockWorkoutRepository.swift
│   ├── MockExerciseRepository.swift
│   ├── MockHealthKitService.swift
│   ├── MockFeatureFlagService.swift
│   └── MockUserProfileRepository.swift
├── Helpers/                    # Test-Helpers
│   └── TestDataFactory.swift
├── UseCases/                   # Use Case Tests
│   ├── CompleteSetUseCaseTests.swift (13 Tests)
│   ├── StartSessionUseCaseTests.swift (13 Tests)
│   ├── CreateWorkoutUseCaseTests.swift (20 Tests)
│   └── EndSessionUseCaseTests.swift (17 Tests)
├── Mappers/                    # Mapper Tests
│   └── SessionMapperTests.swift (25+ Tests)
├── Entities/                   # Entity Tests
│   ├── SessionSetTests.swift (20+ Tests)
│   └── WorkoutTests.swift (20+ Tests)
└── README.md                   # Diese Datei
```

---

## Wichtige Test-Dateien

### Use Case Tests

Tests für Business Logic im Domain Layer:

- **CompleteSetUseCaseTests** - Testen des Set-Completion Flows
- **StartSessionUseCaseTests** - Testen des Session-Start Flows
- **CreateWorkoutUseCaseTests** - Testen der Workout-Erstellung
- **EndSessionUseCaseTests** - Testen des Session-End Flows

### Mapper Tests

Tests für Domain↔Data Konvertierung:

- **SessionMapperTests** - Round-Trip Tests, Sortierung, Datenintegrität

### Entity Tests

Tests für Domain Entities:

- **SessionSetTests** - Value Semantics, toggleCompletion(), Equatable/Hashable
- **WorkoutTests** - Value Semantics, Initialization, Equatable/Hashable

---

## Test-Philosophie

### Was wird getestet?

✅ **Fokus auf Domain Layer** - Dort liegt die Business Logic
✅ **Fehlerbehandlung** - Alle Error Cases
✅ **Edge Cases** - Extreme Werte, leere Daten, etc.
✅ **Business Rules** - z.B. Auto-Finish, nur eine aktive Session
✅ **Datenintegrität** - Mapper Round-Trips

### Was wird NICHT getestet?

❌ **Presentation Layer** - Stores/Views (zu komplex, wenig Nutzen)
❌ **Infrastructure Layer** - Services werden gemockt
❌ **SwiftData Details** - Integration Tests geplant für später

### Warum dieser Ansatz?

1. **Schnelle Tests** - Unit Tests laufen in < 10 Sekunden
2. **Hohe Coverage** - 85%+ im wichtigsten Layer (Domain)
3. **Wartbar** - Tests sind einfach zu verstehen und zu erweitern
4. **Zuverlässig** - Keine Flaky Tests durch Mocks

---

## Einen neuen Test schreiben

### 1. Test-Datei erstellen

```swift
import XCTest
@testable import GymBo

@MainActor
final class YourUseCaseTests: XCTestCase {

    var sut: DefaultYourUseCase!
    var mockRepository: MockSessionRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockSessionRepository()
        sut = DefaultYourUseCase(repository: mockRepository)
    }

    override func tearDown() async throws {
        mockRepository.reset()
        sut = nil
        try await super.tearDown()
    }
}
```

### 2. Test schreiben

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

### 3. Verschiedene Szenarien testen

- ✅ Success Case
- ✅ Error Cases (ungültige IDs, Repository-Fehler, etc.)
- ✅ Edge Cases (leere Daten, extreme Werte, etc.)

---

## Best Practices

### ✅ DO

- **Verwende TestDataFactory** für Test-Daten
- **Given-When-Then** Struktur nutzen
- **Hilfreiche Fehlermeldungen** in Assertions
- **Tests isolieren** - keine Shared State
- **Mocks zurücksetzen** in tearDown
- **Klare Namen** - `test[Method]_[Scenario]_[Result]`

### ❌ DON'T

- **Keine UI Tests für alles** - Sie sind langsam
- **Kein Shared State** zwischen Tests
- **Keine echten Services** - immer Mocks verwenden
- **Keine Flaky Tests** - deterministisch sein
- **Keine langsamen Tests** - < 1 Sekunde pro Test

---

## Häufige Probleme

### Problem: Test schlägt fehl

**Lösung**:
1. Error-Message lesen
2. Breakpoint setzen und debuggen
3. Mock überprüfen - wird `reset()` aufgerufen?
4. Dokumentation lesen

### Problem: Tests sind langsam

**Lösung**:
1. UI Tests minimieren
2. Mocks verwenden statt echte Services
3. Parallele Ausführung aktivieren (Standard in Xcode)

### Problem: Flaky Tests

**Lösung**:
1. `async/await` statt Callbacks verwenden
2. Mocks für zeitabhängigen Code
3. Tests isolieren (setUp/tearDown korrekt nutzen)

---

## Nächste Schritte

### Geplante Erweiterungen

- [ ] Tests für fehlende Use Cases (UpdateSet, AddSet, etc.)
- [ ] Integration Tests für Repositories
- [ ] Performance Tests für kritische Operationen
- [ ] Mehr UI Tests mit Accessibility Identifiers
- [ ] Snapshot Tests für UI-Komponenten

### Coverage-Ziele

| Layer | Aktuell | Ziel |
|-------|---------|------|
| Use Cases | ~85% | 90% |
| Entities | ~90% | 95% |
| Mapper | ~70% | 85% |
| Repositories | ~0% | 60% |

---

## Ressourcen

### Dokumentation
- 📖 [TEST_DOKUMENTATION.md](../Docs/TEST_DOKUMENTATION.md) - Umfangreiche Doku mit allen Details
- 🚀 [TEST_ANLEITUNG.md](../Docs/TEST_ANLEITUNG.md) - Praktische Anleitung zum Ausführen und Schreiben von Tests

### Beispiele
Schauen Sie sich vorhandene Tests als Beispiele an:
- `CompleteSetUseCaseTests.swift`
- `StartSessionUseCaseTests.swift`
- `SessionMapperTests.swift`
- `SessionSetTests.swift`

### Apple Docs
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

---

## Zusammenfassung

✅ **130+ Tests** geschrieben
✅ **Mock-Infrastruktur** komplett
✅ **TestDataFactory** für einfache Test-Daten
✅ **85%+ Coverage** im Domain Layer
✅ **Dokumentation** vorhanden
✅ **Best Practices** etabliert

**Die Tests sind Ihr Sicherheitsnetz** - je mehr Sie haben, desto sicherer können Sie Änderungen machen!

---

**Viel Erfolg beim Testen! 🧪**
