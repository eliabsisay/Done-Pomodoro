//
//  ReportsViewModel.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/25/25.
//


import Foundation
import SwiftUI
import Combine

/// Period options for filtering reports
enum ReportPeriod: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case currentWeek = "Current Week"
    case previousWeek = "Previous Week"
    case currentMonth = "Current Month"
    case previousMonth = "Previous Month"
    case thisYear = "This Year"
    case custom = "Custom"
    
    /// Returns start date for the period
    func startDate(relativeTo date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let now = date
        
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
            
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            return calendar.startOfDay(for: yesterday)
            
        case .currentWeek:
            return calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            
        case .previousWeek:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
            return calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: lastWeek).date!
            
        case .currentMonth:
            return calendar.dateComponents([.year, .month], from: now).date!
            
        case .previousMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            return calendar.dateComponents([.year, .month], from: lastMonth).date!
            
        case .thisYear:
            return calendar.dateComponents([.year], from: now).date!
            
        case .custom:
            // Default to last 7 days if custom is selected without dates
            return calendar.date(byAdding: .day, value: -7, to: now)!
        }
    }
    
    /// Returns end date for the period
    func endDate(relativeTo date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let now = date
        
        switch self {
        case .today:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!.addingTimeInterval(-1)
            
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: yesterday))!.addingTimeInterval(-1)
            
        case .currentWeek:
            let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!.addingTimeInterval(-1)
            
        case .previousWeek:
            let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
            let startOfLastWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: lastWeekStart).date!
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startOfLastWeek)!.addingTimeInterval(-1)
            
        case .currentMonth:
            let startOfMonth = calendar.dateComponents([.year, .month], from: now).date!
            return calendar.date(byAdding: .month, value: 1, to: startOfMonth)!.addingTimeInterval(-1)
            
        case .previousMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            let startOfLastMonth = calendar.dateComponents([.year, .month], from: lastMonth).date!
            return calendar.date(byAdding: .month, value: 1, to: startOfLastMonth)!.addingTimeInterval(-1)
            
        case .thisYear:
            let startOfYear = calendar.dateComponents([.year], from: now).date!
            return calendar.date(byAdding: .year, value: 1, to: startOfYear)!.addingTimeInterval(-1)
            
        case .custom:
            // Default to today if custom is selected without dates
            return now
        }
    }
}

/// Units for displaying data in reports
enum ReportUnit: String, CaseIterable {
    case intervals = "Intervals"
    case time = "Time (min)"
}

/// Chart type options for viewing reports
enum ChartType: String, CaseIterable {
    case bar = "Bar Chart"
    case pie = "Pie Chart"
}

