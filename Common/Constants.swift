//
//  Constants.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/1/25.
//

import Foundation
import SwiftUI

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
        static let shouldRestoreSession = "shouldRestoreSession"
        static let todoSortOption = "todoSortOption"
        static let doneSortOption = "doneSortOption"
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

    // MARK: - Design system tokens (visual redesign, 2026)
    //
    // The redesign direction is "Calm Glass · Neutral + task-accent": a calm,
    // restrained take on iOS 26 Liquid Glass. These tokens are the single home
    // for spacing/radius/elevation/motion so styling stays consistent and the
    // design-lint guard (scripts/design-lint.sh) has something to point at.

    /// 4pt-based spacing scale. Use these instead of raw padding numbers.
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 12
        static let lg:  CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 44
    }

    /// Corner radii for glass surfaces / cards / pills.
    enum Radius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 18
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        /// Sentinel for fully-rounded (capsule) shapes.
        static let pill: CGFloat = 999
    }

    /// Soft elevation tiers for non-glass shadows (glass surfaces mostly carry
    /// their own depth; these are for the few places that need an explicit drop
    /// shadow). Opacity is pre-tuned; the card modifier dampens it in dark mode.
    enum Elevation {
        struct Tier { let radius: CGFloat; let y: CGFloat; let opacity: Double }
        static let low  = Tier(radius: 8,  y: 3, opacity: 0.10)
        static let high = Tier(radius: 16, y: 8, opacity: 0.16)
    }

    /// Named animations so motion timing is consistent app-wide. Formalizes the
    /// spring/easeInOut values that were already scattered through the views.
    enum Motion {
        /// Quick, responsive — taps, state flips on controls.
        static let snappy  = Animation.spring(response: 0.34, dampingFraction: 0.82)
        /// Calm, smooth — the timer ring trim.
        static let gentle  = Animation.easeInOut(duration: 0.5)
        /// Bouncy reveal — the task-completed success overlay (preserves the
        /// pre-redesign feel: spring(response: 0.4, dampingFraction: 0.7)).
        static let overlay = Animation.spring(response: 0.4, dampingFraction: 0.7)
    }
}

