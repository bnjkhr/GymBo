# GymBo V2 - Notification Strategy

**Status:** 📋 Design Phase  
**Erstellt:** 2025-10-26  
**Ziel:** Comprehensive Notification System mit Dynamic Island & Live Activities Support

---

## 🎯 Vision & Ziele

### Strategie
**"Notifications as Workout Companion"** - Intelligente, kontextuelle Benachrichtigungen, die das Training unterstützen, ohne zu nerven.

### Kern-Prinzipien
1. **Contextual First** - Nur relevante Notifications zur richtigen Zeit
2. **Non-Intrusive** - Keine Spam-Notifications, nutzergesteuert
3. **Dynamic Island Ready** - Vorbereitet für Live Activities Integration
4. **Privacy First** - Alle Notifications optional, granulare Kontrolle
5. **Energy Efficient** - Minimaler Battery Impact

---

## 📱 Notification Types & Use Cases

### 1. Rest Timer Notifications (IMPLEMENTED ✅)
**Status:** ✅ Implementiert via UserNotifications (Local Notifications)

**Beschreibung:**
- Timer läuft ab → Notification "Pause vorbei! ⏰"
- Funktioniert mit:
  - Standard Rest Times (z.B. 90s)
  - Per-Set Rest Times (z.B. 180s, 180s, 60s)
  - Manuell angepasste Zeiten (+15s/-15s Buttons)
  - Background & Force Quit Support

**Features:**
- ✅ Notification scheduled beim Timer-Start
- ✅ Notification rescheduled bei Timer-Anpassung (+/-15s)
- ✅ Auto-cancel bei manuellem Timer-Stop
- ✅ Auto-clear Timer nach Ablauf → UI zeigt Workout-Timer

**Implementation:**
- `RestTimerStateManager` mit `UNUserNotificationCenter`
- Permissions automatisch requested beim ersten Timer
- Debug-Logging für Permission-Status

---

### 2. Workout Reminder Notifications 🔔

**Use Case:** Erinnere User an ihre geplanten Training-Zeiten

**Trigger:**
- Nutzer trainiert regelmäßig Mo/Mi/Fr um 18:00
- System lernt Pattern
- Sendet Reminder 30 Min vorher
- Nur wenn heute noch kein Training

**Notification Content:**
```
Titel: "Zeit für dein Push-Workout! 💪"
Body: "Du trainierst normalerweise um 18:00. Bereit?"
Actions:
  - "Training starten" → Öffnet App + startet letztes Workout
  - "Später"
  - "Heute pausieren"
```

**Smart Rules:**
- Kein Reminder wenn bereits trainiert heute
- Kein Reminder wenn Workout pausiert ist
- Lernender Algorithmus (Training-Pattern Erkennung)
- User kann deaktivieren oder Zeit anpassen

---

### 3. Workout Pause Reminder 🕐

**Use Case:** Erinnere User an pausierte Workouts

**Trigger:**
- Workout gestartet, aber nicht beendet
- Nach 2 Stunden Inaktivität
- Nach 24 Stunden nochmal

**Notification Content:**
```
Titel: "Pausiertes Workout: Push-Tag"
Body: "Du hast bei Übung 3/8 pausiert. Fortsetzen?"
Actions:
  - "Fortsetzen" → Öffnet App, restored Session
  - "Workout beenden"
```

**Smart Rules:**
- Nur 1x nach 2h, dann 1x nach 24h
- Danach automatisch "Workout abgebrochen"
- User kann Pause-Dauer konfigurieren

---

### 4. Achievement Notifications 🏆

**Use Case:** Feiere Erfolge und Meilensteine

**Trigger:**
- Neuer Personal Record (PR)
- Workout-Streak (7 Tage, 30 Tage, etc.)
- Volumen-Meilenstein (10.000kg gehoben)
- Konsistenz-Achievement (3 Monate regelmäßig)

**Notification Content:**
```
Titel: "Neuer Personal Record! 🎉"
Body: "Bankdrücken: 105kg × 8 (Vorher: 100kg × 8)"
Actions:
  - "Details anzeigen"
```

**Smart Rules:**
- Nur direkt nach Workout-Ende
- Nur für signifikante PRs (nicht jedes 0.5kg+)
- Batch multiple PRs zu einer Notification
- User kann deaktivieren

