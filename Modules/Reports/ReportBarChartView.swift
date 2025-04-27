//
//  ReportBarChartView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/25/25.
//

import SwiftUI
import Charts

struct ReportBarChartView: View {
    let data: [ReportBarEntry]
    let unit: ReportUnit
    
    // Calculate the maximum value for scaling
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1
    }
    
    // Property to check if there's actual data to display
    private var hasData: Bool {
        !data.isEmpty && data.contains { $0.value > 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if !hasData {
                // Empty state
                VStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding(.bottom)
                    
                    Text("No data available for this period")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            } else {
                // Bar chart
                Chart {
                    ForEach(data) { entry in
                        BarMark(
                            x: .value("Date", entry.label),
                            y: .value(unit.rawValue, entry.value)
                        )
                        .foregroundStyle(entry.displayColor)
                        .cornerRadius(4)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYScale(domain: 0...(maxValue * 1.1)) // Add 10% padding at top
                .frame(height: 250)
                .padding(.horizontal)
                
                // X-axis labels may need rotation if we have many bars
                if data.count > 8 {
                    Text("Dates")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}

// Basic preview provider
struct ReportBarChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Create some dummy data for preview
        let data = [
            ReportBarEntry(date: Date().addingTimeInterval(-86400 * 2), label: "Mon", value: 2, color: nil),
            ReportBarEntry(date: Date().addingTimeInterval(-86400), label: "Tue", value: 3.5, color: nil),
            ReportBarEntry(date: Date(), label: "Wed", value: 1.5, color: nil)
        ]
        
        ReportBarChartView(data: data, unit: .intervals)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
