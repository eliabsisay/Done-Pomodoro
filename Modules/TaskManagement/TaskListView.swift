//
//  TaskListView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//
// TaskListView.swift
import SwiftUI

struct TaskListView: View {
    // We'll use a @State property to track which tab is selected
    @State private var selectedTab = 0
    
    // Our view model will handle data loading and task operations
    @StateObject private var viewModel = TaskListViewModel()
    
    var body: some View {
        ZStack {
            VStack {
                // Segmented control for tab selection
                Picker("Task Status", selection: $selectedTab) {
                    Text("To Do").tag(0)
                    Text("Done").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Display the appropriate list based on the selected tab
                if selectedTab == 0 {
                    ToDoListView(viewModel: viewModel)
                } else {
                    DoneListView(viewModel: viewModel)
                }
                
                // Add button for creating new tasks (only visible in To Do tab)
                if selectedTab == 0 {
                    Button(action: {
                        viewModel.showingNewTaskSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Task")
                        }
                        .font(.headline)
                        .padding()
                        .background(Color.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.bottom)
                }
            }
            
            // Custom Alert Overlay
            if viewModel.showingAlertView {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                
                AlertView(
                    title: viewModel.alertTitle,
                    message: viewModel.alertMessage,
                    buttonText: "OK",
                    action: {
                        viewModel.showingAlertView = false
                    }
                )
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if selectedTab == 0 { // To Do tab
                        Picker("Sort By", selection: $viewModel.todoSortOption) {
                            ForEach(TodoSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } else { // Done tab
                        Picker("Sort By", selection: $viewModel.doneSortOption) {
                            ForEach(DoneSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingNewTaskSheet) {
            TaskEditView(mode: .new, onSave: { task in
                viewModel.addTask(task)
                viewModel.showingNewTaskSheet = false
            })
        }
        .sheet(item: $viewModel.editingTask) { task in
            if WorkSessionViewModel.isTaskInActiveSession(task) {
                // Show an alert or modal explaining why editing is disabled
                AlertView(
                    title: "Cannot Edit Active Task",
                    message: "This task is currently in an active session. Please wait until the session completes or cancel the session before editing.",
                    buttonText: "OK",
                    action: {
                        viewModel.editingTask = nil
                    }
                )
            } else {
                TaskEditView(mode: .edit(task), onSave: { updatedTask in
                    viewModel.updateTask(updatedTask)
                    viewModel.editingTask = nil
                })
            }
        }
        .onAppear {
            viewModel.loadTasks()
        }
    }
}

// Preview provider
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskListView()
        }
    }
}

