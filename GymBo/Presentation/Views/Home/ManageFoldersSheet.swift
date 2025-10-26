//
//  ManageFoldersSheet.swift
//  GymBo
//
//  Created on 2025-10-26.
//

import SwiftUI

/// Sheet for managing workout folders/categories
struct ManageFoldersSheet: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore

    @State private var showCreateFolder = false
    @State private var editingFolder: WorkoutFolder?

    var body: some View {
        @Bindable var store = workoutStore

        NavigationStack {
            List {
                ForEach(store.folders) { folder in
                    HStack {
                        // Color indicator
                        Circle()
                            .fill(Color(hex: folder.color) ?? .purple)
                            .frame(width: 24, height: 24)

                        Text(folder.name)
                            .font(.body)

                        Spacer()

                        // Workout count
                        let count = store.workouts.filter { $0.folderId == folder.id }.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingFolder = folder
                    }
                }
                .onMove { source, destination in
                    // TODO: Implement reordering
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let folder = store.folders[index]
                        Task {
                            await store.deleteFolder(id: folder.id)
                        }
                    }
                }
            }
            .navigationTitle("Kategorien")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Load folders when sheet appears
                await store.loadFolders()
                print("🔄 ManageFoldersSheet: Folders loaded on appear")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateFolder = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateFolder) {
                CreateFolderSheet(mode: .create)
            }
            .onChange(of: showCreateFolder) { oldValue, newValue in
                // Reload folders when create sheet is dismissed
                if !newValue && oldValue {
                    Task {
                        await store.loadFolders()
                        print("🔄 ManageFoldersSheet: Folders reloaded after create sheet dismissed")
                    }
                }
            }
            .sheet(item: $editingFolder) { folder in
                CreateFolderSheet(mode: .edit(folder))
            }
            .onChange(of: editingFolder) { oldValue, newValue in
                // Reload folders when edit sheet is dismissed
                if newValue == nil && oldValue != nil {
                    Task {
                        await store.loadFolders()
                        print("🔄 ManageFoldersSheet: Folders reloaded after edit sheet dismissed")
                    }
                }
            }
        }
    }
}

/// Sheet for creating or editing a folder
struct CreateFolderSheet: View {

    enum Mode {
        case create
        case edit(WorkoutFolder)
    }

    let mode: Mode

    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutStore.self) private var workoutStore

    @State private var name: String = ""
    @State private var selectedColor: String = "#8B5CF6"  // Default purple

    // Available colors
    private let availableColors = [
        "#8B5CF6",  // Purple
        "#EF4444",  // Red
        "#F59E0B",  // Orange
        "#10B981",  // Green
        "#3B82F6",  // Blue
        "#EC4899",  // Pink
        "#6366F1",  // Indigo
        "#14B8A6",  // Teal
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Kategoriename", text: $name)
                }

                Section("Farbe") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(availableColors, id: \.self) { colorHex in
                            Circle()
                                .fill(Color(hex: colorHex) ?? .purple)
                                .frame(width: 50, height: 50)
                                .overlay {
                                    if selectedColor == colorHex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                    }
                                }
                                .onTapGesture {
                                    selectedColor = colorHex
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(mode.isEdit ? "Kategorie bearbeiten" : "Neue Kategorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.isEdit ? "Speichern" : "Erstellen") {
                        Task {
                            await saveFolder()
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let folder) = mode {
                    name = folder.name
                    selectedColor = folder.color
                }
            }
        }
    }

    private func saveFolder() async {
        switch mode {
        case .create:
            await workoutStore.createFolder(name: name, color: selectedColor)
        case .edit(let folder):
            var updatedFolder = folder
            updatedFolder.name = name
            updatedFolder.color = selectedColor
            await workoutStore.updateFolder(updatedFolder)
        }
    }
}

// MARK: - Mode Helper

extension CreateFolderSheet.Mode {
    var isEdit: Bool {
        if case .edit = self { return true }
        return false
    }
}

#Preview {
    ManageFoldersSheet()
        .environment(WorkoutStore.preview)
}
