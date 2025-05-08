//
//  TaskListViewModel.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing task lists and operations
final class TaskListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All tasks loaded from the repository
    @Published var tasks: [Task] = []
    
    /// Flag to control the new task sheet presentation
    @Published var showingNewTaskSheet = false
    
    /// Currently selected task for editing
    @Published var editingTask: Task? = nil
    
    /// Holds the task pending deletion
    @Published var taskToDelete: Task? = nil
    
    @Published var showTaskCompletedOverlay: Bool = false
    @Published var lastCompletedTask: Task? = nil
    
    // Alert properties for custom AlertView
    @Published var showingAlertView = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // MARK: - Private Properties / Functions
    
    /// Repository for data access
    private let taskRepo = TaskRepository()
    
    private func switchToTimerTab() {
        // Use NotificationCenter to communicate with MainTabView
        NotificationCenter.default.post(name: Notification.Name("SwitchToTimerTab"), object: nil)
    }
    
    private var taskSelectedObserver: NSObjectProtocol?
    
    // MARK: - Initialization and Cleanup
    
    init() {
        // Load tasks initially
        loadTasks()
        
        // Set up observer for task selection events
        taskSelectedObserver = AppEvents.observe(AppEvents.taskSelected) { [weak self] _ in
            // Refresh the task list to update the indicators
            DispatchQueue.main.async {
                self?.loadTasks()
                print("🔄 Task list refreshed after task selection")
            }
        }
    }
    
    deinit {
        // Clean up observers
        if let observer = taskSelectedObserver {
            AppEvents.removeObserver(observer)
            print("🧹 Removed task selection observer")
        }
    }
    
    // MARK: - Task Access
    
    /// Returns only the incomplete tasks
    var todoTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    /// Returns only the completed tasks
    var doneTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }
    
    // MARK: - Task Operations
    
    /// Loads all tasks from the repository
    func loadTasks() {
        self.tasks = taskRepo.getAllTasks()
        print("📋 Loaded \(tasks.count) tasks from repository")
    }
    
    /// Adds a new task to the repository and refreshes the task list
    func addTask(_ task: Task) {
        taskRepo.updateTask(task)
        loadTasks()
        print("➕ Added new task: \(task.name ?? "Unnamed Task")")
        
        // Post notification that a task was modified
        AppEvents.post(AppEvents.taskModified, object: task)
    }
    
    /// Updates an existing task in the repository and refreshes the task list
    func updateTask(_ task: Task) {
        taskRepo.updateTask(task)
        loadTasks()
        print("📝 Updated task: \(task.name ?? "Unnamed Task")")
        
        AppEvents.post(AppEvents.taskModified, object: task)
    }
    
    /// Marks a task as complete or incomplete, with animation when completing
    func toggleTaskCompletion(_ task: Task) {
        let wasCompleted = task.isCompleted
        task.isCompleted = !wasCompleted
        
        // If completing the task (changing from incomplete to complete)
        if !wasCompleted {
            task.completedAt = Date()
            print("✅ Marked task as complete: \(task.name ?? "Unnamed Task")")
            
            // Use the shared service to show the completion overlay
            TaskCompletionOverlayService.shared.showOverlay(for: task) {
                self.loadTasks() // Refresh the tasks list after overlay dismissal
            }
        } else {
            task.completedAt = nil
            print("↩️ Unmarked task completion: \(task.name ?? "Unnamed Task")")
        }
        
        taskRepo.updateTask(task)
        loadTasks()
        
        // Post notification that the task was modified
        AppEvents.post(AppEvents.taskModified, object: task)
    }
    
    /// Deletes a task from the repository
    func deleteTask(_ task: Task) {
        taskRepo.deleteTask(task)
        loadTasks()
        print("🗑️ Deleted task: \(task.name ?? "Unnamed Task")")
    }
    
    /// Selects a task to be used in the timer
    func selectTaskForTimer(_ task: Task) {
        // First check if there's an active session
        if WorkSessionViewModel.isTaskInActiveSession(task) {
            // If this is the active task, just switch to the timer tab
            if let activeTaskID = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastSelectedTaskID),
               let taskID = task.id?.uuidString,
               activeTaskID == taskID {
                switchToTimerTab()
                return
            }
            
            // Show alert that task is already active
            alertTitle = "Session in Progress"
            alertMessage = "This task is currently in an active session. Switch to the timer to continue working on it."
            showingAlertView = true
            return
        }
        
        // Check if a different task is in an active session
        if let activeTaskID = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastSelectedTaskID),
           let taskID = task.id?.uuidString,
           activeTaskID != taskID,
           UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeSessionStartDate) != nil {
            
            // Show alert that another task is active
            alertTitle = "Cannot Switch Tasks"
            alertMessage = "You cannot switch tasks while a session is in progress. Please complete or cancel the current session first."
            showingAlertView = true
            return
        }
        
        // Set this task as the selected task
        UserDefaults.standard.set(task.id?.uuidString, forKey: Constants.UserDefaultsKeys.lastSelectedTaskID)
        
        // Post notification that task was selected
        AppEvents.post(AppEvents.taskSelected, object: task)
        
        // Optionally switch to Timer tab
        switchToTimerTab()
    }
    
    // MARK: - Helper Methods
    
    /// Checks if a task is currently active in the timer
    func isTaskActiveInTimer(_ task: Task) -> Bool {
        guard let taskID = task.id?.uuidString,
              let activeTaskID = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.lastSelectedTaskID) else {
            return false
        }
        
        return taskID == activeTaskID
    }
}