/// ViewModel for the Reports screen
final class ReportsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Selected period for reports
    @Published var selectedPeriod: ReportPeriod = .currentWeek {
        didSet { loadReportData() }
    }
    
    /// Units to display data in
    @Published var selectedUnit: ReportUnit = .intervals {
        didSet { loadReportData() }
    }
    
    /// Chart type to display
    @Published var selectedChartType: ChartType = .bar {
        didSet { loadReportData() }
    }
    
    /// The currently selected task to show reports for (nil means "All Tasks")
    @Published var selectedTask: Task? = nil {
        didSet { loadReportData() }
    }
    
    /// Custom start date (when period is .custom)
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date())! {
        didSet { loadReportData() }
    }
    
    /// Custom end date (when period is .custom)
    @Published var customEndDate: Date = Date() {
        didSet { loadReportData() }
    }
    
    /// Controls if report settings sheet is shown
    @Published var showingSettingsSheet = false
    
    /// Flag to show or hide the task picker
    @Published var showingTaskPicker = false
    
    // MARK: - Data Properties
    
    /// All available tasks
    @Published var allTasks: [Task] = []
    
    /// Work sessions grouped by date, filtered by period
    @Published var sessionData: [Date: [WorkSession]] = [:]
    
    /// Aggregated report data for bar chart
    @Published var barChartData: [ReportBarEntry] = []
    
    /// Aggregated report data for pie chart
    @Published var pieChartData: [ReportPieEntry] = []
    
    /// The total aggregated value across the whole report
    @Published var totalValue: Double = 0
    
    // MARK: - Private Properties
    
    private let taskRepo = TaskRepository()
    private let sessionRepo = WorkSessionRepository()
    private let dateFormatter = DateFormatter()
    private var sessionCompletionObserver: NSObjectProtocol?
    
    // MARK: - Init
    
    init() {
        // Configure date formatter for labels
        dateFormatter.dateFormat = "MMM d"
        
        // Load tasks
        loadTasks()
        
        // Initial data load
        loadReportData()
        
        // Register for session completion notifications using AppEvents
            sessionCompletionObserver = AppEvents.observe(AppEvents.sessionCompleted) { [weak self] _ in
                print("📊 Session completed notification received - refreshing report data")
                self?.loadReportData()
                // Also clear cache to ensure fresh data
                ReportCache.shared.clearCache()
            }
    }
    
    // MARK: - Data Loading
    
    /// Loads all tasks from the repository
    private func loadTasks() {
        self.allTasks = taskRepo.getAllTasks()
        print("📊 Loaded \(allTasks.count) tasks for reports")
    }
    
    /// Loads filtered work sessions and prepares chart data
    func loadReportData() {
        print("📊 Loading report data...")
        print("- Period: \(selectedPeriod.rawValue)")
        print("- Unit: \(selectedUnit.rawValue)")
        print("- Chart: \(selectedChartType.rawValue)")
        print("- Task: \(selectedTask?.name ?? "All Tasks")")
        
        // Get date range based on selected period
        let start: Date
        let end: Date
        
        if selectedPeriod == .custom {
            start = Calendar.current.startOfDay(for: customStartDate)
            end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: customEndDate))!.addingTimeInterval(-1)
        } else {
            start = selectedPeriod.startDate()
            end = selectedPeriod.endDate()
        }
        
        print("- Date Range: \(start) to \(end)")
        
        // Fetch all tasks if needed (in case new ones were added)
        if allTasks.isEmpty {
            loadTasks()
        }
        
        // Determine the task ID for cache lookup
        let taskID = selectedTask?.id
        
        // Check if we can use cached data
        if selectedChartType == .bar,
           let cachedData = ReportCache.shared.getBarChartData(
            for: selectedPeriod,
            unit: selectedUnit,
            taskID: taskID,
            startDate: selectedPeriod == .custom ? start : nil,
            endDate: selectedPeriod == .custom ? end : nil) {
            
            print("📊 Using cached bar chart data")
            self.barChartData = cachedData
            
            // Also fetch cached total if available
            if let cachedTotal = ReportCache.shared.getTotalValue(
                for: selectedPeriod,
                unit: selectedUnit,
                taskID: taskID,
                startDate: selectedPeriod == .custom ? start : nil,
                endDate: selectedPeriod == .custom ? end : nil) {
                
                self.totalValue = cachedTotal
                return
            }
        }
        
        if selectedChartType == .pie,
           let cachedData = ReportCache.shared.getPieChartData(
            for: selectedPeriod,
            unit: selectedUnit,
            taskID: taskID,
            startDate: selectedPeriod == .custom ? start : nil,
            endDate: selectedPeriod == .custom ? end : nil) {
            
            print("📊 Using cached pie chart data")
            self.pieChartData = cachedData
            
            // Also fetch cached total if available
            if let cachedTotal = ReportCache.shared.getTotalValue(
                for: selectedPeriod,
                unit: selectedUnit,
                taskID: taskID,
                startDate: selectedPeriod == .custom ? start : nil,
                endDate: selectedPeriod == .custom ? end : nil) {
                
                self.totalValue = cachedTotal
                return
            }
        }
        
        // If we reached here, we need to calculate the data
        print("📊 No cache available, calculating data...")
        
        // Collect work sessions for the selected task(s) and date range
        var allSessions: [WorkSession] = []
        
        if let task = selectedTask {
            // Get sessions for specific task
            let taskSessions = sessionRepo.getSessions(for: task)
            allSessions = taskSessions.filter { session in
                guard let startTime = session.startTime else { return false }
                return startTime >= start && startTime <= end
            }
        } else {
            // Get all sessions in the date range directly
            allSessions = sessionRepo.getAllSessionsInRange(from: start, to: end)
            print("📊 All Tasks: Found \(allSessions.count) sessions in date range")
        }
        
        
        // Group sessions by date
        var groupedSessions: [Date: [WorkSession]] = [:]
        
        for session in allSessions {
            guard let startTime = session.startTime else { continue }
            let startOfDay = Calendar.current.startOfDay(for: startTime)
            
            if groupedSessions[startOfDay] == nil {
                groupedSessions[startOfDay] = []
            }
            
            groupedSessions[startOfDay]?.append(session)
        }
        
        self.sessionData = groupedSessions
        
        // Calculate the value to show based on selected unit
        calculateTotalValue(from: allSessions)
        
        // Store total in cache
        ReportCache.shared.storeTotalValue(
            totalValue,
            for: selectedPeriod,
            unit: selectedUnit,
            taskID: taskID,
            startDate: selectedPeriod == .custom ? start : nil,
            endDate: selectedPeriod == .custom ? end : nil
        )
        
        // Create chart data based on selected chart type
        switch selectedChartType {
        case .bar:
            prepareBarChartData(groupedSessions: groupedSessions, startDate: start, endDate: end)
            
            // Store bar chart data in cache
            ReportCache.shared.storeBarChartData(
                barChartData,
                for: selectedPeriod,
                unit: selectedUnit,
                taskID: taskID,
                startDate: selectedPeriod == .custom ? start : nil,
                endDate: selectedPeriod == .custom ? end : nil
            )
            
        case .pie:
            preparePieChartData(allSessions: allSessions)
            
            // Store pie chart data in cache
            ReportCache.shared.storePieChartData(
                pieChartData,
                for: selectedPeriod,
                unit: selectedUnit,
                taskID: taskID,
                startDate: selectedPeriod == .custom ? start : nil,
                endDate: selectedPeriod == .custom ? end : nil
            )
        }
    }
    
    // MARK: - Bar Chart Data
    
    /// Prepares data for bar chart visualization
    private func prepareBarChartData(groupedSessions: [Date: [WorkSession]], startDate: Date, endDate: Date) {
        // Calculate the appropriate step for x-axis labels
        var barData: [ReportBarEntry] = []
        let calendar = Calendar.current
        
        // Convert to array for access by date index
        var dateRange: [Date] = []
        var currentDate = calendar.startOfDay(for: startDate)
        
        // Create the date range
        while currentDate <= endDate {
            dateRange.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // For each date in the range, create a bar chart entry
        for date in dateRange {
            let sessions = groupedSessions[date] ?? []
            
            let value: Double
            if selectedUnit == .intervals {
                value = sessions.reduce(0) { $0 + $1.intervalCount }
            } else { // .time
                value = sessions.reduce(0) { $0 + $1.duration } // Duration is already in minutes
            }
            
            let entry = ReportBarEntry(
                date: date,
                label: dateFormatter.string(from: date),
                value: value,
                color: selectedTask?.color
            )
            
            barData.append(entry)
        }
        
        // Sort by date
        barData.sort { $0.date < $1.date }
        
        // If we have too many bars, we need to aggregate
        var aggregateLevel = 1
        if barData.count > 14 {
            aggregateLevel = 7 // Weekly for large ranges
        }
        
        if aggregateLevel > 1 {
            barData = aggregateBarData(data: barData, level: aggregateLevel)
        }
        
        // Add this check - if all values are zero, clear the data array
        if !barData.contains(where: { $0.value > 0 }) {
            barData = []
        }
        
        self.barChartData = barData
    }
    
    /// Aggregates bar data to show fewer bars (e.g., for weekly view)
    private func aggregateBarData(data: [ReportBarEntry], level: Int) -> [ReportBarEntry] {
        guard !data.isEmpty else { return [] }
        
        // Group by the aggregation level (e.g., every 7 days)
        var aggregatedData: [ReportBarEntry] = []
        var aggregateDate = data[0].date
        var aggregateValue = 0.0
        var count = 0
        
        for entry in data {
            if count < level {
                aggregateValue += entry.value
                count += 1
            } else {
                // Create the aggregated entry
                let aggregateEntry = ReportBarEntry(
                    date: aggregateDate,
                    label: dateFormatter.string(from: aggregateDate),
                    value: aggregateValue,
                    color: selectedTask?.color
                )
                
                aggregatedData.append(aggregateEntry)
                
                // Reset for next aggregation
                aggregateDate = entry.date
                aggregateValue = entry.value
                count = 1
            }
        }
        
        // Add the last aggregated entry if there's anything left
        if count > 0 {
            let aggregateEntry = ReportBarEntry(
                date: aggregateDate,
                label: dateFormatter.string(from: aggregateDate),
                value: aggregateValue,
                color: selectedTask?.color
            )
            
            aggregatedData.append(aggregateEntry)
        }
        
        return aggregatedData
    }
    
    // MARK: - Pie Chart Data
    
    /// Prepares data for pie chart visualization
    private func preparePieChartData(allSessions: [WorkSession]) {
        var pieData: [ReportPieEntry] = []
        
        // Group sessions by task
        var taskData: [UUID: (name: String, value: Double, color: Data?)] = [:]
        
        for session in allSessions {
            guard let task = session.task else { continue }
            let value: Double
            
            if selectedUnit == .intervals {
                value = session.intervalCount
            } else { // .time
                value = session.duration
            }
            
            if let taskID = task.id {
                if let existingData = taskData[taskID] {
                    taskData[taskID] = (
                        name: existingData.name,
                        value: existingData.value + value,
                        color: existingData.color
                    )
                } else {
                    taskData[taskID] = (
                        name: task.name ?? "Unnamed Task",
                        value: value,
                        color: task.color
                    )
                }
            }
        }
        
        // Convert to pie entries
        for (_, data) in taskData {
            let entry = ReportPieEntry(
                label: data.name,
                value: data.value,
                color: data.color
            )
            
            pieData.append(entry)
        }
        
        // Sort by value descending
        pieData.sort { $0.value > $1.value }
        
        self.pieChartData = pieData
    }
    
    /// Calculates the total value across all sessions
    private func calculateTotalValue(from sessions: [WorkSession]) {
        let total: Double
        
        if selectedUnit == .intervals {
            total = sessions.reduce(0) { $0 + $1.intervalCount }
        } else { // .time
            total = sessions.reduce(0) { $0 + $1.duration }
        }
        
        self.totalValue = total
    }
    
    // MARK: - Helper Functions
    
    /// Returns a formatted string for the total value based on selected unit
    var formattedTotal: String {
        if selectedUnit == .intervals {
            return String(format: "%.1f intervals", totalValue)
        } else {
            return String(format: "%.1f minutes", totalValue)
        }
    }
    
    /// Returns a string representation of the current date range
    var dateRangeText: String {
        let startDate: Date
        let endDate: Date
        
        if selectedPeriod == .custom {
            startDate = customStartDate
            endDate = customEndDate
        } else {
            startDate = selectedPeriod.startDate()
            endDate = selectedPeriod.endDate()
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    /// Returns the task name for display
    var selectedTaskName: String {
        selectedTask?.name ?? "All Tasks"
    }
    
    /// Saves current report settings to UserDefaults
    func saveReportSettings() {
        UserDefaults.standard.set(selectedPeriod.rawValue, forKey: Constants.UserDefaultsKeys.reportPeriod)
        UserDefaults.standard.set(selectedUnit.rawValue, forKey: Constants.UserDefaultsKeys.reportUnits)
        UserDefaults.standard.set(selectedChartType.rawValue, forKey: Constants.UserDefaultsKeys.reportViewType)
    }
    
    /// Loads report settings from UserDefaults
    func loadReportSettings() {
        if let periodString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.reportPeriod),
           let period = ReportPeriod(rawValue: periodString) {
            selectedPeriod = period
        }
        
        if let unitString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.reportUnits),
           let unit = ReportUnit(rawValue: unitString) {
            selectedUnit = unit
        }
        
        if let chartTypeString = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.reportViewType),
           let chartType = ChartType(rawValue: chartTypeString) {
            selectedChartType = chartType
        }
    }
    
    deinit {
        // Clean up for memory management
        self.barChartData = []
        self.pieChartData = []
        self.sessionData = [:]
        
        // Remove the observer
            if let observer = sessionCompletionObserver {
                AppEvents.removeObserver(observer)
            }
    }
}

/// Model for bar chart data entry
struct ReportBarEntry: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let value: Double
    let color: Data?
    
    /// Returns the color for chart display
    var displayColor: Color {
        if let colorData = color,
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
            return Color(uiColor)
        }
        return .primaryColor
    }
}

/// Model for pie chart data entry
struct ReportPieEntry: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Data?
    
    /// Returns the color for chart display
    var displayColor: Color {
        if let colorData = color,
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
            return Color(uiColor)
        }
        return .primaryColor
    }
}
