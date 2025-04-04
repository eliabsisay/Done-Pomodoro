//
//  WorkSessionRepository.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/3/25.
//

import Foundation
import CoreData

/// Manages CRUD operations for WorkSession entities using Core Data.
final class WorkSessionRepository {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext

    // MARK: - Init
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    // MARK: - CRUD
    
    /// Returns all work sessions for a given task.
    func getSessions(for task: Task) -> [WorkSession] {
        let request: NSFetchRequest<WorkSession> = WorkSession.fetchRequest()
        request.predicate = NSPredicate(format: "task == %@", task)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching work sessions: \(error)")
            return []
        }
    }
    
    /// Creates a new WorkSession and saves it to the store.
    @discardableResult
    func createSession(for task: Task,
                       startTime: Date,
                       type: String,
                       isPaused: Bool = false,
                       isCompleted: Bool = false,
                       duration: Double = 0,
                       intervalCount: Double = 0,
                       pauseTime: Date? = nil,
                       totalPauseDuration: Double = 0) -> WorkSession {
        
        let session = WorkSession(context: context)
        session.id = UUID()
        session.task = task
        session.startTime = startTime
        session.type = type
        session.isPaused = isPaused
        session.isCompleted = isCompleted
        session.duration = duration
        session.intervalCount = intervalCount
        session.pauseTime = pauseTime
        session.totalPauseDuration = totalPauseDuration
        
        saveContext()
        return session
    }
    
    /// Updates an existing session (call after making property changes).
    func updateSession(_ session: WorkSession) {
        saveContext()
    }
    
    /// Deletes a session.
    func deleteSession(_ session: WorkSession) {
        context.delete(session)
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
