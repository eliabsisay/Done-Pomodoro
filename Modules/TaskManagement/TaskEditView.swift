//
//  TaskEditView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/24/25.
//

import SwiftUI

/// Enum to represent the different modes of the TaskEditView
enum TaskEditMode: Equatable {
    case new
    case edit(Task)
    
    // Implement Equatable manually since we have an associated value
    static func == (lhs: TaskEditMode, rhs: TaskEditMode) -> Bool {
        switch (lhs, rhs) {
        case (.new, .new):
            return true
        case (.edit(let lhsTask), .edit(let rhsTask)):
            return lhsTask.id == rhsTask.id
        default:
            return false
        }
    }
}

/// Settings that can be adjusted via the duration picker sheet
private enum DurationSetting: Int, Identifiable, CaseIterable {
    case work
    case shortBreak
    case longBreak
    case longBreakAfter
    case dailyGoal

    var id: Int { rawValue }

    /// Title shown in the list and sheet
    var title: String {
        switch self {
        case .work: return "Work Time"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .longBreakAfter: return "Long Break After"
        case .dailyGoal: return "Daily Goal"
        }
    }

    /// Range of allowed values
    var range: ClosedRange<Int> {
        switch self {
        case .work: return 1...60
        case .shortBreak: return 1...30
        case .longBreak: return 5...60
        case .longBreakAfter: return 2...8
        case .dailyGoal: return 1...20
        }
    }

    /// Unit shown beside each value
    var unit: String {
        switch self {
        case .work, .shortBreak, .longBreak: return "minutes"
        case .longBreakAfter, .dailyGoal: return "sessions"
        }
    }
}

struct TaskEditView: View {
    // Environment access for dismissing the sheet
    @Environment(\.dismiss) private var dismiss
    
    // Indicates whether we're creating a new task or editing an existing one
    let mode: TaskEditMode
    
    // Callback for when the task is saved
    let onSave: (Task) -> Void
    
    // Task properties
    @State private var name: String = ""
    @State private var selectedColor: Color = .blue
    @State private var workDuration: Double = 25
    @State private var shortBreakDuration: Double = 5
    @State private var longBreakDuration: Double = 15
    @State private var longBreakAfter: Double = 4
    @State private var dailyGoal: Double = 8

    // Track which duration is currently being edited
    @State private var editingDuration: DurationSetting?
    @State private var startBreaksAutomatically: Bool = false
    @State private var startWorkSessionsAutomatically: Bool = false

    // Track focus state for the task name field
    @FocusState private var isNameFieldFocused: Bool
    
    // Available colors to choose from
    private let colorOptions: [Color] = [.red, .orange, .yellow, .green, .blue, .indigo, .purple, .pink]
    
    // Reference to the Core Data context
    private let context = PersistenceController.shared.container.viewContext
    
