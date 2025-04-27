//
//  WorkSessionRepository.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/3/25.
//

import Foundation
import CoreData

/// Handles all CRUD operations for WorkSession entities using Core Data.
/// This repository always uses a consistent Core Data context for all operations
final class WorkSessionRepository {
    
    // MARK: - Properties
    
    /// The managed object context used for all work session operations.
    private let context: NSManagedObjectContext
    
    // MARK: - Init
    
    /// Initializes a new WorkSessionRepository using the provided context (or defaults to shared viewContext).
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    // MARK: - CRUD
    
    /// Fetches all work sessions related to a given task.
    /// - Parameter task: The parent Task whose sessions should be retrieved.
    /// - Returns: A list of WorkSession objects.
    func getSessions(for task: Task) -> [WorkSession] {
        let request: NSFetchRequest<WorkSession> = WorkSession.fetchRequest()
        request.predicate = NSPredicate(format: "task == %@", task)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching work sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetches all work sessions within a date range, regardless of task
    func getAllSessionsInRange(from startDate: Date, to endDate: Date) -> [WorkSession] {
        let request: NSFetchRequest<WorkSession> = WorkSession.fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Error fetching work sessions by date range: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Creates a new WorkSession object and saves it to the persistent store.
    /// - Returns: The created WorkSession object (or nil on failure).
    @discardableResult
    func createSession(for task: Task,
                       startTime: Date,
                       type: String,
                       isPaused: Bool,
                       isCompleted: Bool,
                       duration: Double,
                       intervalCount: Double,
                       pauseTime: Date?,
                       totalPauseDuration: Double) -> WorkSession? {
        
        let session = WorkSession(context: context)
        session.id = UUID()
        session.startTime = startTime
        session.type = type
        session.isPaused = isPaused
        session.isCompleted = isCompleted
        session.duration = duration
        session.intervalCount = intervalCount
        session.pauseTime = pauseTime
        session.totalPauseDuration = totalPauseDuration
        session.task = task
        
        do {
            try context.save()
            return session
        } catch {
            print("❌ Error saving session: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Saves any changes made to an existing WorkSession.
    func updateSession(_ session: WorkSession) {
        saveContext()
    }
    
    /// Deletes the provided WorkSession from the store.
    func deleteSession(_ session: WorkSession) {
        context.delete(session)
        saveContext()
    }
    
    /// Deletes all WorkSession records from the persistent store.
    func deleteAllSessions() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = WorkSession.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("🧹 Deleted all WorkSession records.")
        } catch {
            print("❌ Failed to delete sessions: \(error.localizedDescription)")
        }
    }
    
    
    
    
    
    // MARK: - Helpers
    
    /// Saves any pending changes in the current context.
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ Error saving context: \(error.localizedDescription)")
        }
    }
}
