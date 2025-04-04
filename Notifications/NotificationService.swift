//
//  NotificationService.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/3/25.
//

import Foundation
import UserNotifications

/// Service responsible for scheduling and managing local notifications.
final class NotificationService {
    
    /// Singleton instance for global access
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Permissions
    
    /// Requests notification authorization from the user.
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    /// Checks whether the app currently has notification permission.
    /// Calls the completion handler with `true` if authorized, otherwise `false`.
    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - General Notification Method
    
    /// Schedules a notification after a given time interval.
    /// - Parameters:
    ///   - seconds: Delay in seconds before the notification fires
    ///   - title: Title text of the notification
    ///   - body: Body text of the notification
    ///   - sound: Optional custom sound (defaults to `.default`)
    ///   - categoryIdentifier: Optional category for handling actions
    func scheduleNotification(in seconds: TimeInterval,
                              title: String,
                              body: String,
                              sound: UNNotificationSound = .default,
                              categoryIdentifier: String = "timerComplete") {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.categoryIdentifier = categoryIdentifier
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - App-Specific Wrappers
    
    /// Convenience method for scheduling end-of-session notifications.
    func scheduleSessionEndNotification(in seconds: TimeInterval, sessionType: SessionType) {
        let title = sessionType == .work ? "Work session done!" : "Break over!"
        let body = sessionType == .work
        ? "Time to take a break and recharge."
        : "Ready to focus again? Start your next session!"
        
        scheduleNotification(in: seconds, title: title, body: body)
    }
    
    // MARK: - Cancel
    
    /// Cancels all pending notifications.
    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