---

### 5. Rest Day Reminder 💤

**Use Case:** Erinnere an aktive Regeneration

**Trigger:**
- 3+ Tage hintereinander trainiert
- Kein Workout heute
- 20:00 Uhr Abends

**Notification Content:**
```
Titel: "Guter Rest Day! 🌙"
Body: "3 Tage Training in Folge. Regeneration ist wichtig!"
Actions:
  - "Dismiss"
```

**Smart Rules:**
- Nur abends (nicht morgens nerven)
- Nur bei echter Überbelastung (3+ Tage)
- User kann deaktivieren

---

### 6. Progressive Overload Suggestion 📈

**Use Case:** Schlage vor, Gewicht zu erhöhen

**Trigger:**
- 3x hintereinander selbes Gewicht geschafft
- Alle Sätze completed
- Keine Probleme/Failed Sets

**Notification Content:**
```
Titel: "Zeit für mehr Gewicht? 💪"
Body: "Bankdrücken 100kg: 3x erfolgreich. Versuch 102.5kg!"
Actions:
  - "Beim nächsten Mal"
  - "Dismiss"
```

**Smart Rules:**
- Nur NACH Workout (nicht währenddessen)
- Nur für Compound Lifts (Squat, Bench, Deadlift)
- Reasonable Progression (2.5kg für Oberkörper, 5kg für Beine)
- User kann deaktivieren

---

## 🏗️ Technical Architecture

### Layer 1: NotificationService Protocol (Domain Layer)

```swift
// Domain/Services/NotificationServiceProtocol.swift

protocol NotificationServiceProtocol {
    /// Request notification permissions
    func requestPermissions() async -> Result<Bool, NotificationError>
    
    /// Check current authorization status
    func authorizationStatus() async -> NotificationAuthorizationStatus
    
    /// Schedule a notification
    func schedule(_ notification: AppNotification) async -> Result<String, NotificationError>
    
    /// Cancel notification by ID
    func cancel(id: String) async
    
    /// Cancel all pending notifications
    func cancelAll() async
    
    /// Get pending notifications
    func pending() async -> [AppNotification]
}

enum NotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case provisional
}

enum NotificationError: LocalizedError {
    case permissionDenied
    case schedulingFailed
    case invalidContent
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Benachrichtigungen sind deaktiviert. Bitte in Einstellungen aktivieren."
        case .schedulingFailed:
            return "Benachrichtigung konnte nicht geplant werden."
        case .invalidContent:
            return "Ungültiger Benachrichtigungs-Inhalt."
        }
    }
}
```

### Layer 2: AppNotification Domain Model

```swift
// Domain/Entities/AppNotification.swift

struct AppNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let trigger: NotificationTrigger
    let actions: [NotificationAction]
    let metadata: [String: String]
    
    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        body: String,
        trigger: NotificationTrigger,
        actions: [NotificationAction] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.trigger = trigger
        self.actions = actions
        self.metadata = metadata
    }
}

enum NotificationType: String {
    case workoutReminder
    case pauseReminder
    case achievement
    case restDay
    case progressionSuggestion
    case restTimer  // Handled by AlarmKit, hier nur für Completeness
}

enum NotificationTrigger {
    case time(Date)
    case timeInterval(TimeInterval)
    case calendar(DateComponents)
}

struct NotificationAction: Identifiable {
    let id: String
    let title: String
    let type: ActionType
    let destructive: Bool
    
    enum ActionType {
        case startWorkout(workoutId: UUID)
        case resumeWorkout(sessionId: UUID)
        case endWorkout(sessionId: UUID)
        case dismiss
        case snooze(minutes: Int)
        case viewDetails
    }
}
```

### Layer 3: Use Cases

