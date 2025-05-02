//
//  DoneListView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

struct DoneListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.doneTasks) { task in
                TaskRowView(task: task, viewModel: viewModel)
                    // Add leading swipe actions (left to right)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        // Edit button
                        Button {
                            viewModel.editingTask = task
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                        
                        // Uncomplete button
                        Button {
                            viewModel.toggleTaskCompletion(task)
                        } label: {
                            Label("Uncomplete", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.orange)
                    }
                    // Keep existing trailing swipe actions (right to left)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.taskToDelete = task
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete { indexSet in
                // Keep existing delete handling
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
        // Keep the existing confirmation dialog
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
