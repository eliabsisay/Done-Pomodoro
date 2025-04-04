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
    
    init() {
        SettingsService.shared.registerDefaults()
        NotificationService.shared.requestPermission()
        DataSeeder.seedIfNeeded(using: TaskRepository())
    }
    
    
    var body: some Scene {
        WindowGroup {
            Text("Done App Placeholder")
        }
    }
}
