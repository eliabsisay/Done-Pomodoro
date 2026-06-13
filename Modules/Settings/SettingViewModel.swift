//
//  SettingsViewModel.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for handling general app settings.
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Controls the app's appearance mode (system, light, dark)
    @Published var appearanceMode: Constants.AppearanceMode {
        didSet {
            settingsService.appearanceMode = appearanceMode
        }
    }
    
    /// Controls whether the screen sleep is prevented during timer sessions
    @Published var preventSleep: Bool {
        didSet {
            settingsService.preventSleep = preventSleep
            updateSleepPrevention()
        }
    }
    
    /// Controls the sound played when a work session completes
    @Published var workCompletedSound: String {
        didSet {
            settingsService.workCompletedSound = workCompletedSound
        }
    }
    
    /// Controls the sound played when a break session completes
    @Published var breakCompletedSound: String {
        didSet {
            settingsService.breakCompletedSound = breakCompletedSound
        }
    }
    
    /// Flag to control the "About" section sheet presentation
    @Published var showingAboutSheet = false
    
    /// Flag to control the "How it Works" tutorial sheet presentation
    @Published var showingTutorialSheet = false
    
    /// Current notification permission status
    @Published var notificationsAuthorized = false
    
    /// Whether to use notifications
    @Published var pushNotificationsEnabled: Bool {
        didSet {
            settingsService.pushNotificationsEnabled = pushNotificationsEnabled
            if pushNotificationsEnabled && !notificationsAuthorized {
                requestNotificationPermission()
            }
        }
    }
    
    // MARK: - Private Properties
    
    /// Reference to the settings service for persistence
    private let settingsService = SettingsService.shared
    private let notificationService = NotificationService.shared
    
    /// Single source of truth for the selectable sound options.
    /// iOS local notifications only support the system default sound or a
    /// bundled custom file; until custom sounds are bundled, we offer the
    /// honest set: the default sound, or none (a silent banner).
    /// Keep this in sync with `NotificationService.getSoundFor`.
    static let supportedSounds = ["default", "none"]

    /// Available sound options for session completion (drives the Settings pickers).
    let availableSounds = SettingsViewModel.supportedSounds
    
    // MARK: - Init
    
    init() {
        // Initialize published properties from stored settings.
        // Legacy sound values (e.g. "ding"/"chime" from before custom sounds
        // were removed) are coerced to "default" so the pickers show a valid
        // selection instead of a blank.
        self.appearanceMode = settingsService.appearanceMode
        self.preventSleep = settingsService.preventSleep
        self.workCompletedSound = SettingsViewModel.supportedSounds.contains(settingsService.workCompletedSound)
            ? settingsService.workCompletedSound : "default"
        self.breakCompletedSound = SettingsViewModel.supportedSounds.contains(settingsService.breakCompletedSound)
            ? settingsService.breakCompletedSound : "default"
        self.pushNotificationsEnabled = settingsService.pushNotificationsEnabled

        // Persist any coercion above so the stored value matches what's shown.
        settingsService.workCompletedSound = workCompletedSound
        settingsService.breakCompletedSound = breakCompletedSound

        print("📱 Settings loaded:")
        print("- Appearance Mode: \(appearanceMode.rawValue)")
        print("- Prevent Sleep: \(preventSleep)")
        print("- Work Sound: \(workCompletedSound)")
        print("- Break Sound: \(breakCompletedSound)")
        print("- Push Notifications: \(pushNotificationsEnabled)")
        
        // Apply current sleep prevention setting
        updateSleepPrevention()
        
        // Check notification permission status
        checkNotificationPermission()
    }
    
    // MARK: - Methods
    
    /// Updates the device sleep prevention based on user settings
    private func updateSleepPrevention() {
        UIApplication.shared.isIdleTimerDisabled = preventSleep
        print("💤 Sleep prevention updated: \(preventSleep ? "enabled" : "disabled")")
    }
    
    /// Requests app review using StoreKit
    func requestAppReview() {
        #if !DEBUG
        // In a real app, we would use the following code:
        // import StoreKit
        // if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        //     SKStoreReviewController.requestReview(in: scene)
        // }
        #endif
        
        print("⭐️ App review requested")
    }
    
    /// Checks the current notification permission status
    func checkNotificationPermission() {
        notificationService.checkPermissionStatus { [weak self] authorized in
            DispatchQueue.main.async {
                self?.notificationsAuthorized = authorized
                print("🔔 Notification permission status: \(authorized ? "authorized" : "denied")")
            }
        }
    }
    
    /// Requests notification permission from the user
    func requestNotificationPermission() {
        notificationService.requestPermission()
        
        // Check the status again after a short delay to update UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkNotificationPermission()
        }
    }
}
