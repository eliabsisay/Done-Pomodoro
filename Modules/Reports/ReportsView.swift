//
//  ReportsView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/25/25.


import SwiftUI

struct ReportsView: View {
    // ViewModel to manage report data and settings
    @StateObject private var viewModel = ReportsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Report header
            VStack(spacing: 4) {
                Text("Productivity Report")
                    .font(.headingM)
                    .padding(.top)
                
                Text(viewModel.dateRangeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Task & period selector
                HStack {
                    // Task selection button
                    Button(action: {
                        viewModel.showingTaskPicker = true
                    }) {
                        HStack {
                            Text(viewModel.selectedTaskName)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                    }
                    .actionSheet(isPresented: $viewModel.showingTaskPicker) {
                        var buttons: [ActionSheet.Button] = [
                            .default(Text("All Tasks")) {
                                viewModel.selectedTask = nil
                            }
                        ]
                        
                        // Add a button for each task
                        for task in viewModel.allTasks {
                            buttons.append(
                                .default(Text(task.name ?? "Unnamed Task")) {
                                    viewModel.selectedTask = task
                                }
                            )
                        }
                        
                        // Add cancel button
                        buttons.append(.cancel())
                        
                        return ActionSheet(
                            title: Text("Select Task"),
                            buttons: buttons
                        )
                    }
                    
                    Spacer()
                    
                    // Period selection
                    Menu {
                        ForEach(ReportPeriod.allCases, id: \.self) { period in
                            Button(period.rawValue) {
                                viewModel.selectedPeriod = period
                                
                                // If custom period is selected, show settings sheet immediately
                                if period == .custom {
                                    viewModel.showingSettingsSheet = true
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedPeriod.rawValue)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Chart type selector
                Picker("Chart Type", selection: $viewModel.selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Summary info
            HStack {
                VStack(alignment: .leading) {
                    Text("Total \(viewModel.selectedUnit.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.formattedTotal)
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.showingSettingsSheet = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            // Chart content
            ScrollView {
                if viewModel.selectedChartType == .bar {
                    ReportBarChartView(
                        data: viewModel.barChartData,
                        unit: viewModel.selectedUnit
                    )
                    .padding(.top)
                } else {
                    ReportPieChartView(
                        data: viewModel.pieChartData,
                        unit: viewModel.selectedUnit
                    )
                    .padding(.top)
                }
                
//                // Display detailed sessions (optional)
//                if viewModel.barChartData.isEmpty && viewModel.pieChartData.isEmpty {
//                    EmptyDataView()
//                        .padding(.top, 40)
//                }
            }
        }
        .navigationTitle("Reports")
        .onAppear {
            // Load saved settings and data
            viewModel.loadReportSettings()
            viewModel.loadReportData()
        }
        .sheet(isPresented: $viewModel.showingSettingsSheet) {
            ReportSettingsView(viewModel: viewModel)
        }
    }
}

// View shown when no data is available
struct EmptyDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Complete some work sessions to see your productivity data.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct ReportsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportsView()
        }
    }
}
