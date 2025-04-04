//
//  TaskRepository.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/3/25.
//

import Foundation
import CoreData

/// Handles all CRUD operations for Task entities using Core Data.
final class TaskRepository {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Init
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    // MARK: - CRUD Operations
    
    /// Returns all tasks sorted by creation date.
    func getAllTasks() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }

    /// Creates and saves a new task with the provided properties.
    /// - Returns: The newly created Task object.
    @discardableResult
    func createTask(name: String,
                    color: Data,
                    workDuration: Int32,
                    shortBreakDuration: Int32,
                    longBreakDuration: Int32,
                    longBreakAfter: Int32,
                    dailyGoal: Int32,
                    startBreaksAutomatically: Bool,
                    startWorkSessionsAutomatically: Bool) -> Task {
        
        let task = Task(context: context)
        task.id = UUID()
        task.name = name
        task.color = color
        task.workDuration = workDuration
        task.shortBreakDuration = shortBreakDuration
        task.longBreakDuration = longBreakDuration
        task.longBreakAfter = longBreakAfter
        task.dailyGoal = dailyGoal
        task.isCompleted = false
        task.createdAt = Date()
        task.startBreaksAutomatically = startBreaksAutomatically
        task.startWorkSessionsAutomatically = startWorkSessionsAutomatically
        
        saveContext()
        
        return task
    }


    /// Updates an existing task.
    func updateTask(_ task: Task) {
        // Assume properties have been updated already via bindings or manually
        saveContext()
    }

    /// Deletes a task from the store.
    func deleteTask(_ task: Task) {
        context.delete(task)
        saveContext()
    }

    // MARK: - Helpers
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

