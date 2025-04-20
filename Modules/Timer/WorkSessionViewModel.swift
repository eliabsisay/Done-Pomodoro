//
//  WorkSessionViewModel.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/10/25.
//

import Foundation
import Combine
import SwiftUI

/// ViewModel that coordinates the timer, current task, and session lifecycle.
final class WorkSessionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var sessionType: SessionType = .work
    @Published var currentTask: Task?
    
    // MARK: - Private Properties
    
    private let timerService = TimerService()
    private let taskRepo = TaskRepository()
    private let sessionRepo = WorkSessionRepository()
    private let sessionManager = SessionManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    private var sessionStartTime: Date?
    private var totalDuration: TimeInterval = 0
    private var hasLoadedInitialTask = false
    
    // MARK: - Init
    
    init() {
        bindToTimer()
        
        // Delay task loading to avoid Core Data timing issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let allTasks = self.taskRepo.getAllTasks()
            print("📋 All tasks found: \(allTasks.map { $0.name ?? "Unnamed Task" })")
            
            if let firstTask = allTasks.first {
                self.currentTask = firstTask
                self.hasLoadedInitialTask = true
                print("🧠 Task loaded:")
                print("- Name: \(firstTask.name ?? "nil")")
                
                // Restore or start session
                if SessionRestorer.hasPersistedSession {
                    self.restoreIfNeeded()
                } else {
                    let defaultDuration = TimeInterval(firstTask.workDuration * 60)
                    if firstTask.startWorkSessionsAutomatically {
                        self.startSession(for: firstTask, type: .work, duration: defaultDuration)
                        print("🚀 Auto-starting default session")
                    } else {
                        self.sessionType = .work
                        self.totalDuration = defaultDuration
                        self.timeRemaining = defaultDuration
                        self.isRunning = false
                        print("🛑 No prior session found — awaiting manual start")
                    }
                }
            } else {
                print("⚠️ No task available to load.")
            }
        }
    }
    
    // MARK: - Bindings
    
    private func bindToTimer() {
        timerService.$timeRemaining
            .receive(on: DispatchQueue.main)
            .assign(to: &$timeRemaining)
        
        timerService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isRunning = (state == .running)
                if state == .stopped {
                    self?.handleSessionCompletion()
                }
            }
            .store(in: &cancellables)
        
        timerService.$sessionType
            .receive(on: DispatchQueue.main)
            .assign(to: &$sessionType)
    }
    
    // MARK: - Timer Control
    
    func startSession(for task: Task, type: SessionType, duration: TimeInterval) {
        self.currentTask = task
        self.sessionType = type
        self.sessionStartTime = Date()
        self.totalDuration = duration
        
        timerService.start(duration: duration, type: type)
        
        UserDefaults.standard.set(Date(), forKey: Constants.UserDefaultsKeys.activeSessionStartDate)
        UserDefaults.standard.set(duration, forKey: Constants.UserDefaultsKeys.activeSessionDuration)
        UserDefaults.standard.set(type.rawValue, forKey: Constants.UserDefaultsKeys.activeSessionType)
        
        NotificationService.shared.scheduleSessionEndNotification(in: duration, sessionType: type)
    }
    
    func pause() {
        timerService.pause()
    }
    
    func resume() {
        timerService.resume()
    }
    
    func cancel() {
        timerService.stop()
        NotificationService.shared.cancelAll()
        resetState()
    }
    
    func completeEarly() {
        timerService.stop()
        NotificationService.shared.cancelAll()
        handleSessionCompletion()
    }
    
    private func resetState() {
        currentTask = nil
        sessionStartTime = nil
        totalDuration = 0
        isRunning = false
        timeRemaining = 0
        
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionStartDate)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionDuration)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionType)
    }
    
    // MARK: - Restore Session
    
    func restoreIfNeeded() {
        // Ensure a current task is loaded before attempting restore
        guard let task = currentTask else {
            print("⚠️ No task loaded — skipping restore.")
            return
        }
        
        // Attempt to restore session state from UserDefaults
        guard let restored = SessionRestorer.restore() else {
            print("❌ No session to restore.")
            return
        }
        
        // Log what we found
        print("✅ Session restored: \(restored.sessionType), \(restored.timeRemaining.formattedAsTimer) remaining")
        
        // Restore state in view model
        self.totalDuration = restored.totalDuration
        self.sessionStartTime = restored.startTime
        self.sessionType = restored.sessionType
        self.timeRemaining = restored.timeRemaining

        // Resume the timer
        timerService.start(duration: restored.timeRemaining, type: restored.sessionType)
    }
    
    // MARK: - Session Completion
    
    private func handleSessionCompletion() {
        guard hasLoadedInitialTask else {
            print("⏳ Task not loaded — ignoring completion.")
            return
        }
        
        guard let task = currentTask else {
            print("❌ currentTask is nil on session completion.")
            resetState()
            return
        }
        
        guard let start = sessionStartTime else {
            print("⚠️ Session missing start time — transitioning anyway.")
            transitionToNextSession()
            return
        }
        
        // Log only completed work sessions
        sessionManager.logCompletedSession(task: task,
                                           start: start,
                                           sessionType: sessionType,
                                           totalDuration: totalDuration)
        
        NotificationService.shared.cancelAll()
        transitionToNextSession()
    }
    
    private func transitionToNextSession() {
        guard let task = currentTask else {
            resetState()
            return
        }
        
        let (nextType, nextDuration) = sessionManager.nextSession(after: sessionType, for: task)
        print("🔁 Transitioning to next session: \(nextType)")
        
        if sessionManager.shouldAutoStart(nextType, for: task) {
            startSession(for: task, type: nextType, duration: nextDuration)
            print("🚀 Auto-starting next session: \(nextType)")
        } else {
            sessionType = nextType
            totalDuration = nextDuration
            sessionStartTime = nil
            timeRemaining = nextDuration
            isRunning = false
            
            UserDefaults.standard.set(nil, forKey: Constants.UserDefaultsKeys.activeSessionStartDate)
            UserDefaults.standard.set(nextDuration, forKey: Constants.UserDefaultsKeys.activeSessionDuration)
            UserDefaults.standard.set(nextType.rawValue, forKey: Constants.UserDefaultsKeys.activeSessionType)
            
            print("🛑 Waiting for user to start next session: \(nextType) — \(nextDuration.formattedAsTimer)")
        }
    }
    
    // MARK: - Helpers
    
    var sessionTypeLabel: String {
        switch sessionType {
        case .work: return Constants.SessionLabels.work
        case .shortBreak: return Constants.SessionLabels.shortBreak
        case .longBreak: return Constants.SessionLabels.longBreak
        }
    }
    
    var progress: CGFloat {
        guard totalDuration > 0 else { return 0 }
        return CGFloat((totalDuration - timeRemaining) / totalDuration)
    }
    
    var taskColor: Color {
        guard let data = currentTask?.color,
              let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor else {
            return Color.primaryColor
        }
        return Color(uiColor)
    }
    
    var isStartable: Bool {
        return !isRunning && sessionStartTime == nil && timeRemaining > 0
    }
}