```swift
// Domain/UseCases/Notification/ScheduleWorkoutReminderUseCase.swift

protocol ScheduleWorkoutReminderUseCaseProtocol {
    func execute(at time: Date, workout: Workout?) async -> Result<Void, NotificationError>
}

final class ScheduleWorkoutReminderUseCase: ScheduleWorkoutReminderUseCaseProtocol {
    private let notificationService: NotificationServiceProtocol
    private let userPreferences: UserPreferencesProtocol
    
    init(
        notificationService: NotificationServiceProtocol,
        userPreferences: UserPreferencesProtocol
    ) {
        self.notificationService = notificationService
        self.userPreferences = userPreferences
    }
    
    func execute(at time: Date, workout: Workout?) async -> Result<Void, NotificationError> {
        // Check if reminders enabled
        guard userPreferences.workoutRemindersEnabled else {
            return .success(())
        }
        
        // Request permissions if needed
        let status = await notificationService.authorizationStatus()
        if status == .notDetermined {
            let result = await notificationService.requestPermissions()
            guard case .success(true) = result else {
                return .failure(.permissionDenied)
            }
        }
        
        // Create notification
        let workoutName = workout?.name ?? "Workout"
        let notification = AppNotification(
            type: .workoutReminder,
            title: "Zeit für dein \(workoutName)! 💪",
            body: "Du trainierst normalerweise jetzt. Bereit?",
            trigger: .time(time),
            actions: [
                NotificationAction(
                    id: "start",
                    title: "Training starten",
                    type: .startWorkout(workoutId: workout?.id ?? UUID()),
                    destructive: false
                ),
                NotificationAction(
                    id: "dismiss",
                    title: "Später",
                    type: .dismiss,
                    destructive: false
                )
            ],
            metadata: [
                "workoutId": workout?.id.uuidString ?? "",
                "workoutName": workoutName
            ]
        )
        
        return await notificationService.schedule(notification)
    }
}
```

### Layer 4: Infrastructure Implementation

```swift
// Infrastructure/Services/UNNotificationService.swift

import UserNotifications

final class UNNotificationService: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()
    
    func requestPermissions() async -> Result<Bool, NotificationError> {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return .success(granted)
        } catch {
            return .failure(.permissionDenied)
        }
    }
    
    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        case .ephemeral: return .authorized
        @unknown default: return .notDetermined
        }
    }
    
    func schedule(_ notification: AppNotification) async -> Result<String, NotificationError> {
        // Create content
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        
        // Add category for actions
        if !notification.actions.isEmpty {
            let categoryId = "gymbo.\(notification.type.rawValue)"
            content.categoryIdentifier = categoryId
            
            // Register category with actions
            let actions = notification.actions.map { action in
                UNNotificationAction(
                    identifier: action.id,
                    title: action.title,
                    options: action.destructive ? [.destructive] : []
                )
            }
            
            let category = UNNotificationCategory(
                identifier: categoryId,
                actions: actions,
                intentIdentifiers: []
            )
            
            center.setNotificationCategories([category])
        }
        
        // Add metadata
        content.userInfo = notification.metadata
        
        // Create trigger
        let trigger: UNNotificationTrigger
        switch notification.trigger {
        case .time(let date):
            trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: date
                ),
                repeats: false
            )
        case .timeInterval(let interval):
            trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: false
            )
        case .calendar(let components):
            trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )
        }
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            return .success(notification.id)
        } catch {
            return .failure(.schedulingFailed)
        }
    }
    
    func cancel(id: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
    }
    
    func pending() async -> [AppNotification] {
        let requests = await center.pendingNotificationRequests()
        // Map UNNotificationRequest back to AppNotification
        // Implementation details...
        return []
    }
}
```

---

## 🎨 Dynamic Island & Live Activities Integration

### Strategy: Gradual Enhancement

**Phase 1 (Current):** Local Notifications only  
**Phase 2 (Later):** Live Activities für Active Workout  
**Phase 3 (Future):** Dynamic Island für Rest Timer (already via AlarmKit!)

### Architecture Preparation

**Key Point:** Notification System muss **Live Activity Ready** sein:

```swift
// Domain/Entities/LiveActivityData.swift

struct WorkoutLiveActivityData {
    let sessionId: UUID
    let workoutName: String
    let currentExercise: String
    let exercisesCompleted: Int
    let totalExercises: Int
    let elapsedTime: TimeInterval
    let restTimeRemaining: TimeInterval?
}

// Future: NotificationService kann LiveActivity starten
protocol NotificationServiceProtocol {
    // ... existing methods
    
    /// Start Live Activity (Phase 2)
    func startLiveActivity(data: WorkoutLiveActivityData) async -> Result<String, NotificationError>
    
    /// Update Live Activity
    func updateLiveActivity(id: String, data: WorkoutLiveActivityData) async -> Result<Void, NotificationError>
    
    /// End Live Activity
    func endLiveActivity(id: String) async
}
```

