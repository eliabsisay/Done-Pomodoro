//
//  AppEvents.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/26/25.
//

import Foundation

/// Central location for app-wide events using NotificationCenter
struct AppEvents {
    /// Posted when a work session is completed
    static let sessionCompleted = Notification.Name("sessionCompletedNotification")
    
    /// Posted when a task is created or updated
    static let taskModified = Notification.Name("taskModifiedNotification")
    
    /// Posts a notification for the given event
    static func post(_ event: Notification.Name, object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: event, object: object, userInfo: userInfo)
    }
    
    /// Adds an observer for the given event
    @discardableResult
    static func observe(_ event: Notification.Name, object: Any? = nil, queue: OperationQueue? = .main, using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: event, object: object, queue: queue, using: block)
    }
    
    /// Removes an observer
    static func removeObserver(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }
}
