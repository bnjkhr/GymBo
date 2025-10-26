//
//  WorkoutFolderMapper.swift
//  GymBo
//
//  Created on 2025-10-26.
//  V2 Clean Architecture - Data Layer
//

import Foundation

/// Mapper for converting between Domain WorkoutFolder entities and SwiftData entities
struct WorkoutFolderMapper {
    
    // MARK: - WorkoutFolder Mapping
    
    /// Convert Domain WorkoutFolder to SwiftData Entity
    func toEntity(_ domain: WorkoutFolder) -> WorkoutFolderEntity {
        WorkoutFolderEntity(
            id: domain.id,
            name: domain.name,
            color: domain.color,
            order: domain.order,
            createdDate: domain.createdDate
        )
    }
    
    /// Convert SwiftData Entity to Domain WorkoutFolder
    func toDomain(_ entity: WorkoutFolderEntity) -> WorkoutFolder {
        WorkoutFolder(
            id: entity.id,
            name: entity.name,
            color: entity.color,
            order: entity.order,
            createdDate: entity.createdDate
        )
    }
    
    /// Update existing entity with domain data
    func updateEntity(_ entity: WorkoutFolderEntity, from domain: WorkoutFolder) {
        entity.name = domain.name
        entity.color = domain.color
        entity.order = domain.order
    }
    
    // MARK: - Batch Mapping
    
    /// Convert array of SwiftData entities to Domain folders
    func toDomain(_ entities: [WorkoutFolderEntity]) -> [WorkoutFolder] {
        entities.map { toDomain($0) }
    }
}
