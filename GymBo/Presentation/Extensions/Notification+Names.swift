//
//  Notification+Names.swift
//  GymBo
//
//  Created on 2025-10-27.
//  Presentation Layer - Notification Names
//

import Foundation

extension Notification.Name {
    /// Posted when user profile is updated (e.g., weekly workout goal changed)
    static let userProfileDidChange = Notification.Name("userProfileDidChange")
}
