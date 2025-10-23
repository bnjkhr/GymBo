//
//  DependencyContainerEnvironmentKey.swift
//  GymBo
//
//  Created on 2025-10-23.
//

import SwiftUI

/// Environment key for DependencyContainer
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer? = nil
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer? {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}
