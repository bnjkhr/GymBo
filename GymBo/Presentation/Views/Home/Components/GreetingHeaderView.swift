//
//  GreetingHeaderView.swift
//  GymTracker
//
//  Created on 2025-10-24.
//  V2 Clean Architecture - Greeting Header with Locker Number
//

import SwiftUI

/// Header view with time-based greeting, locker number widget, and profile button
struct GreetingHeaderView: View {
    @Binding var showProfile: Bool
    @Binding var showLockerInput: Bool
    @AppStorage("lockerNumber") private var lockerNumber: String?

    let userProfile: DomainUserProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Greeting + Profile Button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    if let timeOfDay = timeOfDayGreeting {
                        Text(timeOfDay)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Profile Button with Image or Icon (larger)
                Button {
                    showProfile = true
                } label: {
                    if let imageData = userProfile?.profileImageData,
                        let uiImage = UIImage(data: imageData)
                    {
                        // Show profile image
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        // Show default icon
                        Image(systemName: "person.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profil öffnen")
            }

            // Locker Number as Text Link (below greeting)
            LockerNumberTextLink(
                lockerNumber: lockerNumber,
                showLockerInput: $showLockerInput
            )
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Computed Properties

    private var greeting: String {
        if let name = userProfile?.name, !name.isEmpty {
            return "Hey \(name),"
        } else {
            return "Hey"
        }
    }

    private var timeOfDayGreeting: String? {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            return "guten Morgen!"
        case 12..<18:
            return "guten Tag!"
        case 18..<24, 0..<5:
            return "guten Abend!"
        default:
            return nil
        }
    }
}

// MARK: - Locker Number Text Link

private struct LockerNumberTextLink: View {
    let lockerNumber: String?
    @Binding var showLockerInput: Bool
    @State private var showDeleteConfirmation = false
    @AppStorage("lockerNumber") private var storedLockerNumber: String?

    var body: some View {
        Button {
            if lockerNumber != nil {
                showDeleteConfirmation = true
            } else {
                showLockerInput = true
            }
        } label: {
            if let number = lockerNumber {
                // Show: "Spintnummer: XX"
                Text("Spintnummer: \(number)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Show: "Spintnummer hinterlegen"
                Text("Spintnummer hinterlegen")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        .buttonStyle(.plain)
        .confirmationDialog("Spintnummer", isPresented: $showDeleteConfirmation) {
            Button("Nummer ändern") {
                showLockerInput = true
            }
            Button("Nummer löschen", role: .destructive) {
                withAnimation(.spring(response: 0.3)) {
                    storedLockerNumber = nil
                }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            if let number = lockerNumber {
                Text("Spint \(number)")
            }
        }
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("With Profile & Locker") {
    GreetingHeaderView(
        showProfile: .constant(false),
        showLockerInput: .constant(false),
        userProfile: DomainUserProfile(
            name: "Max",
            age: 28,
            healthKitEnabled: false
        )
    )
    .onAppear {
        UserDefaults.standard.set("127", forKey: "lockerNumber")
    }
}
#endif

#if DEBUG
#Preview("Without Profile") {
    GreetingHeaderView(
        showProfile: .constant(false),
        showLockerInput: .constant(false),
        userProfile: nil
    )
    .onAppear {
        UserDefaults.standard.removeObject(forKey: "lockerNumber")
    }
}
#endif
