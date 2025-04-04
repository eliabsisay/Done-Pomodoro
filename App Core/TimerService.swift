//
//  TimerService.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/3/25.
//

import Foundation
import Combine

/// Enum representing the current state of the timer.
enum TimerState {
    case stopped
    case running
    case paused
}

/// Enum representing the session type (work or break).
enum SessionType: String {
    case work
    case shortBreak
    case longBreak
}

/// A service that manages Pomodoro-style countdown timers.
final class TimerService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var timeRemaining: TimeInterval = 0 // seconds
    @Published var state: TimerState = .stopped
    @Published var sessionType: SessionType = .work
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var totalDuration: TimeInterval = 0
    private var startDate: Date?
    private var pauseDate: Date?
    
    // MARK: - Timer Controls
    
    /// Starts the timer with the given duration and session type.
    func start(duration: TimeInterval, type: SessionType) {
        self.totalDuration = duration
        self.sessionType = type
        self.startDate = Date()
        self.timeRemaining = duration
        self.state = .running
        
        startTimer()
    }
    
    /// Pauses the timer.
    func pause() {
        guard state == .running else { return }
        pauseDate = Date()
        timer?.invalidate()
        state = .paused
    }
    
    /// Resumes the timer from where it left off.
    func resume() {
        guard state == .paused, let pauseDate else { return }
        let pausedDuration = Date().timeIntervalSince(pauseDate)
        startDate = startDate?.addingTimeInterval(pausedDuration)
        self.pauseDate = nil
        state = .running
        startTimer()
    }
    
    /// Stops and resets the timer.
    func stop() {
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
        state = .stopped
    }
    
    // MARK: - Internal Logic
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.tick()
        }
    }
    
    private func tick() {
        guard let startDate else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = max(totalDuration - elapsed, 0)
        
        self.timeRemaining = remaining
        
        if remaining <= 0 {
            self.stop()
            // Notify observers (will hook into NotificationService later)
        }
    }
}
