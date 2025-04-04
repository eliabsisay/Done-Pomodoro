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
    
    private static let hasSeededKey = Constants.UserDefaultsKeys.hasCreatedDefaultTask
    
    static func seedIfNeeded(using taskRepo: TaskRepository) {
        let hasSeeded = UserDefaults.standard.bool(forKey: hasSeededKey)
        guard !hasSeeded else {
            print("Default task data already seeded.")
            return
        }

        // Generate a random system color
        let systemColors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
        let selectedColor = systemColors.randomElement() ?? .blue
        
        // Convert Color to Data (via UIColor archive)
        let uiColor = UIColor(selectedColor)
        let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)

        // Create default task
        _ = taskRepo.createTask(
            name: "My First Task",
            color: colorData ?? Data(),
            workDuration: 25,
            shortBreakDuration: 5,
            longBreakDuration: 15,
            longBreakAfter: 4,
            dailyGoal: 4,
            startBreaksAutomatically: true,
            startWorkSessionsAutomatically: false
        )
        
        // Mark as seeded
        UserDefaults.standard.set(true, forKey: hasSeededKey)
        print("✅ Default task seeded.")
    }
}
