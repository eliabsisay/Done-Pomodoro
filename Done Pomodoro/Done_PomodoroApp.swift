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
    
    // Track app lifecycle
    @Environment(\.scenePhase) var scenePhase
    
    /// App-wide configuration that runs once when the app launches
    init() {
        // 📲 Register default UserDefaults values for first launch
        SettingsService.shared.registerDefaults()
        
        // Initialize app lifecycle flags
            UserDefaults.standard.set(false, forKey: "app_clean_exit")
            UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.shouldRestoreSession)
        
        // 🔔 Ask the user for permission to send local notifications
        NotificationService.shared.requestPermission()
        
        // 🧪 Apply development-only configurations (delete/seed data, etc.)
        DevEnvironment.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(settingsObserver.colorScheme)
            // Add scene phase handling
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        // App has become active
                        // No action needed here for our approach
                    } else if newPhase == .background {
                        // App is entering background - mark as "clean exit expectation"
                        UserDefaults.standard.set(true, forKey: "app_clean_exit")
                    }
                }
        }
    }
    
    /// Handles cleanup when app was terminated and relaunched
    private func handleAppTermination() {
        // Clear any active session data
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionStartDate)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionDuration)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionType)
        print("🔄 App was terminated and relaunched - cleaned up session state")
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
