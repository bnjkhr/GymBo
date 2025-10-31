# SwiftData Migration Strategy

## Problem Statement

Während der Entwicklung haben wir `isFinished` zu `SessionExerciseEntity` hinzugefügt, was zu einem **Breaking Change** führte:
- Alte Datenbank: SessionExerciseEntity OHNE `isFinished` 
- Neue Datenbank: SessionExerciseEntity MIT `isFinished`
- Result: **Migration Error** → App fiel auf In-Memory Storage zurück

**Development Solution:** Simulator komplett löschen (`xcrun simctl erase all`)

**Production Problem:** User-Daten dürfen NIEMALS gelöscht werden!

---

## ⚠️ CRITICAL: Inverse Relationships Nach Migration (2025-10-31)

### Problem
Bei Schema-Migrationen stellt SwiftData **inverse relationships NICHT automatisch** wieder her, auch bei `lightweight` Migrationen!

**Symptome:**
- `SessionExerciseEntity.session = nil` nach Migration
- `SessionSetEntity.exercise = nil` nach Migration  
- `SessionExerciseGroupEntity.session = nil` nach Migration
- **Result:** `assertionFailure` in `ModelContext.save()` → App Crash

### Lösung: Custom Migration mit Relationship Restoration

**IMMER verwenden bei Schema-Migrationen:**
```swift
static let migrateVXtoVY = MigrationStage.custom(
    fromVersion: SchemaVX.self,
    toVersion: SchemaVY.self,
    didMigrate: { context in
        // ✅ FIX: Restore inverse relationships
        let sessionDescriptor = FetchDescriptor<SchemaVY.WorkoutSessionEntity>()
        if let sessions = try? context.fetch(sessionDescriptor) {
            for session in sessions {
                for exercise in session.exercises {
                    if exercise.session == nil {
                        exercise.session = session  // ✅ Restore
                    }
                    for set in exercise.sets {
                        if set.exercise == nil {
                            set.exercise = exercise  // ✅ Restore
                        }
                    }
                }
            }
            try? context.save()
        }
    }
)
```

**Siehe:** `GymBoMigrationPlan.swift` - Migration V1→V2 und V5→V6 für vollständige Implementierung

---

## SwiftData Migration Konzepte

### 1. Lightweight Migration (Automatic)
SwiftData kann **automatisch** migrieren bei:
- ✅ Neue optionale Properties hinzufügen
- ✅ Properties umbenennen (mit `@Attribute(.originalName:)`)
- ✅ Relationships ändern
- ✅ Entities hinzufügen/löschen

**ABER NICHT bei:**
- ❌ Neue **required** (non-optional) Properties ohne Default
- ❌ Type Changes (String → Int)
- ❌ Komplexe Daten-Transformationen

### 2. Custom Migration (VersionedSchema)
Für komplexe Changes brauchen wir:
- **VersionedSchema**: Jede Schema-Version wird explizit definiert
- **SchemaMigrationPlan**: Definiert Migration-Schritte zwischen Versionen
- **willMigrate/didMigrate**: Custom Logic für Daten-Transformation

---

## Production-Ready Migration Plan

### Phase 1: Schema Versioning Setup (JETZT)

**1.1 Erstelle Initial Schema Version**
```swift
// GymBo/Data/Migration/SchemaV1.swift
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [
            WorkoutSessionEntity.self,
            SessionExerciseEntity.self,
            SessionSetEntity.self,
            ExerciseEntity.self,
            WorkoutEntity.self
        ]
    }
    
    @Model
    final class SessionExerciseEntity {
        @Attribute(.unique) var id: UUID
        var exerciseId: UUID
        var notes: String?
        var restTimeToNext: TimeInterval?
        var orderIndex: Int
        var isFinished: Bool = false  // ✅ NEU in V1
        
        @Relationship(deleteRule: .cascade, inverse: \SessionSetEntity.exercise)
        var sets: [SessionSetEntity]
        var session: WorkoutSessionEntity?
        
        init(id: UUID = UUID(), exerciseId: UUID, notes: String? = nil, 
             restTimeToNext: TimeInterval? = nil, orderIndex: Int = 0, 
             isFinished: Bool = false, sets: [SessionSetEntity] = []) {
            self.id = id
            self.exerciseId = exerciseId
            self.notes = notes
            self.restTimeToNext = restTimeToNext
            self.orderIndex = orderIndex
            self.isFinished = isFinished
            self.sets = sets
        }
    }
    
    // ... alle anderen Entities ...
}
```

**1.2 Erstelle Migration Plan**
```swift
// GymBo/Data/Migration/GymBoMigrationPlan.swift
import SwiftData

enum GymBoMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]  // Später: [SchemaV1.self, SchemaV2.self, ...]
    }
    
    static var stages: [MigrationStage] {
        []  // Keine Migrations nötig (noch)
    }
}
```

**1.3 Update ModelContainer**
```swift
// GymBo/GymBoApp.swift
let container = try ModelContainer(
    for: SchemaV1.self,
    migrationPlan: GymBoMigrationPlan.self,
    configurations: ModelConfiguration(
        schema: Schema([
            WorkoutSessionEntity.self,
            SessionExerciseEntity.self,
            SessionSetEntity.self,
            ExerciseEntity.self,
            WorkoutEntity.self
        ])
    )
)
```

---

### Phase 2: Future Migrations (Wenn neue Fields benötigt werden)

**Beispiel: Wir wollen `restCompletedAt: Date?` zu SessionExerciseEntity hinzufügen**

