//
//  DoneListView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

// DoneListView.swift
import SwiftUI

struct DoneListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.doneTasks) { task in
                TaskRowView(task: task, viewModel: viewModel)
            }
            .onDelete { indexSet in
                // Instead of direct deletion, set the task to delete
                for index in indexSet {
                    if index < viewModel.doneTasks.count {
                        viewModel.taskToDelete = viewModel.doneTasks[index]
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .overlay(
            Group {
                if viewModel.doneTasks.isEmpty {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No completed tasks")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Tasks you complete will appear here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
        )
        // Add confirmation dialog - same as in ToDoListView
        .confirmationDialog(
            "Are you sure you want to delete this task?",
            isPresented: Binding(
                get: { viewModel.taskToDelete != nil },
                set: { if !$0 { viewModel.taskToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let task = viewModel.taskToDelete {
                    viewModel.deleteTask(task)
                }
                viewModel.taskToDelete = nil
            }
            
            Button("Cancel", role: .cancel) {
                viewModel.taskToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct DoneListView_Previews: PreviewProvider {
    static var previews: some View {
        DoneListView(viewModel: TaskListViewModel())
    }
}
