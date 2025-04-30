//
//  Constants.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/1/25.
//

import Foundation

/// Central place for all app constants.
enum Constants {
    
    /// Keys used with UserDefaults
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasCreatedDefaultTask = "hasCreatedDefaultTask"
        static let hideStatusBar = "hideStatusBar"
        static let preventSleep = "preventSleep"
        static let workCompletedSound = "workCompletedSound"
        static let breakCompletedSound = "breakCompletedSound"
        static let pushNotificationsEnabled = "pushNotificationsEnabled"
        static let reportViewType = "reportViewType"
        static let reportUnits = "reportUnits"
        static let reportPeriod = "reportPeriod"
        static let appearanceMode = "appearanceMode"
        static let activeSessionStartDate = "activeSessionStartDate"
        static let activeSessionDuration = "activeSessionDuration"
        static let activeSessionType = "activeSessionType"
        static let lastSelectedTaskID = "lastSelectedTaskID"
    }
   
    /// App-specific label strings for session types
        enum SessionLabels {
            static let work = "Work Session"
            static let shortBreak = "Short Break"
            static let longBreak = "Long Break"
        }
    
    /// UI Mode
    enum AppearanceMode: String {
        case system
        case light
        case dark
    }

    /// Identifiers for local notifications
    enum NotificationConstants {
        static let workSessionEnded = "workSessionEndedNotification"
        static let breakSessionEnded = "breakSessionEndedNotification"
        static let dailyGoalReminder = "dailyGoalReminderNotification"
    }
    
    /// App-wide UI constants
    enum UI {
        static let defaultPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
    }
}

