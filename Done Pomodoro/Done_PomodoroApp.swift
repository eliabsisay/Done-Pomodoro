//
//  Done_PomodoroApp.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 3/31/25.
//

import SwiftUI

@main
struct Done_PomodoroApp: App {
    
    let taskRepository = TaskRepository()
    
    /// App-wide configuration that runs once when the app launches
    init() {
        // 📲 Register default UserDefaults values for first launch
        SettingsService.shared.registerDefaults()
        
        // 🔔 Ask the user for permission to send local notifications
        NotificationService.shared.requestPermission()
        
        // 🧪 Apply development-only configurations (delete/seed data, etc.)
        DevEnvironment.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

