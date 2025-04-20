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

    // Allows injecting a custom viewModel preview/testing
    init(viewModel: @autoclosure @escaping () -> WorkSessionViewModel = WorkSessionViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    var body: some View {
        VStack(spacing: 32) {
            
            // Task name (if available)
            if let task = viewModel.currentTask {
                Text(task.name ?? "Unnamed Task")
                    .font(.headingL)
                    .foregroundStyle(Color.textColor)
            } else {
                Text("No Task")
                    .font(.headingL)
                    .foregroundStyle(.gray)
            }
            
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

                } else {
                    // Timer is paused — show Resume and Complete
                    HStack(spacing: 16) {
                        Button("Resume") {
                            viewModel.resume()
                        }
                        .buttonStyle(.bordered)

                        Button("Complete") {
                            viewModel.completeEarly()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding()
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


