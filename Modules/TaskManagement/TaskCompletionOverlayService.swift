//
//  TaskCompletionOverlayService.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 5/2/25.
//

import Foundation
import SwiftUI
import Combine

/// A singleton service for managing task completion overlays across the app
final class TaskCompletionOverlayService: ObservableObject {
    // Shared instance
    static let shared = TaskCompletionOverlayService()
    
    // Published property for binding to views
    @Published var showTaskCompletedOverlay: Bool = false
    @Published var lastCompletedTask: Task? = nil
    
    // Configuration options
    var overlayDuration: TimeInterval = 1.5
    
    // Private initializer for singleton
    private init() {}
    
    /// Shows the task completion overlay with automatic dismissal
    /// - Parameters:
    ///   - task: The task that was completed
    ///   - completion: Optional callback when the overlay is dismissed
    func showOverlay(for task: Task, completion: (() -> Void)? = nil) {
        // Set the last completed task for reference
        lastCompletedTask = task
        
        // Show the completion overlay
        withAnimation {
            showTaskCompletedOverlay = true
        }
        
        // Automatically hide the overlay after the specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + overlayDuration) { [weak self] in
            withAnimation {
                self?.showTaskCompletedOverlay = false
                
                // Call completion handler if provided
                if let completion = completion {
                    completion()
                }
            }
        }
    }
}
