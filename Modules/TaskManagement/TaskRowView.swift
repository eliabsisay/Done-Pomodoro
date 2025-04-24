//
//  TaskRowView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

struct TaskRowView: View {
    let task: Task
    @ObservedObject var viewModel: TaskListViewModel
    
    // For showing the dot indicator with the task's color
    private var taskColor: Color {
        guard let data = task.color,
              let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor else {
            return Color.primaryColor
        }
        return Color(uiColor)
    }
    
    // Format the task's completion date (if available)
    private var completedDateText: String {
        guard let completedAt = task.completedAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Completed: \(formatter.string(from: completedAt))"
    }
    
    var body: some View {
        HStack {
            // Color indicator
            Circle()
                .fill(taskColor)
                .frame(width: 16, height: 16)
                .padding(.trailing, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name ?? "Unnamed Task")
                    .font(.bodyMedium)
                    .strikethrough(task.isCompleted)
                
                if task.isCompleted, !completedDateText.isEmpty {
                    Text(completedDateText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(task.workDuration) min work, \(task.shortBreakDuration) min break")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Menu for additional actions
            Menu {
                Button(action: {
                    viewModel.toggleTaskCompletion(task)
                }) {
                    Label(task.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                          systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
                }
                
                Button(action: {
                    viewModel.editingTask = task
                }) {
                    Label("Edit Task", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    viewModel.taskToDelete = task
                }) {
                    Label("Delete Task", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Keep this to ensure the menu is tappable
        // Remove the onTapGesture here
    }
}

struct TaskRowView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock task and viewModel for the preview
        let context = PersistenceController.preview.container.viewContext
        let mockTask = Task(context: context)
        mockTask.name = "Preview Task"
        mockTask.workDuration = 25
        mockTask.shortBreakDuration = 5
        mockTask.isCompleted = false
        
        return TaskRowView(
            task: mockTask,
            viewModel: TaskListViewModel()
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
