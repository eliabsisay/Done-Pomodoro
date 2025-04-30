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
    @Published var showingTaskPicker = false
    @Published var availableTasks: [Task] = []
    @Published var showTaskCompletedOverlay: Bool = false
    @Published var showingTaskCreationSheet = false

    
    // MARK: - Private Properties
    
    private let timerService = TimerService()
    private let taskRepo = TaskRepository()
    private let sessionRepo = WorkSessionRepository()
    private let sessionManager = SessionManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var taskModifiedObserver: NSObjectProtocol?
    private var sessionCompletionObserver: NSObjectProtocol?
    
    private var sessionStartTime: Date?
    private var totalDuration: TimeInterval = 0
    private var hasLoadedInitialTask = false
    
    // MARK: - Init
    
    init() {
        bindToTimer()
        
        // Listen for task modification events
        taskModifiedObserver = AppEvents.observe(AppEvents.taskModified) { [weak self] notification in
            // Check if the modified task is our current task
            if let modifiedTask = notification.object as? Task,
               let currentTaskID = self?.currentTask?.id,
               modifiedTask.id == currentTaskID {
                print("📝 Current task was modified - updating timer settings")
                self?.updateTimerSettingsFromTask(modifiedTask)
            }
        }
        
        // Listen for session completion events
        sessionCompletionObserver = AppEvents.observe(AppEvents.sessionCompleted) { [weak self] _ in
            print("⏱️ Session completed - refreshing available tasks")
            self?.loadAvailableTasks()
        }
        
        // Delay task loading to avoid Core Data timing issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadAvailableTasks()
            
            // Check if we have a previously selected task ID
            if let savedTaskIDString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastSelectedTaskID),
               let savedTaskID = UUID(uuidString: savedTaskIDString) {
                // Try to find the task with this ID
                self.currentTask = self.availableTasks.first { $0.id == savedTaskID }
                print("🔄 Restored previously selected task: \(self.currentTask?.name ?? "Not found")")
            }
            
            // If no task was restored or found, use the first available task
            if self.currentTask == nil, let firstTask = self.availableTasks.first {
                self.currentTask = firstTask
                print("🧠 Using first available task: \(firstTask.name ?? "Unnamed Task")")
            }
            
            self.hasLoadedInitialTask = true
            
            // Restore session or prepare for start
            if SessionRestorer.hasPersistedSession {
                self.restoreIfNeeded()
            } else if let task = self.currentTask {
                let defaultDuration = TimeInterval(task.workDuration * 60)
                if task.startWorkSessionsAutomatically {
                    self.startSession(for: task, type: .work, duration: defaultDuration)
                    print("🚀 Auto-starting default session")
                } else {
                    self.sessionType = .work
                    self.totalDuration = defaultDuration
                    self.timeRemaining = defaultDuration
                    self.isRunning = false
                    print("🛑 No prior session found — awaiting manual start")
                }
            } else {
                print("⚠️ No task available to load.")
            }
        }
    }
    
    deinit {
        // Clean up observers
        if let observer = taskModifiedObserver {
            AppEvents.removeObserver(observer)
        }
        
        if let observer = sessionCompletionObserver {
            AppEvents.removeObserver(observer)
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
    
    // MARK: - Task Management
    
    /// Loads all available (non-completed) tasks
    func loadAvailableTasks() {
        self.availableTasks = taskRepo.getAllTasks().filter { !$0.isCompleted }
        print("📋 Loaded \(availableTasks.count) available tasks for picker")
        
        // If we had a task selected that's now completed, clear it
        if let currentTask = currentTask, currentTask.isCompleted {
            self.currentTask = nil
        }
    }
    
    /// Selects a task and updates the timer settings
    func selectTask(_ task: Task) {
        self.currentTask = task
        print("🎯 Selected task: \(task.name ?? "Unnamed Task")")
        
        // Reset the timer state for the new task
        let duration = TimeInterval(task.workDuration * 60)
        self.sessionType = .work
        self.totalDuration = duration
        self.timeRemaining = duration
        self.isRunning = false
        
        // Update UserDefaults to remember the selected task
        if let taskID = task.id {
            UserDefaults.standard.set(taskID.uuidString, forKey: Constants.UserDefaultsKeys.lastSelectedTaskID)
        }
    }
    
    /// Refreshes the task list and optionally selects the first task if none is selected
    func refreshTaskList() {
        // Reload available tasks after a new task is created
        loadAvailableTasks()
        
        // If we're coming directly back from creating a task,
        // the most recent one is likely the one the user wants to use
        if currentTask == nil, let lastTask = availableTasks.first {
            selectTask(lastTask)
        }
    }
    
    /// Updates timer settings from a modified task
    private func updateTimerSettingsFromTask(_ task: Task) {
        // Only update if no active session is running
        guard !isRunning, sessionStartTime == nil else {
            print("⚠️ Cannot update timer settings during active session")
            return
        }
        
        // Update session duration based on current session type
        let updatedDuration: TimeInterval
        switch sessionType {
        case .work:
            updatedDuration = TimeInterval(task.workDuration * 60)
        case .shortBreak:
            updatedDuration = TimeInterval(task.shortBreakDuration * 60)
        case .longBreak:
            updatedDuration = TimeInterval(task.longBreakDuration * 60)
        }
        
        // Update the timer settings
        self.totalDuration = updatedDuration
        self.timeRemaining = updatedDuration
        
        print("🔄 Updated timer settings for task \(task.name ?? "Unknown"):")
        print("- Session Type: \(sessionType.rawValue)")
        print("- New Duration: \(updatedDuration.formattedAsTimer)")
    }
    
    /// Completes the current task and ends the session
    func completeTask() {
        guard let task = currentTask else {
            print("❌ No task to complete")
            return
        }
        
        // Log the session as completed if appropriate
        if let start = sessionStartTime {
            sessionManager.logCompletedSession(task: task,
                                               start: start,
                                               sessionType: sessionType,
                                               totalDuration: totalDuration)
        }
        
        // Mark the task as completed
        task.isCompleted = true
        task.completedAt = Date()
        taskRepo.updateTask(task)
        print("✅ Marked task as complete: \(task.name ?? "Unnamed Task")")
        
        // Reset timer and notify
        timerService.stop()
        NotificationService.shared.cancelAll()
        
        // Post notification that the task was completed (for other views to update)
        AppEvents.post(AppEvents.taskModified, object: task)
        AppEvents.post(AppEvents.sessionCompleted)
        
        // 🚀 Show the success overlay
        showTaskCompletedOverlay = true
        
        // Reset the state
        resetState()
        
        // Automatically hide the overlay after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            withAnimation {
                self?.showTaskCompletedOverlay = false
            }
        }
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
        
        // Save the task ID
        if let taskID = task.id?.uuidString {
            UserDefaults.standard.set(taskID, forKey: Constants.UserDefaultsKeys.lastSelectedTaskID)
        }
        
        NotificationService.shared.scheduleSessionEndNotification(in: duration, sessionType: type)
    }
    
    func pause() {
        timerService.pause()
    }
    
    func resume() {
        timerService.resume()
    }
    
    func cancel() {
        // Stop the timer and cancel notifications
        timerService.stop()
        NotificationService.shared.cancelAll()
        
        // Save the current task and session type before resetting
        let task = currentTask
        let currentSessionType = sessionType
        
        // Clear session state but keep the task and session type
        sessionStartTime = nil
        isRunning = false
        
        // Remove session data from UserDefaults
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionStartDate)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionDuration)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionType)
        
        // Restore the task and reset timer to appropriate duration
        if let task = task {
            // Reset the timer based on current session type
            let newDuration: TimeInterval
            switch currentSessionType {
            case .work:
                newDuration = TimeInterval(task.workDuration * 60)
            case .shortBreak:
                newDuration = TimeInterval(task.shortBreakDuration * 60)
            case .longBreak:
                newDuration = TimeInterval(task.longBreakDuration * 60)
            }
            
            // Update the timer settings
            totalDuration = newDuration
            timeRemaining = newDuration  // This updates the display time
            
            // Update the timer service to ensure it's in a clean state
            timerService.timeRemaining = newDuration
            timerService.state = .stopped
            
            print("⏹️ Canceled session for task: \(task.name ?? "Unknown")")
            print("- Session type: \(currentSessionType.rawValue)")
            print("- Reset timer to: \(newDuration.formattedAsTimer)")
        }
    }
    
    func completeEarly() {
        timerService.stop()
        NotificationService.shared.cancelAll()
        handleSessionCompletion()
    }
    
    /// Resets everything back to “no active session”
    /// and kicks the UI into “pick a new task” mode.
    private func resetState() {
        // Clear out the current task so the picker becomes empty
        currentTask = nil

        // Clear out any leftover timing state
        sessionStartTime = nil
        totalDuration = 0
        isRunning = false
        timeRemaining = 0

        // Clean up any persisted session info
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
    
    /// Completes the current session only and transitions to the next session, manually triggered when the user clicks the "Complete Session" button.
    func completeWorkSession() {
        guard let task = currentTask else {
            print("❌ No task to complete session for")
            return
        }
        
        guard let start = sessionStartTime else {
            print("⚠️ No session start time found")
            return
        }
        
        // Only log work sessions as completed
        if sessionType == .work {
            // Log the session as completed with full credit
            sessionManager.logCompletedSession(
                task: task,
                start: start,
                sessionType: sessionType,
                totalDuration: totalDuration,
                intervalCount: 1.0 // Force full credit for the interval
            )
        }
        
        // Stop timer and cancel notifications
        timerService.stop()
        NotificationService.shared.cancelAll()
        
        // Clear session start time before transitioning
        sessionStartTime = nil
        
        // Transition to the next session
        transitionToNextSession()
        
        // Post notification that a session was completed
        AppEvents.post(AppEvents.sessionCompleted)
    }
    
    /// Called when a session naturally completes (timer reaches zero)
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
            return
        }
        
        // Log only completed work sessions
        sessionManager.logCompletedSession(task: task,
                                           start: start,
                                           sessionType: sessionType,
                                           totalDuration: totalDuration)
        
        NotificationService.shared.cancelAll()
        transitionToNextSession()
        
        // Post notification that a session was completed
        AppEvents.post(AppEvents.sessionCompleted)
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
            
            // Make sure timer service values are updated too
            timerService.timeRemaining = nextDuration
            
            UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeSessionStartDate)
            UserDefaults.standard.set(nextDuration, forKey: Constants.UserDefaultsKeys.activeSessionDuration)
            UserDefaults.standard.set(nextType.rawValue, forKey: Constants.UserDefaultsKeys.activeSessionType)
            
            print("🛑 Waiting for user to start next session: \(nextType) — \(nextDuration.formattedAsTimer)")
        }
    }
    
    // MARK: - Static Helpers
    
    /// Static method to check if a task is in an active session
    static func isTaskInActiveSession(_ task: Task) -> Bool {
        // Check UserDefaults for active session
        guard let startDateValue = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionStartDate) as? Date,
              let sessionTypeRaw = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.activeSessionType),
              let activeTaskID = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastSelectedTaskID),
              let taskID = task.id?.uuidString else {
            return false
        }
        
        // If the active task ID matches this task's ID and there's a non-expired session
        return activeTaskID == taskID && Date().timeIntervalSince(startDateValue) <
            UserDefaults.standard.double(forKey: Constants.UserDefaultsKeys.activeSessionDuration)
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
        // A session is startable when:
        // 1. It's not currently running
        // 2. There's no active session (sessionStartTime is nil)
        // 3. We have a timeRemaining value greater than 0
        // 4. We have a currentTask selected
        return !isRunning &&
               sessionStartTime == nil &&
               timeRemaining > 0 &&
               currentTask != nil
    }
}

extension WorkSessionViewModel {
    
    /// Returns true if there are no incomplete tasks available
    var hasNoIncompleteTasks: Bool {
        return availableTasks.isEmpty
    }
    
    /// Opens the task creation view
    func showTaskCreationView() {
        // We'll need a way to present the TaskEditView
        // This will be handled by a new published property
        showingTaskCreationSheet = true
    }
}
