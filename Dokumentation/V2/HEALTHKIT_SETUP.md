# HealthKit Setup Instructions

## Info.plist Entries Required

Add these entries to your Info.plist (or in Xcode Project Settings → Info):

### Privacy - Health Share Usage Description
**Key:** `NSHealthShareUsageDescription`  
**Value:** `GymBo benötigt Zugriff auf deine Gesundheitsdaten, um Gewicht und Herzfrequenz zu importieren.`

### Privacy - Health Update Usage Description
**Key:** `NSHealthUpdateUsageDescription`  
**Value:** `GymBo möchte deine Workouts und verbrannten Kalorien in Apple Health speichern.`

## How to Add in Xcode

1. Open `GymBo.xcodeproj` in Xcode
2. Select the **GymBo** target
3. Go to the **Info** tab
4. Click **+** to add a new key
5. Start typing "Health" to find the privacy keys
6. Add both keys with the German descriptions above

## Capabilities Required

1. Go to **Signing & Capabilities** tab
2. Click **+ Capability**
3. Add **HealthKit**

## Testing

After adding these:
1. Build the project
2. Run on Simulator or Device
3. Grant HealthKit permissions when prompted
4. Start a workout → Check Health app for saved workout
5. Check Console for HealthKit logs: `✅ HealthKit session started`

---

**Note:** These entries are required before the app can request HealthKit permissions.
Without them, the app will crash when calling `requestAuthorization()`.
