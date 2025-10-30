//
//  ProfileView.swift
//  GymBo
//
//  Created on 2025-10-27.
//  V2 Clean Architecture - Profile View (Complete Implementation)
//

import HealthKit
import PhotosUI
import SwiftUI

/// Complete profile view with personal info, settings, and notifications
///
/// **Structure:**
/// - Profil: Image, Name, Age, Experience, Goal
/// - Einstellungen: HealthKit, App Theme
/// - Benachrichtigungen: Push Notifications, Live Activity
struct ProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings
    @State private var userProfile: DomainUserProfile?
    @State private var isLoading = false

    // Image Picker
    @State private var showImageSourcePicker = false
    @State private var showCameraPicker = false
    @State private var showGalleryPicker = false
    @State private var selectedImage: UIImage?
    @State private var isImportingHealthData = false

    private let userProfileRepository: UserProfileRepositoryProtocol
    private let importBodyMetricsUseCase: ImportBodyMetricsUseCase
    private let healthKitService: HealthKitServiceProtocol

    init(
        userProfileRepository: UserProfileRepositoryProtocol,
        importBodyMetricsUseCase: ImportBodyMetricsUseCase,
        healthKitService: HealthKitServiceProtocol
    ) {
        self.userProfileRepository = userProfileRepository
        self.importBodyMetricsUseCase = importBodyMetricsUseCase
        self.healthKitService = healthKitService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Section
                    profileSection

                    // Personal Data Section
                    personalDataSection

                    // Settings Section
                    settingsSection

                    // Notifications Section
                    notificationsSection

                    #if DEBUG
                        // Developer Section (Feature Flags)
                        developerSection
                    #endif
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadUserProfile()
            }
            .sheet(isPresented: $showCameraPicker) {
                ImagePicker(
                    sourceType: .camera,
                    onImagePicked: { image in
                        selectedImage = image
                        Task {
                            await updateProfileImage(image)
                        }
                    }
                )
            }
            .sheet(isPresented: $showGalleryPicker) {
                ImagePicker(
                    sourceType: .photoLibrary,
                    onImagePicked: { image in
                        selectedImage = image
                        Task {
                            await updateProfileImage(image)
                        }
                    }
                )
            }
            .confirmationDialog("Profilbild auswählen", isPresented: $showImageSourcePicker) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Kamera") {
                        showCameraPicker = true
                    }
                }
                Button("Fotobibliothek") {
                    showGalleryPicker = true
                }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: 16) {
            // Profile Image
            Button {
                showImageSourcePicker = true
            } label: {
                Group {
                    if let imageData = userProfile?.profileImageData,
                        let uiImage = UIImage(data: imageData)
                    {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(.secondary)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .gray)
                }
            }
            .buttonStyle(.plain)

            Text("Profilbild")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    // MARK: - Personal Data Section

    private var personalDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Persönliche Daten")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                // Name
                HStack {
                    Image(systemName: "person.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    TextField(
                        "Name",
                        text: Binding(
                            get: { userProfile?.name ?? "" },
                            set: { newValue in
                                Task {
                                    await updatePersonalInfo(name: newValue)
                                }
                            }
                        )
                    )
                    .font(.body)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))

                Divider()
                    .padding(.leading, 48)

                // Age
                HStack {
                    Image(systemName: "calendar")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    Text("Alter")
                        .font(.body)

                    Spacer()

                    if let age = userProfile?.age {
                        Text("\(age) Jahre")
                            .foregroundStyle(.secondary)
                    }

                    Stepper(
                        value: Binding(
                            get: { userProfile?.age ?? 25 },
                            set: { newValue in
                                Task {
                                    await updatePersonalInfo(age: newValue)
                                }
                            }
                        ),
                        in: 10...100
                    ) {
                        EmptyView()
                    }
                    .labelsHidden()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))

                Divider()
                    .padding(.leading, 48)

                // Experience Level
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    Text("Erfahrung")
                        .font(.body)

                    Spacer()

                    Menu {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            Button {
                                Task {
                                    await updatePersonalInfo(experienceLevel: level)
                                }
                            } label: {
                                HStack {
                                    Text(level.rawValue)
                                    if userProfile?.experienceLevel == level {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(userProfile?.experienceLevel?.rawValue ?? "Auswählen")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))

                Divider()
                    .padding(.leading, 48)

                // Fitness Goal
                HStack {
                    Image(systemName: "target")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    Text("Ziel")
                        .font(.body)

                    Spacer()

                    Menu {
                        ForEach(FitnessGoal.allCases, id: \.self) { goal in
                            Button {
                                Task {
                                    await updatePersonalInfo(fitnessGoal: goal)
                                }
                            } label: {
                                HStack {
                                    Text(goal.rawValue)
                                    if userProfile?.fitnessGoal == goal {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(userProfile?.fitnessGoal?.rawValue ?? "Auswählen")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))

                Divider()
                    .padding(.leading, 48)

                // Height
                HStack {
                    Image(systemName: "ruler")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    Text("Größe")
                        .font(.body)

                    Spacer()

                    if let height = userProfile?.height {
                        Text("\(Int(height)) cm")
                            .foregroundStyle(.secondary)
                    }

                    Stepper(
                        value: Binding(
                            get: { userProfile?.height ?? 175 },
                            set: { newValue in
                                Task {
                                    do {
                                        try await userProfileRepository.updateBodyMetrics(
                                            bodyMass: userProfile?.bodyMass,
                                            height: newValue
                                        )
                                        await loadUserProfile()
                                    } catch {
                                        print("❌ Failed to update height: \(error)")
                                    }
                                }
                            }
                        ),
                        in: 100...250,
                        step: 1
                    ) {
                        EmptyView()
                    }
                    .labelsHidden()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))

                Divider()
                    .padding(.leading, 48)

                // Weight
                HStack {
                    Image(systemName: "scalemass")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    Text("Gewicht")
                        .font(.body)

                    Spacer()

                    if let bodyMass = userProfile?.bodyMass {
                        Text(String(format: "%.1f kg", bodyMass))
                            .foregroundStyle(.secondary)
                    }

                    Stepper(
                        value: Binding(
                            get: { userProfile?.bodyMass ?? 75 },
                            set: { newValue in
                                Task {
                                    do {
                                        try await userProfileRepository.updateBodyMetrics(
                                            bodyMass: newValue,
                                            height: userProfile?.height
                                        )
                                        await loadUserProfile()
                                    } catch {
                                        print("❌ Failed to update body mass: \(error)")
                                    }
                                }
                            }
                        ),
                        in: 30...250,
                        step: 0.5
                    ) {
                        EmptyView()
                    }
                    .labelsHidden()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
            }
            .cornerRadius(12)

            // Import from HealthKit Button
            if userProfile?.healthKitEnabled == true {
                Button {
                    Task {
                        await importFromHealthKit()
                    }
                } label: {
                    HStack {
                        if isImportingHealthData {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text("Aus Apple Health importieren")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .disabled(isImportingHealthData)
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Einstellungen")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                // Apple Health Toggle
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health aktivieren")
                            .font(.body)

                        Text("Alter, Gewicht, Trainings, Aktivität")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle(
                        "",
                        isOn: Binding(
                            get: { userProfile?.healthKitEnabled ?? false },
                            set: { newValue in
                                Task {
                                    await updateHealthKitEnabled(newValue)
                                }
                            }
                        )
                    )
                    .labelsHidden()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
            }
            .cornerRadius(12)
        }
    }

    // MARK: - Notifications Section

    /// Notifications section
    /// Note: Toggle saves preference to database, but actual notification logic not yet implemented
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benachrichtigungen")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                // Push Notifications - Opens iOS Settings
                Button {
                    openNotificationSettings()
                } label: {
                    HStack {
                        Image(systemName: "bell.fill")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Benachrichtigungen verwalten")
                                .font(.body)
                                .foregroundStyle(.primary)

                            Text("Öffnet iOS Einstellungen")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.leading, 48)

                // Live Activity (disabled - not implemented yet)
                HStack {
                    Image(systemName: "livephoto")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Activity")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        Text("Bald verfügbar")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Toggle("", isOn: .constant(false))
                        .labelsHidden()
                        .disabled(true)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .opacity(0.6)
            }
            .cornerRadius(12)
        }
    }

    #if DEBUG
        // MARK: - Developer Section (DEBUG only)

        private var developerSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Developer")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                VStack(spacing: 0) {
                    ForEach(Array(FeatureFlag.allCases.enumerated()), id: \.offset) { index, flag in
                        HStack {
                            Image(systemName: "flag")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)

                            Text(flag.rawValue)
                                .font(.body)

                            Spacer()

                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { appSettings.isFeatureEnabled(flag) },
                                    set: { newValue in
                                        appSettings.setFeature(flag, enabled: newValue)
                                    }
                                )
                            )
                            .labelsHidden()
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))

                        if index < FeatureFlag.allCases.count - 1 {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
                .cornerRadius(12)
            }
        }
    #endif

    // MARK: - Helper Methods

    private func loadUserProfile() async {
        do {
            userProfile = try await userProfileRepository.fetchOrCreate()
            print("✅ User profile loaded")
        } catch {
            print("❌ Failed to load user profile: \(error)")
        }
    }

    private func updateProfileImage(_ image: UIImage) async {
        guard let resizedImage = image.resized(maxDimension: 512).compressedJPEG(maxSizeKB: 500)
        else {
            print("❌ Failed to compress image")
            return
        }

        do {
            try await userProfileRepository.updateProfileImage(resizedImage)
            await loadUserProfile()
            print("✅ Profile image updated")
        } catch {
            print("❌ Failed to update profile image: \(error)")
        }
    }

    private func updatePersonalInfo(
        name: String? = nil,
        age: Int? = nil,
        experienceLevel: ExperienceLevel? = nil,
        fitnessGoal: FitnessGoal? = nil
    ) async {
        do {
            try await userProfileRepository.updatePersonalInfo(
                name: name,
                age: age,
                experienceLevel: experienceLevel,
                fitnessGoal: fitnessGoal
            )
            await loadUserProfile()
            print("✅ Personal info updated")
        } catch {
            print("❌ Failed to update personal info: \(error)")
        }
    }

    private func updateHealthKitEnabled(_ enabled: Bool) async {
        // If enabling HealthKit, request authorization first
        if enabled {
            let result = await healthKitService.requestAuthorization()

            switch result {
            case .success:
                print("✅ HealthKit authorization granted")
            case .failure(let error):
                print("❌ HealthKit authorization failed: \(error)")
                // Don't enable if authorization failed
                return
            }
        }

        do {
            try await userProfileRepository.updateSettings(
                healthKitEnabled: enabled,
                appTheme: nil
            )
            await loadUserProfile()
            print("✅ HealthKit setting updated to: \(enabled)")
        } catch {
            print("❌ Failed to update HealthKit setting: \(error)")
        }
    }

    private func updateNotificationSettings(
        notificationsEnabled: Bool? = nil,
        liveActivityEnabled: Bool? = nil
    ) async {
        do {
            try await userProfileRepository.updateNotificationSettings(
                notificationsEnabled: notificationsEnabled,
                liveActivityEnabled: liveActivityEnabled
            )
            await loadUserProfile()
            print("✅ Notification settings updated")
        } catch {
            print("❌ Failed to update notification settings: \(error)")
        }
    }

    private func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func importFromHealthKit() async {
        print("🔍 Import from HealthKit started...")
        isImportingHealthData = true
        defer { isImportingHealthData = false }

        // Import body metrics from HealthKit
        let result = await importBodyMetricsUseCase.execute()

        switch result {
        case .success(let metrics):
            print(
                "📊 Imported metrics - Weight: \(metrics.bodyMass?.description ?? "nil") kg, Height: \(metrics.height?.description ?? "nil") cm, Age: \(metrics.age?.description ?? "nil") years"
            )

            do {
                // Update profile with imported data
                var updates: [() async throws -> Void] = []

                // Update body metrics if available
                if metrics.bodyMass != nil || metrics.height != nil {
                    print("💾 Saving body metrics...")
                    updates.append {
                        try await self.userProfileRepository.updateBodyMetrics(
                            bodyMass: metrics.bodyMass,
                            height: metrics.height
                        )
                    }
                }

                // Update age if available
                if let age = metrics.age {
                    print("💾 Saving age: \(age)")
                    updates.append {
                        try await self.userProfileRepository.updatePersonalInfo(
                            name: nil,
                            age: age,
                            experienceLevel: nil,
                            fitnessGoal: nil
                        )
                    }
                }

                // Execute all updates
                for update in updates {
                    try await update()
                }

                // Reload profile to show new data
                await loadUserProfile()

                print("✅ HealthKit data imported and saved successfully")
            } catch {
                print("❌ Failed to save HealthKit data: \(error)")
            }

        case .failure(let error):
            print("❌ Failed to import from HealthKit: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    let mockRepository = MockUserProfileRepository()
    let mockUseCase = MockImportBodyMetricsUseCase()
    let mockFeatureFlags = FeatureFlagService()
    let mockSettings = AppSettings(
        userProfileRepository: mockRepository,
        featureFlagService: mockFeatureFlags
    )

    ProfileView(
        userProfileRepository: mockRepository,
        importBodyMetricsUseCase: mockUseCase,
        healthKitService: MockHealthKitService()
    )
    .environment(mockSettings)
}

// MARK: - Mock Implementation

private class MockUserProfileRepository: UserProfileRepositoryProtocol {
    func fetchOrCreate() async throws -> DomainUserProfile {
        DomainUserProfile(
            name: "Max Mustermann",
            age: 28,
            experienceLevel: .intermediate,
            fitnessGoal: .muscleGain,
            bodyMass: 75.0,
            height: 180.0,
            weeklyWorkoutGoal: 4,
            healthKitEnabled: true,
            appTheme: .system,
            notificationsEnabled: true,
            liveActivityEnabled: true
        )
    }

    func update(_ profile: DomainUserProfile) async throws {}
    func updateBodyMetrics(bodyMass: Double?, height: Double?) async throws {}
    func updateWeeklyWorkoutGoal(_ goal: Int) async throws {}
    func updatePersonalInfo(
        name: String?, age: Int?, experienceLevel: ExperienceLevel?, fitnessGoal: FitnessGoal?
    ) async throws {}
    func updateProfileImage(_ imageData: Data?) async throws {}
    func updateSettings(
        healthKitEnabled: Bool?,
        appTheme: AppTheme?
    ) async throws {}
    func updateNotificationSettings(notificationsEnabled: Bool?, liveActivityEnabled: Bool?)
        async throws
    {}
}

private class MockImportBodyMetricsUseCase: ImportBodyMetricsUseCase {
    func execute() async -> Result<BodyMetrics, HealthKitError> {
        .success(BodyMetrics(bodyMass: 75.0, height: 180.0, age: 28))
    }
}

