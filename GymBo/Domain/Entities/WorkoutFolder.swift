//
//  WorkoutFolder.swift
//  GymBo
//
//  Created on 2025-10-26.
//  V2 Clean Architecture - Domain Layer
//

import Foundation

/// Domain Entity representing a workout folder/category
struct WorkoutFolder: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var color: String  // Hex color string (e.g., "#8B5CF6")
    var order: Int
    let createdDate: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String = "#8B5CF6",
        order: Int = 0,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.order = order
        self.createdDate = createdDate
    }
    
    static func == (lhs: WorkoutFolder, rhs: WorkoutFolder) -> Bool {
        lhs.id == rhs.id
    }
}