**Implementation Note:**  
Phase 1 nutzt nur Local Notifications. Phase 2 erweitert `UNNotificationService` um Live Activity Support. **Keine Breaking Changes**, nur additive Funktionen.

---

## 🛠️ Implementation Plan

### Phase 1: Foundation (Session 21) - 3-4h

**Ziel:** Basic Notification Infrastructure

**Tasks:**
1. ✅ Create `NotificationServiceProtocol` (Domain)
2. ✅ Create `AppNotification` Domain Model
3. ✅ Create `UNNotificationService` (Infrastructure)
4. ✅ Implement Permission Request Flow
5. ✅ Add to `DependencyContainer`
6. ✅ Test Permission Request in Settings

**Deliverables:**
- Working notification permission request
- Service can schedule basic notifications
- No actual use cases yet (just infrastructure)

---

### Phase 2: Workout Reminder (Session 22) - 2-3h

**Ziel:** Erste konkrete Use Case Implementation

**Tasks:**
1. ✅ `ScheduleWorkoutReminderUseCase`
2. ✅ `UserPreferences` für Reminder Settings
3. ✅ Settings UI für Reminder Toggle
4. ✅ Smart Pattern Learning (simple heuristic)
5. ✅ Test End-to-End

**Deliverables:**
- User kann Workout Reminders aktivieren
- System schlägt Zeit basierend auf History vor
- Reminder wird korrekt gesendet

---

### Phase 3: Pause Reminder (Session 23) - 1-2h

**Ziel:** Pausierte Workouts wieder aufnehmen

**Tasks:**
1. ✅ `SchedulePauseReminderUseCase`
2. ✅ Hook in `EndSessionUseCase` (wenn Session nicht completed)
3. ✅ Notification Action Handler (Resume/End)
4. ✅ Test Pause Flow

**Deliverables:**
- Pausierte Sessions triggern Reminder nach 2h
- User kann aus Notification fortsetzen
- Workout wird korrekt restored

---

### Phase 4: Achievements (Session 24) - 2-3h

**Ziel:** Feiere Erfolge

**Tasks:**
1. ✅ Achievement Detection Logic
2. ✅ `ScheduleAchievementNotificationUseCase`
3. ✅ PR Comparison Algorithm
4. ✅ Streak Tracking
5. ✅ Settings Toggle für Achievement Notifications

**Deliverables:**
- PRs werden erkannt
- Streaks werden getrackt
- Notifications direkt nach Workout

---

### Phase 5: Live Activities Preparation (Session 25) - 2h

**Ziel:** Vorbereitung für Phase 2

**Tasks:**
1. ✅ Extend `NotificationServiceProtocol` mit Live Activity Methods
2. ✅ Create `WorkoutLiveActivityData` Model
3. ✅ Stub Implementation (no actual Live Activity yet)
4. ✅ Documentation Update

**Deliverables:**
- Architecture ready für Live Activities
- No breaking changes
- Clear migration path documented

---

## 📊 User Settings & Preferences

### Settings Screen Additions

```swift
struct NotificationSettingsView: View {
    @AppStorage("notifications.workoutReminders") var workoutReminders = true
    @AppStorage("notifications.pauseReminders") var pauseReminders = true
    @AppStorage("notifications.achievements") var achievements = true
    @AppStorage("notifications.restDay") var restDay = false
    @AppStorage("notifications.progression") var progression = true
    
    @AppStorage("notifications.reminderTime") var reminderTime = 18 // 18:00
    @AppStorage("notifications.pauseDelay") var pauseDelay = 2 // 2 hours
    
    var body: some View {
        Form {
            Section("Workout Reminders") {
                Toggle("Workout-Erinnerungen", isOn: $workoutReminders)
                
                if workoutReminders {
                    Picker("Standard-Zeit", selection: $reminderTime) {
                        ForEach(6..<23) { hour in
                            Text("\(hour):00 Uhr").tag(hour)
                        }
                    }
                }
            }
            
            Section("Fortschritt") {
                Toggle("Erfolge & Meilensteine", isOn: $achievements)
                Toggle("Progressive Overload Tipps", isOn: $progression)
                Toggle("Ruhetag-Erinnerungen", isOn: $restDay)
            }
            
            Section("Pausierte Workouts") {
                Toggle("Erinnerung bei Pause", isOn: $pauseReminders)
                
                if pauseReminders {
                    Picker("Erinnern nach", selection: $pauseDelay) {
                        Text("1 Stunde").tag(1)
                        Text("2 Stunden").tag(2)
                        Text("4 Stunden").tag(4)
                    }
                }
            }
        }
        .navigationTitle("Benachrichtigungen")
    }
}
```