**2.1 Erstelle SchemaV2**
```swift
// GymBo/Data/Migration/SchemaV2.swift
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [/* same as V1 */]
    }
    
    @Model
    final class SessionExerciseEntity {
        // ... alle bisherigen Fields ...
        var isFinished: Bool = false
        var restCompletedAt: Date? = nil  // ✅ NEU in V2
        
        // ... Rest ...
    }
}
```

**2.2 Update Migration Plan**
```swift
enum GymBoMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]  // ✅ V2 hinzugefügt
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            // Optional: Pre-migration logic
            print("🔄 Starting migration V1 → V2")
        },
        didMigrate: { context in
            // Optional: Post-migration data fixes
            print("✅ Migration V1 → V2 complete")
        }
    )
}
```

---

## Best Practices für Schema Changes

### ✅ SAFE Changes (Lightweight Migration)

**1. Neue Optional Properties**
```swift
// V1
var notes: String?

// V2 - ADD optional field
var tags: [String]? = nil  // ✅ SAFE
```

**2. Rename Properties**
```swift
// V2
@Attribute(.originalName: "restTimeToNext") 
var restDuration: TimeInterval?  // ✅ SAFE with originalName
```

**3. Delete Optional Properties**
```swift
// V1
var temporaryFlag: Bool? = nil

// V2 - DELETE optional
// (just remove it)  // ✅ SAFE
```

---

### ⚠️ CAREFUL Changes (Custom Migration Required)

**1. Neue Required Properties**
```swift
// V1
var name: String

// V2 - ADD required field
var category: String = "General"  // ⚠️ Needs default value
```

**2. Type Changes**
```swift
// V1
var duration: Int  // seconds

// V2
var duration: TimeInterval  // Double
// ⚠️ Needs custom migration to convert Int → Double
```

**3. Relationship Changes**
```swift
// V1
var workout: WorkoutEntity?

// V2
var workouts: [WorkoutEntity]  // one-to-many
// ⚠️ Needs custom migration to wrap in array
```

---

### ❌ DANGEROUS Changes (High Risk)

**1. Delete Required Properties WITHOUT Migration**
```swift
// V1
var criticalData: String

// V2
// (removed)  // ❌ DATA LOSS! Needs migration to preserve
```

**2. Ändern von @Attribute(.unique)**
```swift
// V1
@Attribute(.unique) var email: String

// V2
var email: String  // removed .unique
// ❌ Kann zu Duplikaten führen
```

---

## Testing Strategy

### 1. Unit Tests für Migrations
```swift
import XCTest
@testable import GymBo

final class MigrationTests: XCTestCase {
    func testMigrateV1toV2() throws {
        // Create V1 container with test data
        let v1Container = createV1ContainerWithData()
        
        // Perform migration
        let v2Container = try ModelContainer(
            for: SchemaV2.self,
            migrationPlan: GymBoMigrationPlan.self
        )
        
        // Verify data integrity
        let context = v2Container.mainContext
        let exercises = try context.fetch(FetchDescriptor<SessionExerciseEntity>())
        
        XCTAssertEqual(exercises.count, 5)
        XCTAssertNotNil(exercises.first?.restCompletedAt)
    }
}
```

### 2. Beta Testing Checklist
- [ ] Export Testdaten aus aktueller Version
- [ ] Test Migration auf verschiedenen iOS Versionen
- [ ] Verify alle Daten sind korrekt migriert
- [ ] Test Rollback-Scenario (alte App Version öffnen)
- [ ] Monitor Crashlytics für Migration-Errors

---

## Decision Matrix: Wann welcher Ansatz?

| Scenario | Lightweight | Custom | Breaking Change |
|----------|-------------|--------|-----------------|
| Neue optional Property | ✅ | - | - |
| Neue required Property mit Default | ✅ | - | - |
| Property umbenennen | ✅ (@Attribute) | - | - |
| Type ändern | - | ✅ | - |
| Komplexe Transformation | - | ✅ | - |
| Fundamental Schema Redesign | - | - | ⚠️ Requires data export/import |

---

## Current Status (2025-10-23)

**Schema Version:** Implicit V1 (kein Versioning aktiv)
**Migration Support:** ❌ Nicht implementiert
**Risk Level:** 🔴 HIGH - Breaking changes führen zu Datenverlust

**TODO for Production:**
1. [ ] Implement SchemaV1 mit allen aktuellen Entities
2. [ ] Setup GymBoMigrationPlan
3. [ ] Update ModelContainer mit Migration Support
4. [ ] Add Unit Tests für Migrations
5. [ ] Document alle zukünftigen Schema Changes VOR Implementation

---

## Lessons Learned

### ❌ Was wir FALSCH gemacht haben:
1. **Kein Schema Versioning** von Anfang an
2. **Required Field hinzugefügt** ohne Migration Plan
3. **Keine Tests** für Schema Changes

### ✅ Was wir in Zukunft RICHTIG machen:
1. **IMMER Schema Versioning** nutzen
2. **IMMER Migration Plan** erstellen VOR Schema Changes
3. **IMMER Tests** schreiben für Migrations
4. **DOKUMENTIEREN** jedes Schema Change mit Reason

---

## References

- [Apple: Model your schema with SwiftData (WWDC23)](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [HackingWithSwift: SwiftData Migrations](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-complex-migration-using-versionedschema)
- [Medium: Handling SwiftData Schema Migrations](https://medium.com/@manikantasirumalla5/handling-swiftdata-schema-migrations-a-practical-guide-e58e05bd3071)

---

**Last Updated:** 2025-10-23  
**Status:** 🔴 CRITICAL - Migration Support muss implementiert werden vor Production Release!
