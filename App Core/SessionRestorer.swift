//
//  SessionRestorer.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/19/25.
//

import Foundation

/// Represents a previously saved session pulled from UserDefaults.
struct RestoredSession {
    let startTime: Date
    let totalDuration: TimeInterval
    let timeRemaining: TimeInterval
    let sessionType: SessionType
}

/// Responsible for restoring session state from UserDefaults if the user previously had a session in progress.
struct SessionRestorer {
    
    /// Returns true if a previously saved session exists in UserDefaults.
    static var hasPersistedSession: Bool {
        let hasDate = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionStartDate) != nil
        let hasDuration = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionDuration) != nil
        let hasType = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionType) != nil
        return hasDate && hasDuration && hasType
    }
    
    /// Attempts to restore a Pomodoro session from persisted UserDefaults values.
    /// - Returns: A `RestoredSession` object if restoration is possible; otherwise `nil`.
    static func restore() -> RestoredSession? {
        // Read persisted session values from UserDefaults
        guard
            let startDate = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionStartDate) as? Date,
            let duration = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.activeSessionDuration) as? TimeInterval,
            let rawType = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.activeSessionType),
            let sessionType = SessionType(rawValue: rawType)
        else {
            print("❌ No persisted session state found — skipping restore")
            return nil
        }
        
        print("🔄 Found persisted session state:")
        print("- Start Date: \(startDate)")
        print("- Duration: \(duration) seconds (\(Int(duration / 60)) min)")
        print("- Session Type: \(sessionType.rawValue)")
        
        // Calculate how much time has passed
        let now = Date()
        let elapsed = now.timeIntervalSince(startDate)
        let remaining = max(duration - elapsed, 0)
        
        print("🕒 Elapsed Time: \(elapsed) seconds")
        print("⏳ Remaining Time: \(remaining) seconds")
        
        // If the session already expired, return nil
        guard remaining > 0 else {
            print("✅ Session already expired — skipping restore")
            return nil
        }
        
        // Create and return a wrapped session object
        return RestoredSession(
            startTime: startDate,
            totalDuration: duration,
            timeRemaining: remaining,
            sessionType: sessionType
        )
    }
}
