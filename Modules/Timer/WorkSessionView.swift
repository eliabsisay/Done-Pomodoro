//
//  WorkSessionView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/10/25.
//
//  Visual redesign (PR1): restyled onto the "Calm Glass · Neutral + task-accent"
//  design system — neutral surface, a glass task chip, the reusable
//  `TimerRingView` (thin gradient ring + gentle glow from the task color), and
//  the DS Liquid Glass button styles. RESTYLE ONLY: every `viewModel` binding
//  and the full control-button state machine below are preserved verbatim from
//  the original (running / startable / paused·work / paused·break / paused·no-task).
//  Do not alter the actions or conditions here — they are CI-invisible.
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
            VStack(spacing: Constants.Spacing.xxl) {
                // Task name with selector (glass chip)
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
                    HStack(spacing: Constants.Spacing.sm) {
                        if let task = viewModel.currentTask {
                            Text(task.name ?? "Unnamed Task")
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.textSecondary)
                        } else {
                            if viewModel.hasNoIncompleteTasks {
                                Text("Create a Task")
                                    .font(.system(.title2, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Color.textPrimary)
                                Image(systemName: "plus")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.textSecondary)

                            } else {
                                Text("Select a Task")
                                    .font(.system(.title2, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Color.textSecondary)
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.textSecondary)

                            }
                        }

                    }
                    .padding(.horizontal, Constants.Spacing.lg)
                    .padding(.vertical, Constants.Spacing.md)
                    .glassCard(cornerRadius: Constants.Radius.lg)
                }
                .disabled(viewModel.isRunning) // Prevent changing tasks during active session

                // Timer countdown — redesigned ring component + neutral countdown
                ZStack {
                    TimerRingView(progress: viewModel.progress, color: viewModel.taskColor)

                    VStack(spacing: Constants.Spacing.xxs) {
                        Text(viewModel.timeRemaining.formattedAsTimer)
                            .font(.system(size: 64, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.textPrimary)
                        Text("remaining")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .frame(width: 250, height: 250)
                .padding(Constants.Spacing.sm)

                // Session type label
                Text(viewModel.sessionTypeLabel)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Color.textSecondary)

                // Control buttons — STATE MACHINE PRESERVED VERBATIM (restyle only)
                VStack(spacing: Constants.Spacing.md) {
                    if viewModel.isRunning {
                        // Timer is actively counting down
                        Button("Pause") {
                            viewModel.pause()
                        }
                        .buttonStyle(.dsPrimary(tint: viewModel.taskColor))

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
                        .buttonStyle(.dsPrimary(tint: viewModel.taskColor))
                        .disabled(viewModel.currentTask == nil) // Disable if no task selected

                    } else {
                        // Paused state UI
                        if viewModel.currentTask == nil {
                            // --- After completing a task: show only a disabled Start button ---
                            Button("Start") { }
                                .buttonStyle(.dsPrimary(tint: viewModel.taskColor))
                            // Always disabled until they actually pick a task
                                .disabled(!viewModel.isStartable)
                        } else {
                            // --- Normal "paused" menu (no task‐complete yet) ---
                            VStack(spacing: Constants.Spacing.md) {
                                // First row - Resume (common for all session types)
                                Button("Resume") {
                                    viewModel.resume()
                                }
                                .buttonStyle(.dsPrimary(tint: viewModel.taskColor))

                                // Second row - options based on session type
                                if viewModel.sessionType == .work {
                                    // For work sessions: Complete Session, Complete Task, Cancel
                                    Button("Complete Session") {
                                        viewModel.completeWorkSession()
                                    }
                                    .buttonStyle(.dsSecondary)

                                    Button("Complete Task") {
                                        viewModel.completeTask()
                                    }
                                    .buttonStyle(.dsSecondary)

                                    Button("Cancel") {
                                        viewModel.cancel()
                                    }
                                    .buttonStyle(.dsDestructive)
                                } else {
                                    // For break sessions: Just Skip Break (Resume is already handled above)
                                    Button("Skip Break") {
                                        viewModel.completeWorkSession()
                                    }
                                    .buttonStyle(.dsSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(Constants.Spacing.xl)
            .appBackground(accent: viewModel.taskColor)
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
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }

            // Success overlay
            if overlayService.showTaskCompletedOverlay {
                TaskCompletedOverlayView()
            }
        }
        .animation(Constants.Motion.overlay, value: overlayService.showTaskCompletedOverlay)
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
