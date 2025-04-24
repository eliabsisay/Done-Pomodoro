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
    
    // MARK: - Private Properties
    
    /// Repository for data access
    private let taskRepo = TaskRepository()
    
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
    }
    
    /// Updates an existing task in the repository and refreshes the task list
    func updateTask(_ task: Task) {
        taskRepo.updateTask(task)
        loadTasks()
        print("📝 Updated task: \(task.name ?? "Unnamed Task")")
    }
    
    /// Marks a task as complete or incomplete
    func toggleTaskCompletion(_ task: Task) {
        task.isCompleted = !task.isCompleted
        
        // If completing the task, set the completion date
        if task.isCompleted {
            task.completedAt = Date()
            print("✅ Marked task as complete: \(task.name ?? "Unnamed Task")")
        } else {
            task.completedAt = nil
            print("↩️ Unmarked task completion: \(task.name ?? "Unnamed Task")")
        }
        
        taskRepo.updateTask(task)
        loadTasks()
    }
    
    /// Deletes a task from the repository
    func deleteTask(_ task: Task) {
        taskRepo.deleteTask(task)
        loadTasks()
        print("🗑️ Deleted task: \(task.name ?? "Unnamed Task")")
    }
}
