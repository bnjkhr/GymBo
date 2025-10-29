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
        VStack(alignment: .leading, spacing: 12) {
            // Greeting + Right Side Actions (Locker & Profile)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    if let timeOfDay = timeOfDayGreeting {
                        Text(timeOfDay)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Locker Number Widget (Compact)
                LockerNumberButton(
                    lockerNumber: lockerNumber,
                    showLockerInput: $showLockerInput
                )

                // Profile Button with Image or Icon
                Button {
                    showProfile = true
                } label: {
                    if let imageData = userProfile?.profileImageData,
                        let uiImage = UIImage(data: imageData)
                    {
                        // Show profile image
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        // Show default icon
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profil öffnen")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Computed Properties

    private var greeting: String {
        if let name = userProfile?.name, !name.isEmpty {
            return "Hey \(name)"
        } else {
            return "Hey"
        }
    }

    private var timeOfDayGreeting: String? {
        // Only show time-of-day greeting if name is set
        guard userProfile?.name != nil else {
            // Fallback to old full greeting
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12:
                return "guten Morgen!"
            case 18..<24, 0..<5:
                return "guten Abend!"
            default:
                return nil
            }
        }

        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "guten Morgen"
        case 18..<24, 0..<5:
            return "guten Abend"
        default:
            return nil
        }
    }
}

// MARK: - Locker Number Button (Compact Widget)

private struct LockerNumberButton: View {
    let lockerNumber: String?
    @Binding var showLockerInput: Bool
    @State private var showDeleteConfirmation = false
    @AppStorage("lockerNumber") private var storedLockerNumber: String?

    var body: some View {
        if let number = lockerNumber {
            // Unlocked state: Show number as pill
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill")
                        .font(.caption)
                    Text(number)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
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
                Text("Spint \(number)")
            }
        } else {
            // Locked state: Show lock icon
            Button {
                showLockerInput = true
            } label: {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundColor(.appOrange)
            }
            .buttonStyle(ScaleButtonStyle())
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
