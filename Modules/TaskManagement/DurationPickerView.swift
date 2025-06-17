//
//  DurationPickerView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on [Current Date]
//

import SwiftUI

// MARK: - Duration Setting Enum

/// Settings that can be adjusted via the duration picker sheet
enum DurationSetting: Int, Identifiable, CaseIterable {
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

// MARK: - Duration Row Component

/// Reusable row component for duration settings that opens the picker when tapped
struct DurationRow: View {
    let title: String
    let value: Int
    let unit: String
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .foregroundColor(.secondary)
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle()) // Make the entire row tappable
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Duration Picker Sheet

/// Sheet with a wheel picker for selecting a duration value
struct DurationPickerView: View {
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

    /// Computed property to check if the select button should be enabled
    private var hasChanges: Bool {
        tempValue != initialValue
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Wheel picker - taking up most of the available space
                Picker(setting.title, selection: $tempValue) {
                    ForEach(Array(setting.range), id: \.self) { val in
                        Text("\(val) \(setting.unit)")
                            .tag(val)
                    }
                }
                .labelsHidden()
                .pickerStyle(WheelPickerStyle())
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Select button positioned at the bottom center
                Button(action: {
                    // Only save the value when Select is pressed
                    value = tempValue
                    dismiss()
                }) {
                    Text("Select")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(hasChanges ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!hasChanges)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle(setting.title)
            .navigationBarTitleDisplayMode(.inline)
            // No navigation bar items - user can only dismiss by tapping outside or selecting
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Preview Provider

struct DurationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with a sample setting
        DurationPickerView(
            setting: .shortBreak,
            value: .constant(5)
        )
    }
}
