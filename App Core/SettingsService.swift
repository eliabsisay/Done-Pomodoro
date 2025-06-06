//
//  SettingsService.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/3/25.
//

import Foundation

/// A service to manage global app settings stored in UserDefaults.
final class SettingsService {
    
    static let shared = SettingsService()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    
    // MARK: - Settings
    
    /// Registers default values for all known settings (called on app launch).
    func registerDefaults() {
        defaults.register(defaults: [
            Constants.UserDefaultsKeys.appearanceMode: "system",
            Constants.UserDefaultsKeys.hasCompletedOnboarding: false,
            Constants.UserDefaultsKeys.hideStatusBar: false,
            Constants.UserDefaultsKeys.preventSleep: false,
            Constants.UserDefaultsKeys.workCompletedSound: "ding",
            Constants.UserDefaultsKeys.breakCompletedSound: "chime",
            Constants.UserDefaultsKeys.pushNotificationsEnabled: true,
        ])
    }
    
    var appearanceMode: Constants.AppearanceMode {
        get {
            let value = defaults.string(forKey: Constants.UserDefaultsKeys.appearanceMode)
            return Constants.AppearanceMode(rawValue: value ?? "system") ?? .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: Constants.UserDefaultsKeys.appearanceMode)
        }
    }
    
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding) }
    }
    
    var hideStatusBar: Bool {
        get { defaults.bool(forKey: Constants.UserDefaultsKeys.hideStatusBar) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.hideStatusBar) }
    }
    
    var preventSleep: Bool {
        get { defaults.bool(forKey: Constants.UserDefaultsKeys.preventSleep) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.preventSleep) }
    }
    
    var workCompletedSound: String {
        get { defaults.string(forKey: Constants.UserDefaultsKeys.workCompletedSound) ?? "ding" }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.workCompletedSound) }
    }
    
    var breakCompletedSound: String {
        get { defaults.string(forKey: Constants.UserDefaultsKeys.breakCompletedSound) ?? "chime" }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.breakCompletedSound) }
    }
    
    var pushNotificationsEnabled: Bool {
        get { defaults.bool(forKey: Constants.UserDefaultsKeys.pushNotificationsEnabled) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.pushNotificationsEnabled) }
    }
}
