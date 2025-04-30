//
//  TaskPickerView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/28/25.
//


import SwiftUI

struct TaskPickerView: View {
    // Environment value to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    
    // Reference to the parent view model
    @ObservedObject var viewModel: WorkSessionViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.availableTasks) { task in
                    Button(action: {
                        viewModel.selectTask(task)
                        dismiss()
                    }) {
                        HStack {
                            // Color indicator
                            Circle()
                                .fill(getTaskColor(task))
                                .frame(width: 16, height: 16)
                                .padding(.trailing, 4)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.name ?? "Unnamed Task")
                                    .font(.bodyMedium)
                                
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                    Text("\(task.workDuration) min work, \(task.shortBreakDuration) min break")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Show checkmark for currently selected task
                            if viewModel.currentTask?.id == task.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Select Task")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
            .overlay(
                Group {
                    if viewModel.availableTasks.isEmpty {
                        VStack {
                            Image(systemName: "text.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                                .padding()
                            
                            Text("No tasks available")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("Create a task in the Tasks tab first")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
            )
        }
    }
    
    // Helper function to convert task color data to SwiftUI Color
    private func getTaskColor(_ task: Task) -> Color {
        guard let data = task.color,
              let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor else {
            return Color.primaryColor
        }
        return Color(uiColor)
    }
}

// Preview provider for TaskPickerView
struct TaskPickerView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock view model for preview
        let viewModel = WorkSessionViewModel()
        
        // Create a sample context and task
        let context = PersistenceController.preview.container.viewContext
        let task = Task(context: context)
        task.id = UUID()
        task.name = "Preview Task"
        task.workDuration = 25
        task.shortBreakDuration = 5
        
        // Set up view model with sample data
        viewModel.availableTasks = [task]
        
        return TaskPickerView(viewModel: viewModel)
    }
}