---

## 🧪 Testing Strategy

### Unit Tests

```swift
class ScheduleWorkoutReminderUseCaseTests: XCTestCase {
    var sut: ScheduleWorkoutReminderUseCase!
    var mockNotificationService: MockNotificationService!
    var mockPreferences: MockUserPreferences!
    
    func test_execute_whenRemindersDisabled_doesNotSchedule() async {
        // Given
        mockPreferences.workoutRemindersEnabled = false
        
        // When
        let result = await sut.execute(at: Date(), workout: nil)
        
        // Then
        XCTAssertEqual(mockNotificationService.scheduleCallCount, 0)
        guard case .success = result else {
            XCTFail("Expected success")
            return
        }
    }
    
    func test_execute_whenPermissionDenied_returnsError() async {
        // Given
        mockNotificationService.authorizationResult = .denied
        
        // When
        let result = await sut.execute(at: Date(), workout: nil)
        
        // Then
        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertEqual(error, .permissionDenied)
    }
    
    func test_execute_withWorkout_schedulesCorrectNotification() async {
        // Given
        mockPreferences.workoutRemindersEnabled = true
        mockNotificationService.authorizationResult = .authorized
        let workout = Workout.fixture(name: "Push Day")
        let time = Date()
        
        // When
        let result = await sut.execute(at: time, workout: workout)
        
        // Then
        guard case .success = result else {
            XCTFail("Expected success")
            return
        }
        XCTAssertEqual(mockNotificationService.scheduleCallCount, 1)
        XCTAssertTrue(mockNotificationService.lastScheduledNotification?.title.contains("Push Day") ?? false)
    }
}
```

---

## 📈 Success Metrics

### Phase 1-3 (MVP)
- ✅ Notification Permissions granted rate > 60%
- ✅ Workout Reminder engagement rate > 40%
- ✅ Pause Reminder resume rate > 30%
- ✅ Zero crashes related to notifications

### Phase 4-5 (Enhancement)
- ✅ Achievement Notification sentiment > 80% positive
- ✅ Progressive Overload adoption rate > 25%
- ✅ Live Activity engagement > 50% (Phase 2)

---

## 🚨 Privacy & Compliance

### iOS Requirements
- ✅ Request permissions contextually (not on first launch)
- ✅ Clear explanation in permission prompt
- ✅ Granular control in Settings
- ✅ Respect quiet hours (use system defaults)

### Data Privacy
- ✅ No personal data in notifications (nur "Workout", kein "Bankdrücken 150kg")
- ✅ No notification tracking/analytics
- ✅ All notification data stays on device
- ✅ No cloud sync of notification state

---

## 🎯 Decision: Notification Strategy v1.0

**Approach:** **Incremental Enhancement**

1. **Phase 1:** Local Notifications Infrastructure (Session 21)
2. **Phase 2-4:** Core Use Cases (Workout/Pause/Achievement Reminders)
3. **Phase 5:** Live Activities Preparation
4. **Future:** Dynamic Island Integration (using AlarmKit patterns)

**Timeline:** 5 Sessions (~10-12 Stunden)

**Dependencies:**
- ✅ AlarmKit already handles Rest Timer (no work needed)
- ✅ UserPreferences system (needs light extension)
- ✅ Settings UI (needs new section)

**Risks:**
- ⚠️ Permission rejection rate (mitigate: contextual prompts)
- ⚠️ Notification fatigue (mitigate: smart rules, user control)
- ⚠️ iOS version compatibility (mitigate: fallbacks)

---

**Next Steps:** Approve this plan → Start Phase 1 Implementation

