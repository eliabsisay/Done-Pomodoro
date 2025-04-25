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
    
    // State object to observe app settings for UI updates
    @StateObject private var settingsObserver = AppSettingsObserver()
    
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
                .preferredColorScheme(settingsObserver.colorScheme)
        }
    }
}

// Helper class to observe settings changes for UI updates
class AppSettingsObserver: ObservableObject {
    @Published var colorScheme: ColorScheme?
    
    private let settingsService = SettingsService.shared
    private var observer: NSObjectProtocol?
    
    init() {
        // Set initial value
        updateColorScheme()
        
        // Listen for settings changes
        observer = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateColorScheme()
        }
    }
    
    deinit {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func updateColorScheme() {
        switch settingsService.appearanceMode {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil
        }
    }
}
