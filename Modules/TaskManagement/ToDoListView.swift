//
//  ToDoListView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

struct ToDoListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.todoTasks) { task in
                TaskRowView(task: task, viewModel: viewModel)
            }
            .onDelete { indexSet in
                // Instead of direct deletion, set the task to delete
                for index in indexSet {
                    if index < viewModel.todoTasks.count {
                        viewModel.taskToDelete = viewModel.todoTasks[index]
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .overlay(
            Group {
                if viewModel.todoTasks.isEmpty {
                    VStack {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No tasks to do")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Add your first task using the button below")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
        )
        // Add confirmation dialog
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


struct ToDoListView_Previews: PreviewProvider {
    static var previews: some View {
        ToDoListView(viewModel: TaskListViewModel())
    }
}