    // Check if task is in an active session
    private var isTaskInActiveSession: Bool {
        if case .edit(let task) = mode {
            // Check if this task is currently in a session
            return WorkSessionViewModel.isTaskInActiveSession(task)
        }
        return false
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Task name section
                Section(header: Text("Task Name")) {
                    TextField("Task Name", text: $name)
                        .focused($isNameFieldFocused)
                }
                
                // Color selection section
                Section(header: Text("Task Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colorOptions, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Durations section
                Section(header: Text("Durations")) {
                    durationButton(.work, value: Int(workDuration))
                    durationButton(.shortBreak, value: Int(shortBreakDuration))
                    durationButton(.longBreak, value: Int(longBreakDuration))
                }
                
                // Pomodoro settings section
                Section(header: Text("Pomodoro Settings")) {
                    durationButton(.longBreakAfter, value: Int(longBreakAfter))
                    durationButton(.dailyGoal, value: Int(dailyGoal))
                }
                
                // Automation section
                Section(header: Text("Automation")) {
                    Toggle("Auto-Start Breaks", isOn: $startBreaksAutomatically)
                    Toggle("Auto-Start Work Sessions", isOn: $startWorkSessionsAutomatically)
                }
            }
            .onTapGesture {
                // Dismiss the keyboard when tapping outside the text field
                isNameFieldFocused = false
            }
            .onChange(of: isNameFieldFocused) { isFocused in
                if !isFocused {
                    UIApplication.shared.endEditing()
                }
            }
            .navigationTitle(mode == .new ? "New Task" : "Edit Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveTask()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .onAppear {
                // Load task data if in edit mode
                if case .edit(let task) = mode {
                    loadTaskData(task)
                }
            }
            .sheet(item: $editingDuration) { setting in
                DurationPickerView(setting: setting, value: binding(for: setting))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Loads the task data into the form fields when editing
    private func loadTaskData(_ task: Task) {
        name = task.name ?? ""
        
        // Extract color from the stored data
        if let colorData = task.color,
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
            selectedColor = Color(uiColor)
        }
        
        workDuration = Double(task.workDuration)
        shortBreakDuration = Double(task.shortBreakDuration)
        longBreakDuration = Double(task.longBreakDuration)
        longBreakAfter = Double(task.longBreakAfter)
        dailyGoal = Double(task.dailyGoal)
        startBreaksAutomatically = task.startBreaksAutomatically
        startWorkSessionsAutomatically = task.startWorkSessionsAutomatically
    }
    
    /// Saves the task data
    private func saveTask() {
        // Convert Color to UIColor, then to Data for storage
        let uiColor = UIColor(selectedColor)
        let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        
        // Create or update the task based on mode
        let task: Task
        
        switch mode {
        case .new:
            // Create a new task
            task = Task(context: context)
            task.id = UUID()
            task.createdAt = Date()
            task.isCompleted = false
        case .edit(let existingTask):
            // Use the existing task
            task = existingTask
        }
        
        // Update task properties
        task.name = name
        task.color = colorData
        task.workDuration = Int32(workDuration)
        task.shortBreakDuration = Int32(shortBreakDuration)
        task.longBreakDuration = Int32(longBreakDuration)
        task.longBreakAfter = Int32(longBreakAfter)
        task.dailyGoal = Int32(dailyGoal)
        task.startBreaksAutomatically = startBreaksAutomatically
        task.startWorkSessionsAutomatically = startWorkSessionsAutomatically
        
        // Call the save callback
        onSave(task)
    }

    /// Button builder for each duration row
    @ViewBuilder
    private func durationButton(_ setting: DurationSetting, value: Int) -> some View {
        Button(action: {
            editingDuration = setting
        }) {
            HStack {
                Text(setting.title)
                Spacer()
                Text("\(value) \(setting.unit)")
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// Returns a binding to the correct duration value for the given setting
    private func binding(for setting: DurationSetting) -> Binding<Int> {
        switch setting {
        case .work:
            return Binding(
                get: { Int(workDuration) },
                set: { workDuration = Double($0) }
            )
        case .shortBreak:
            return Binding(
                get: { Int(shortBreakDuration) },
                set: { shortBreakDuration = Double($0) }
            )
        case .longBreak:
            return Binding(
                get: { Int(longBreakDuration) },
                set: { longBreakDuration = Double($0) }
            )
        case .longBreakAfter:
            return Binding(
                get: { Int(longBreakAfter) },
                set: { longBreakAfter = Double($0) }
            )
        case .dailyGoal:
            return Binding(
                get: { Int(dailyGoal) },
                set: { dailyGoal = Double($0) }
            )
        }
    }
}

// Preview provider
struct TaskEditView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview for new task
        TaskEditView(mode: .new, onSave: { _ in })

        // Preview for edit task would need a mock Task
    }
}

/// Sheet with a wheel picker for selecting a duration value
private struct DurationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let setting: DurationSetting
    @Binding var value: Int

    @State private var tempValue: Int
    private let initialValue: Int

    init(setting: DurationSetting, value: Binding<Int>) {
        self.setting = setting
        self._value = value
        self.initialValue = value.wrappedValue
        _tempValue = State(initialValue: value.wrappedValue)
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker(setting.title, selection: $tempValue) {
                    ForEach(Array(setting.range), id: \.self) { val in
                        Text("\(val) \(setting.unit)").tag(val)
                    }
                }
                .labelsHidden()
                .pickerStyle(WheelPickerStyle())
                .frame(maxWidth: .infinity)
            }
            .navigationTitle(setting.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    value = tempValue
                    dismiss()
                }
                .disabled(tempValue == initialValue)
                .foregroundColor(tempValue == initialValue ? .gray : .blue)
            )
        }
    }
}
