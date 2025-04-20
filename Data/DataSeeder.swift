//
//  DataSeeder.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/3/25.
//

import Foundation
import SwiftUI

/// Responsible for seeding default data on first launch.
struct DataSeeder {
    
    /// Convenience reference to the UserDefaults key that tracks whether we’ve seeded tasks before
    private static let hasSeededKey = Constants.UserDefaultsKeys.hasCreatedDefaultTask
    
    /// Seeds a default demo task if none exists (used during development and first launch)
    /// - Parameter taskRepo: The task repository instance used to interact with Core Data.
    static func seedIfNeeded(using taskRepo: TaskRepository) {
        // Check if seeding has already occurred to prevent duplicates
        let hasSeeded = UserDefaults.standard.bool(forKey: hasSeededKey)
        guard !hasSeeded else {
            print("Default task data already seeded.")
            return
        }
        
        // Generate a random system color for demo task
        let systemColors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
        let selectedColor = systemColors.randomElement() ?? .purple
        
        // Convert Color to Data (via UIColor archive)
        let uiColor = UIColor(selectedColor)
        let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        
        // Create a demo task using pre-defined default settings
        _ = taskRepo.createTask(
            name: "Demo Task",
            color: colorData ?? Data(),
            workDuration: 1,
            shortBreakDuration: 2,
            longBreakDuration: 3,
            longBreakAfter: 3,
            dailyGoal: 4,
            startBreaksAutomatically: false,
            startWorkSessionsAutomatically: false
        )
        
        // Mark as seeded to avoid reseeding on future launches
        UserDefaults.standard.set(true, forKey: hasSeededKey)
        print("✅ Default task seeded.")
    }
    
    /// Deletes all tasks from storage (used to simulate a clean slate during development)
    /// - Parameter taskRepo: The task repository to access and delete task records.
    static func deleteAllTasks(using taskRepo: TaskRepository) {
        let tasks = taskRepo.getAllTasks()
        for task in tasks {
            taskRepo.deleteTask(task)
        }
        print("🧹 Deleted \(tasks.count) existing tasks.")
    }
    
}
