//
//  EditExerciseDetailsView.swift
//  GymBo
//
//  Created on 2025-10-23.
//  V2 Clean Architecture - Presentation Layer
//

import SwiftUI

/// Sheet view for editing exercise details within a workout
///
/// **Features:**
/// - Edit target sets, reps, weight
/// - Edit rest time between sets
/// - Add/edit notes
/// - Validation feedback
/// - Save with success notification
///
/// **Design:**
/// - Form-based layout
/// - Number pickers for easy input
/// - Cancel and Save buttons
/// - Keyboard-friendly
struct EditExerciseDetailsView: View {

    // MARK: - Properties

    let workoutId: UUID
    let exercise: WorkoutExercise
    let exerciseName: String
    let onSave: (Int, Int?, TimeInterval?, Double?, TimeInterval?, [TimeInterval]?, String?) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var targetSets: Int
    @State private var targetReps: Int
    @State private var targetTime: Int  // in seconds
    @State private var targetWeight: String
    @State private var restTime: Int
    @State private var customRestTime: String
    @State private var useCustomRestTime: Bool
    @State private var usePerSetRestTimes: Bool
    @State private var perSetRestTimes: [Int]
    @State private var notes: String
    @State private var useWeight: Bool
    @State private var useReps: Bool
    @State private var useTime: Bool
    @FocusState private var isWeightFieldFocused: Bool
    @FocusState private var isNotesFieldFocused: Bool
    @FocusState private var isCustomRestTimeFocused: Bool

    // MARK: - Initialization

