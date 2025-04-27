//
//  SessionManager.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/19/25.
//
import Foundation

/// Manages the logic for completing sessions and transitioning to the next one.
/// It also logs completed work sessions and handles notification cleanup.
final class SessionManager {
    
    // MARK: - Properties
    
    private let sessionRepo: WorkSessionRepository
    
    /// Tracks the number of completed work sessions (used to trigger long breaks)
    private(set) var completedWorkSessions: Int = 0
    
    static let sessionCompletedNotification = Notification.Name("sessionCompletedNotification")
    
    // MARK: - Init
    
    /// Initializes a new SessionManager instance
    /// - Parameter sessionRepo: Optional session repository (default to shared context)
    init(sessionRepo: WorkSessionRepository = WorkSessionRepository()) {
        self.sessionRepo = sessionRepo
    }
    
    // MARK: - Public Methods
    
    /// Logs a completed work session to Core Data.
    /// - Parameters:
    ///   - task: The current task
    ///   - start: The session's start time
    ///   - sessionType: The type of session (work, shortBreak, longBreak)
    ///   - totalDuration: Full intended duration (used to calculate progress)
    ///   - end: The current time (used to determine how long the session actually ran)
    func logCompletedSession(task: Task,
                             start: Date,
                             sessionType: SessionType,
                             totalDuration: TimeInterval,
                             end: Date = Date()) {
        
        let elapsed = end.timeIntervalSince(start)
        
        // Determine how much credit to assign based on % completed
        let percentComplete = elapsed / totalDuration
        let intervalCount: Double = {
            if percentComplete >= 0.8 {
                print("📊 Session percent complete: \(percentComplete) — Full credit (1)")
                return 1
            } else if percentComplete >= 0.5 {
                print("📊 Session percent complete: \(percentComplete) — Half credit (0.5)")
                return 0.5
            } else {
                print("📊 Session percent complete: \(percentComplete) — No credit (0)")
                return 0
            }
        }()
        
        guard sessionType == .work, intervalCount > 0 else {
            print("🚫 Skipping session logging — Type: \(sessionType.rawValue), Credit: \(intervalCount)")
            return
        }
        
        // Save the session to Core Data
        _ = sessionRepo.createSession(
            for: task,
            startTime: start,
            type: sessionType.rawValue,
            isPaused: false,
            isCompleted: true,
            duration: elapsed / 60,  // Store in minutes
            intervalCount: intervalCount,
            pauseTime: nil,
            totalPauseDuration: 0
        )
        
        completedWorkSessions += 1
        
        // Notify observers that a session was completed
        AppEvents.post(AppEvents.sessionCompleted)
        
        print("📝 Logged completed work session:")
        print("- Task: \(task.name ?? "Unnamed Task")")
        print("- Duration: \(elapsed.formatted(.number.precision(.fractionLength(2)))) seconds")
        print("- Interval Count: \(intervalCount)")
        print("- Total Work Sessions Completed: \(completedWorkSessions)")
    }
    
    /// Determines the next session type and its duration.
    /// - Parameter currentSessionType: The current session type (work, break, etc)
    /// - Parameter task: The associated task (for duration settings)
    /// - Returns: A tuple containing the next session type and its duration in seconds
    func nextSession(after currentSessionType: SessionType, for task: Task) -> (SessionType, TimeInterval) {
        let nextType: SessionType
        let nextDuration: TimeInterval
        
        switch currentSessionType {
        case .work:
            let useLongBreak = completedWorkSessions % Int(task.longBreakAfter) == 0
            nextType = useLongBreak ? .longBreak : .shortBreak
            nextDuration = useLongBreak
            ? TimeInterval(task.longBreakDuration * 60)
            : TimeInterval(task.shortBreakDuration * 60)
        case .shortBreak, .longBreak:
            nextType = .work
            nextDuration = TimeInterval(task.workDuration * 60)
        }
        
        print("🔁 Determined next session:")
        print("- From: \(currentSessionType.rawValue)")
        print("- To: \(nextType.rawValue)")
        print("- Duration: \(Int(nextDuration)) seconds")
        
        return (nextType, nextDuration)
    }
    
    /// Determines whether the given session type should auto-start.
    /// - Parameters:
    ///   - type: The session type we're transitioning to.
    ///   - task: The current task (holds session auto-start settings).
    func shouldAutoStart(_ type: SessionType, for task: Task) -> Bool {
        let shouldStart: Bool
        
        switch type {
        case .work:
            shouldStart = task.startWorkSessionsAutomatically
        case .shortBreak, .longBreak:
            shouldStart = task.startBreaksAutomatically
        }
        
        print("⚙️ Auto-start check for \(type.rawValue): \(shouldStart)")
        return shouldStart
    }
}

