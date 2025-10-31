//
//  RepositoryError.swift
//  GymBoTests
//
//  Common repository error type for test mocks
//

import Foundation

/// Common repository error type used across test mocks
enum RepositoryError: Error, LocalizedError {
    case notFound(UUID)
    case saveFailed(String)
    case updateFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Entity with ID \(id.uuidString) not found"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .updateFailed(let message):
            return "Failed to update: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete: \(message)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