    init(
        workoutId: UUID,
        exercise: WorkoutExercise,
        exerciseName: String,
        onSave:
            @escaping (Int, Int?, TimeInterval?, Double?, TimeInterval?, [TimeInterval]?, String?)
            -> Void
    ) {
        self.workoutId = workoutId
        self.exercise = exercise
        self.exerciseName = exerciseName
        self.onSave = onSave

        // Initialize state
        _targetSets = State(initialValue: exercise.targetSets)
        _targetReps = State(initialValue: exercise.targetReps ?? 8)
        _targetTime = State(initialValue: Int(exercise.targetTime ?? 60))
        _targetWeight = State(
            initialValue: exercise.targetWeight.map { String(format: "%.1f", $0) } ?? "0")

        let initialRestTime = Int(exercise.restTime ?? 90)
        _restTime = State(initialValue: initialRestTime)

        // Check if rest time is a predefined value
        let predefinedRestTimes = [30, 45, 60, 90, 120, 180]
        let isCustom = !predefinedRestTimes.contains(initialRestTime)
        _useCustomRestTime = State(initialValue: isCustom)
        _customRestTime = State(initialValue: isCustom ? String(initialRestTime) : "")

        // Initialize per-set rest times
        if let perSetRestTimes = exercise.perSetRestTimes {
            _usePerSetRestTimes = State(initialValue: true)
            _perSetRestTimes = State(initialValue: perSetRestTimes.map { Int($0) })
        } else {
            _usePerSetRestTimes = State(initialValue: false)
            _perSetRestTimes = State(
                initialValue: Array(repeating: initialRestTime, count: exercise.targetSets))
        }

        _notes = State(initialValue: exercise.notes ?? "")
        _useWeight = State(initialValue: exercise.targetWeight != nil && exercise.targetWeight! > 0)
        _useReps = State(initialValue: exercise.targetReps != nil)
        _useTime = State(initialValue: exercise.targetTime != nil)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Exercise Name Header
                    exerciseNameHeader

                    // Sets Section
                    setsSection

                    // Reps or Time Section
                    repsTimeSection

                    // Weight Section
                    weightSection

                    // Rest Time Section
                    restTimeSection

                    // Notes Section
                    notesSection
                }
                .padding()
                .padding(.bottom, 100)  // Extra padding for keyboard
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Übung bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        isWeightFieldFocused = false
                        isNotesFieldFocused = false
                        isCustomRestTimeFocused = false
                    }
                }
            }
        }
    }

    // MARK: - Subviews (Modern iOS 26 Design)

    private var exerciseNameHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(.primary)

            Text(exerciseName)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var setsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Sätze")

            VStack(spacing: 0) {
                HStack {
                    Text("Anzahl")
                        .font(.body)

                    Spacer()

                    Button {
                        if targetSets > 1 {
                            targetSets -= 1
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(targetSets > 1 ? .primary : .secondary)
                    }
                    .disabled(targetSets <= 1)

                    Text("\(targetSets)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .frame(minWidth: 40)

                    Button {
                        if targetSets < 10 {
                            targetSets += 1
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(targetSets < 10 ? .primary : .secondary)
                    }
                    .disabled(targetSets >= 10)
                }
                .padding()
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private var repsTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Wiederholungen oder Zeit")

            VStack(spacing: 8) {
                // Reps Toggle
                toggleCard(
                    title: "Wiederholungen",
                    isOn: $useReps,
                    onChange: { newValue in
                        if newValue { useTime = false }
                    }
                )

                // Reps Stepper
                if useReps {
                    HStack {
                        Text("Wiederholungen")
                            .font(.body)

                        Spacer()

                        Button {
                            if targetReps > 1 {
                                targetReps -= 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(targetReps > 1 ? .primary : .secondary)
                        }
                        .disabled(targetReps <= 1)

                        Text("\(targetReps)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .frame(minWidth: 40)

                        Button {
                            if targetReps < 50 {
                                targetReps += 1
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(targetReps < 50 ? .primary : .secondary)
                        }
                        .disabled(targetReps >= 50)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }

                // Time Toggle
                toggleCard(
                    title: "Zeit verwenden",
                    isOn: $useTime,
                    onChange: { newValue in
                        if newValue { useReps = false }
                    }
                )

                // Time Picker
                if useTime {
                    VStack(spacing: 8) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { seconds in
                            timeOptionButton(seconds: seconds)
                        }
                    }
                }
            }
        }
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Gewicht")

            VStack(spacing: 8) {
                toggleCard(
                    title: "Gewicht verwenden",
                    isOn: $useWeight,
                    onChange: { _ in }
                )

                if useWeight {
                    HStack {
                        Text("Gewicht")
                            .font(.body)

                        Spacer()

                        TextField("0", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .frame(maxWidth: 100)
                            .focused($isWeightFieldFocused)

                        Text("kg")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var restTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Pause zwischen Sätzen")

            // Toggle for per-set rest times
            Toggle("Pausenzeit pro Satz", isOn: $usePerSetRestTimes)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .onChange(of: usePerSetRestTimes) { _, isEnabled in
                    if isEnabled {
                        // Initialize array with current restTime for all sets
                        perSetRestTimes = Array(repeating: restTime, count: targetSets)
                    }
                    HapticFeedback.impact(.light)
                }

            if usePerSetRestTimes {
                // Per-set rest time controls
                perSetRestTimesView
            } else {
                // Standard: One rest time for all sets
                VStack(spacing: 8) {
                    ForEach([30, 45, 60, 90, 120, 180], id: \.self) { seconds in
                        restTimeOptionButton(seconds: seconds)
                    }

                    // Custom Rest Time Option
                    Button {
                        useCustomRestTime.toggle()
                        if useCustomRestTime {
                            isCustomRestTimeFocused = true
                        }
                        HapticFeedback.impact(.light)
                    } label: {
                        HStack {
                            Text("Individuelle Pausenzeit")
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if useCustomRestTime {
                                Image(systemName: "checkmark")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(
                            useCustomRestTime
                                ? Color.primary.opacity(0.1)
                                : Color(.secondarySystemGroupedBackground)
                        )
                        .cornerRadius(12)
                    }

                    // Custom Rest Time Input Field
                    if useCustomRestTime {
                        HStack {
                            Text("Sekunden")
                                .font(.body)

                            Spacer()

                            TextField("60", text: $customRestTime)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                                .frame(maxWidth: 100)
                                .focused($isCustomRestTimeFocused)
                                .onChange(of: customRestTime) { _, newValue in
                                    // Update restTime as user types
                                    if let seconds = Int(newValue), seconds > 0 {
                                        restTime = seconds
                                    }
                                }

                            Text("Sek")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Per-Set Rest Times View

    private var perSetRestTimesView: some View {
        VStack(spacing: 8) {
            ForEach(0..<targetSets, id: \.self) { setIndex in
                perSetRestTimeRow(setIndex: setIndex)
            }
        }
    }

    private func perSetRestTimeRow(setIndex: Int) -> some View {
        NavigationLink {
            PerSetRestTimePickerView(
                setNumber: setIndex + 1,
                restTime: Binding(
                    get: { perSetRestTimes[safe: setIndex] ?? 90 },
                    set: { newValue in
                        if setIndex < perSetRestTimes.count {
                            perSetRestTimes[setIndex] = newValue
                        }
                    }
                )
            )
        } label: {
            HStack {
                Text("Nach Satz \(setIndex + 1)")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(perSetRestTimes[safe: setIndex] ?? 90) Sek")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Notizen")

            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .focused($isNotesFieldFocused)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }

    private func toggleCard(title: String, isOn: Binding<Bool>, onChange: @escaping (Bool) -> Void)
        -> some View
    {
        Button {
            isOn.wrappedValue.toggle()
            onChange(isOn.wrappedValue)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                if isOn.wrappedValue {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(
                isOn.wrappedValue
                    ? Color.primary.opacity(0.1) : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
        }
    }

    private func timeOptionButton(seconds: Int) -> some View {
        Button {
            targetTime = seconds
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Text("\(seconds) Sekunden")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                if targetTime == seconds {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(
                targetTime == seconds
                    ? Color.primary.opacity(0.1) : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
        }
    }

    private func restTimeOptionButton(seconds: Int) -> some View {
        Button {
            restTime = seconds
            useCustomRestTime = false
            customRestTime = ""
            HapticFeedback.impact(.light)
        } label: {
            HStack {
                Text("\(seconds) Sekunden")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                if !useCustomRestTime && restTime == seconds {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(
                !useCustomRestTime && restTime == seconds
                    ? Color.primary.opacity(0.1) : Color(.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
        }
    }

    // MARK: - Computed Properties

    private var isValid: Bool {
        // Must have either reps or time
        guard useReps || useTime else {
            return false
        }

        if useWeight {
            // Check if weight is valid number
            guard Double(targetWeight.replacingOccurrences(of: ",", with: ".")) != nil,
                !targetWeight.isEmpty
            else {
                return false
            }
        }
        return true
    }

    // MARK: - Actions

    private func saveChanges() {
        // Determine final rest time values
        let finalRestTime: TimeInterval?
        let finalPerSetRestTimes: [TimeInterval]?

        if usePerSetRestTimes {
            // Use per-set rest times
            finalPerSetRestTimes = perSetRestTimes.map { TimeInterval($0) }
            finalRestTime = TimeInterval(perSetRestTimes.first ?? 90)
        } else {
            // Use single rest time for all sets
            finalPerSetRestTimes = nil
            finalRestTime = TimeInterval(restTime)
        }

        // Continue with existing save logic
        // Parse weight
        let weight: Double?
        if useWeight, !targetWeight.isEmpty {
            weight = Double(targetWeight.replacingOccurrences(of: ",", with: "."))
        } else {
            weight = nil
        }

        // Prepare notes (nil if empty)
        let finalNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesToSave = finalNotes.isEmpty ? nil : finalNotes

        // Call save handler
        onSave(
            targetSets,
            useReps ? targetReps : nil,
            useTime ? TimeInterval(targetTime) : nil,
            weight,
            finalRestTime,
            finalPerSetRestTimes,
            notesToSave
        )

        dismiss()
    }
}

// MARK: - Array Safe Subscript Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Per-Set Rest Time Picker View

private struct PerSetRestTimePickerView: View {
    let setNumber: Int
    @Binding var restTime: Int
    @Environment(\.dismiss) private var dismiss

    private let predefinedTimes = [30, 45, 60, 90, 120, 180]
    @State private var useCustomTime = false
    @State private var customTimeText = ""
    @FocusState private var isCustomTimeFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pausenzeit nach Satz \(setNumber)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    VStack(spacing: 8) {
                        ForEach(predefinedTimes, id: \.self) { seconds in
                            Button {
                                restTime = seconds
                                useCustomTime = false
                                customTimeText = ""
                                HapticFeedback.impact(.light)
                            } label: {
                                HStack {
                                    Text("\(seconds) Sekunden")
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()

                                    if !useCustomTime && restTime == seconds {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding()
                                .background(
                                    !useCustomTime && restTime == seconds
                                        ? Color.primary.opacity(0.1)
                                        : Color(.secondarySystemGroupedBackground)
                                )
                                .cornerRadius(12)
                            }
                        }

                        // Custom Time Option
                        Button {
                            useCustomTime.toggle()
                            if useCustomTime {
                                customTimeText = String(restTime)
                                isCustomTimeFocused = true
                            }
                            HapticFeedback.impact(.light)
                        } label: {
                            HStack {
                                Text("Individuelle Pausenzeit")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                if useCustomTime {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(
                                useCustomTime
                                    ? Color.primary.opacity(0.1)
                                    : Color(.secondarySystemGroupedBackground)
                            )
                            .cornerRadius(12)
                        }

                        if useCustomTime {
                            HStack {
                                Text("Sekunden")
                                    .font(.body)

                                Spacer()

                                TextField("60", text: $customTimeText)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                                    .frame(maxWidth: 100)
                                    .focused($isCustomTimeFocused)
                                    .onChange(of: customTimeText) { _, newValue in
                                        if let seconds = Int(newValue), seconds > 0 {
                                            restTime = seconds
                                        }
                                    }

                                Text("Sek")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pausenzeit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fertig") {
                    isCustomTimeFocused = false
                }
            }
        }
        .onAppear {
            let predefined = predefinedTimes.contains(restTime)
            useCustomTime = !predefined
            if !predefined {
                customTimeText = String(restTime)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditExerciseDetailsView(
        workoutId: UUID(),
        exercise: WorkoutExercise(
            exerciseId: UUID(),
            targetSets: 3,
            targetReps: 10,
            targetWeight: 80.0,
            restTime: 90,
            orderIndex: 0,
            notes: "Focus on form"
        ),
        exerciseName: "Bankdrücken",
        onSave: { sets, reps, time, weight, rest, perSetRestTimes, notes in
            print(
                "Saved: \(sets) sets, \(reps.map { "\($0) reps" } ?? ""), \(time.map { "\($0)s" } ?? ""), \(weight ?? 0)kg, \(rest ?? 0)s rest, perSet: \(perSetRestTimes?.description ?? "nil")"
            )
        }
    )
}
