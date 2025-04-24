//
//  DevEnvironment.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/19/25.
//

import Foundation

/// A helper used during development and debugging to simulate a "clean slate" environment on launch.
/// Use this to delete all data, reset seed flags, or force reseeding of default content.
struct DevEnvironment {
    
    /// Set to `true` to delete all existing tasks when the app launches.
    static let shouldDeleteAllTasks = false
    
    /// Set to `true` to reset the default seed flag and force reseeding tasks.
    static let shouldForceReseedTasks = false
    
    /// Set to `true` to delete all saved work sessions from Core Data on app launch.
    static let shouldDeleteAllSessions = false
    
    /// Applies all enabled development behaviors.
    static func configure() {
        // Create repository instances for data operations
        let taskRepo = TaskRepository()
        let sessionRepo = WorkSessionRepository()

        // 🧹 Delete all tasks if toggled on (useful during iteration)
        if shouldDeleteAllTasks {
            taskRepo.deleteAllTasks()
        }

        // 🧹 Delete all work sessions if toggled on
        if shouldDeleteAllSessions {
            sessionRepo.deleteAllSessions()
        }

        // 🧼 Force reseeding by resetting the "hasCreatedDefaultTask" UserDefaults flag
        if shouldForceReseedTasks {
            UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.hasCreatedDefaultTask)
        }

        // 🚀 Seed the database with a default task if not already present
        DataSeeder.seedIfNeeded(using: taskRepo)
    }
}


