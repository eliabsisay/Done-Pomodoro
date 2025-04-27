//
//  ReportSettingsView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/25/25.
import SwiftUI

struct ReportSettingsView: View {
    // Environment value to dismiss the sheet
    @Environment(\.dismiss) private var dismiss
    
    // Reference to the parent view model (NOT a new instance)
    @ObservedObject var viewModel: ReportsViewModel
    
    // Local state variables for tracking changes
    @State private var localPeriod: ReportPeriod
    @State private var localUnit: ReportUnit
    @State private var localChartType: ChartType
    @State private var localStartDate: Date
    @State private var localEndDate: Date
    @State private var localSelectedTask: Task?
    
    // Track if any changes have been made
    @State private var hasChanges: Bool = false
    
    // Initialize with values from view model
    init(viewModel: ReportsViewModel) {
        self.viewModel = viewModel
        _localPeriod = State(initialValue: viewModel.selectedPeriod)
        _localUnit = State(initialValue: viewModel.selectedUnit)
        _localChartType = State(initialValue: viewModel.selectedChartType)
        _localStartDate = State(initialValue: viewModel.customStartDate)
        _localEndDate = State(initialValue: viewModel.customEndDate)
        _localSelectedTask = State(initialValue: viewModel.selectedTask)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Units section
                Section(header: Text("Data Display")) {
                    Picker("Units", selection: $localUnit.onChange(trackChanges)) {
                        ForEach(ReportUnit.allCases, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    
                    Picker("Chart Type", selection: $localChartType.onChange(trackChanges)) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                // Time period section
                Section(header: Text("Time Period")) {
                    Picker("Report Period", selection: $localPeriod.onChange(trackChanges)) {
                        ForEach(ReportPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    
                    // Only show date pickers for custom period
                    if localPeriod == .custom {
                        DatePicker("Start Date",
                                  selection: $localStartDate.onChange(trackChanges),
                                  displayedComponents: .date)
                        
                        DatePicker("End Date",
                                  selection: $localEndDate.onChange(trackChanges),
                                  displayedComponents: .date)
                    }
                }
                
                // Task filter section
                Section(header: Text("Task Filter")) {
                    Picker("Selected Task", selection: $localSelectedTask.onChange(trackChanges)) {
                        // Option for all tasks (nil)
                        Text("All Tasks").tag(nil as Task?)
                        
                        // Option for each task
                        ForEach(viewModel.allTasks) { task in
                            Text(task.name ?? "Unnamed Task").tag(task as Task?)
                        }
                    }
                }
            }
            .navigationTitle("Report Settings")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .disabled(!hasChanges)
                .foregroundColor(hasChanges ? .blue : .gray)
            )
            .onAppear {
                // Reset changes tracking when view appears
                hasChanges = false
            }
        }
    }
    
    // Save all settings back to the view model
    private func saveSettings() {
        // Only apply changes if something changed
        if hasChanges {
            viewModel.selectedPeriod = localPeriod
            viewModel.selectedUnit = localUnit
            viewModel.selectedChartType = localChartType
            viewModel.customStartDate = localStartDate
            viewModel.customEndDate = localEndDate
            viewModel.selectedTask = localSelectedTask
            
            // Save to UserDefaults
            viewModel.saveReportSettings()
            
            // Reload report data with new settings
            viewModel.loadReportData()
        }
    }
    
    // Track when any changes are made
    private func trackChanges() {
        hasChanges =
            localPeriod != viewModel.selectedPeriod ||
            localUnit != viewModel.selectedUnit ||
            localChartType != viewModel.selectedChartType ||
            localSelectedTask?.id != viewModel.selectedTask?.id ||
            (localPeriod == .custom && (
                !Calendar.current.isDate(localStartDate, inSameDayAs: viewModel.customStartDate) ||
                !Calendar.current.isDate(localEndDate, inSameDayAs: viewModel.customEndDate)
            ))
    }
}

// Extension to track changes to Binding values
extension Binding {
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler()
            }
        )
    }
}

struct ReportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a preview view model
        let viewModel = ReportsViewModel()
        
        ReportSettingsView(viewModel: viewModel)
    }
}


