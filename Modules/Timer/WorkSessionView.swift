//
//  WorkSessionView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/10/25.
//


import SwiftUI

struct WorkSessionView: View {
    
    // ViewModel drives all timer logic
    @StateObject private var viewModel: WorkSessionViewModel
    
    @ObservedObject private var overlayService = TaskCompletionOverlayService.shared
    
    // Allows injecting a custom viewModel preview/testing
    init(viewModel: @autoclosure @escaping () -> WorkSessionViewModel = WorkSessionViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                // Task name with selector
                Button(action: {
                    //If no incomplete tasks show task createion view
                    if viewModel.hasNoIncompleteTasks {
                        viewModel.showTaskCreationView()
                    } else {
                        // Load available tasks before showing picker
                        viewModel.loadAvailableTasks()
                        viewModel.showingTaskPicker = true
                    }
                }) {
                    HStack {
                        if let task = viewModel.currentTask {
                            Text(task.name ?? "Unnamed Task")
                                .font(.headingL)
                                .foregroundStyle(Color.textColor)
                        } else {
                            if viewModel.hasNoIncompleteTasks {
                                Text("Create a Task")
                                    .font(.headingL)
                                    .foregroundStyle(.blue)
                                Image(systemName: "plus")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                
                            } else {
                                Text("Select a Task")
                                    .font(.headingL)
                                    .foregroundStyle(.gray)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                            }
                        }
                        
                    }
                }
                .disabled(viewModel.isRunning) // Prevent changing tasks during active session
                
                // Timer countdown
                ZStack {
                    // Background ring — full light circle
                    Circle()
                        .stroke(viewModel.taskColor.opacity(0.2), lineWidth: 12)
                    
                    // Foreground ring — animates down
                    Circle()
                        .trim(from: 0, to: 1 - viewModel.progress)
                        .stroke(viewModel.taskColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.progress)
                    
                    // Countdown
                    Text(viewModel.timeRemaining.formattedAsTimer)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.primaryColor)
                }
                .frame(width: 200, height: 200)
                .padding()
                
                // Session type label
                Text(viewModel.sessionTypeLabel)
                    .font(.bodyMedium)
                    .foregroundStyle(.secondary)
                
                // Control buttons
                HStack(spacing: 24) {
                    if viewModel.isRunning {
                        // Timer is actively counting down
                        Button("Pause") {
                            viewModel.pause()
                        }
                        .buttonStyle(.borderedProminent)
                        
                    } else if viewModel.isStartable {
                        // Timer hasn't started yet — show Start button
                        Button("Start") {
                            guard let task = viewModel.currentTask else { return }
                            
                            // Use the correct sessionType and matching duration from ViewModel
                            let duration: TimeInterval
                            
                            switch viewModel.sessionType {
                            case .work:
                                duration = TimeInterval(task.workDuration * 60)
                            case .shortBreak:
                                duration = TimeInterval(task.shortBreakDuration * 60)
                            case .longBreak:
                                duration = TimeInterval(task.longBreakDuration * 60)
                            }
                            
                            viewModel.startSession(for: task, type: viewModel.sessionType, duration: duration)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.currentTask == nil) // Disable if no task selected
                        
                    } else {
                        // Paused state UI
                        if viewModel.currentTask == nil {
                            // --- After completing a task: show only a disabled Start button ---
                            Button("Start") { }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity, minHeight: 44)
                            // Always disabled until they actually pick a task
                                .disabled(!viewModel.isStartable)
                        } else {
                            // --- Normal "paused" menu (no task‐complete yet) ---
                            VStack(spacing: 16) {
                                // First row - Resume (common for all session types)
                                Button("Resume") {
                                    viewModel.resume()
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                                
                                // Second row - options based on session type
                                if viewModel.sessionType == .work {
                                    // For work sessions: Complete Session, Complete Task, Cancel
                                    HStack(spacing: 12) {
                                        Button("Complete Session") {
                                            viewModel.completeWorkSession()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.blue)
                                        
                                        Button("Complete Task") {
                                            viewModel.completeTask()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.green)
                                        
                                        Button("Cancel") {
                                            viewModel.cancel()
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)
                                    }
                                } else {
                                    // For break sessions: Just Skip Break (Resume is already handled above)
                                    Button("Skip Break") {
                                        viewModel.completeWorkSession()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .sheet(isPresented: $viewModel.showingHowItWorksSheet) {
                HowItWorksView()
            }
            .sheet(isPresented: $viewModel.showingTaskPicker) {
                TaskPickerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingTaskCreationSheet) {
                TaskEditView(mode: .new, onSave: { newTask in
                    // When a task is saved, select it and close the sheet
                    viewModel.selectTask(newTask)
                    viewModel.showingTaskCreationSheet = false
                    
                    // Reload available tasks to ensure UI is updated
                    viewModel.loadAvailableTasks()
                })
            }
            .onAppear {
                // Load available tasks when the view appears
                viewModel.loadAvailableTasks()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showingHowItWorksSheet = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title3)
                            .foregroundColor(.primaryColor)
                    }
                }
            }
            
            // Success overlay
            if overlayService.showTaskCompletedOverlay {
                TaskCompletedOverlayView()
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: overlayService.showTaskCompletedOverlay)
    }
}

struct WorkSessionView_Previews: PreviewProvider {
    static var previews: some View {
        let taskRepo = TaskRepository()
        let vm = WorkSessionViewModel()
        
        return WorkSessionView(viewModel: vm)
            .onAppear {
                if let task = taskRepo.getAllTasks().first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        vm.startSession(for: task, type: .work, duration: 10)
                    }
                }
            }
    }
}
