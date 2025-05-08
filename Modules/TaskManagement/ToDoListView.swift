//
//  ToDoListView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

struct ToDoListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @ObservedObject private var overlayService = TaskCompletionOverlayService.shared
    
    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.todoTasks) { task in
                    TaskRowView(task: task, viewModel: viewModel)
                        // Add leading swipe actions (left to right)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                      
                            // Complete button
                            Button {
                                viewModel.toggleTaskCompletion(task)
                            } label: {
                                Label("Complete", systemImage: "checkmark")
                            }
                            .tint(.green)
                            
                            // Edit button
                            Button {
                                viewModel.editingTask = task
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
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
            
            // Completion overlay
            if overlayService.showTaskCompletedOverlay {
                TaskCompletedOverlayView()
            }
            
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.showTaskCompletedOverlay)
        
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

struct ToDoListView_Previews: PreviewProvider {
    static var previews: some View {
        ToDoListView(viewModel: TaskListViewModel())
    }
}
