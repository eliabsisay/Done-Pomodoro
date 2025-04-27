//
//  ReportPieChartView.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/25/25.
//

import SwiftUI
import Charts

struct ReportPieChartView: View {
    let data: [ReportPieEntry]
    let unit: ReportUnit
    
    // Calculate total for percentages
    private var total: Double {
        data.reduce(0) { $0 + $1.value }
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
                    Image(systemName: "chart.pie")
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
                // Custom pie chart using SwiftUI shape
                ZStack {
                    // Draw the pie slices
                    PieChartView(entries: data, total: total)
                        .frame(height: 250)
                    
                    // Center text showing total
                    VStack {
                        Text(String(format: "%.1f", total))
                            .font(.headline)
                        Text(unit.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Legend
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(data) { entry in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(entry.displayColor)
                                .frame(width: 12, height: 12)
                            
                            Text(entry.label)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(unit == .intervals ?
                                 String(format: "%.1f", entry.value) :
                                    String(format: "%.0f min", entry.value))
                            .font(.caption)
                            
                            Text(String(format: "(%.1f%%)", (entry.value / total) * 100))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
}

// Custom pie chart drawing using SwiftUI shapes
struct PieChartView: View {
    let entries: [ReportPieEntry]
    let total: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<entries.count, id: \.self) { index in
                    PieSlice(
                        startAngle: self.startAngle(for: index),
                        endAngle: self.endAngle(for: index),
                        innerRadius: min(geometry.size.width, geometry.size.height) * 0.25
                    )
                    .fill(entries[index].displayColor)
                    .overlay(
                        PieSlice(
                            startAngle: self.startAngle(for: index),
                            endAngle: self.endAngle(for: index),
                            innerRadius: min(geometry.size.width, geometry.size.height) * 0.25
                        )
                        .stroke(Color(UIColor.systemBackground), lineWidth: 2)
                    )
                }
                
                // Optional: Add a center circle for the donut hole effect
                Circle()
                    .fill(Color(UIColor.systemBackground))
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.5)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
    
    // Calculate the starting angle for each slice
    private func startAngle(for index: Int) -> Angle {
        if index == 0 {
            return .degrees(-90) // Start from the top
        }
        
        // Sum of all previous slices
        let sumPrevious = entries[0..<index].reduce(0) { $0 + $1.value }
        let degreesPerUnit = 360 / total
        return .degrees(degreesPerUnit * sumPrevious - 90)
    }
    
    // Calculate the ending angle for each slice
    private func endAngle(for index: Int) -> Angle {
        let sumIncludingCurrent = entries[0...index].reduce(0) { $0 + $1.value }
        let degreesPerUnit = 360 / total
        return .degrees(degreesPerUnit * sumIncludingCurrent - 90)
    }
}

// Shape for a single pie slice
struct PieSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var innerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        
        // Move to inner circle starting point
        let innerStartX = center.x + innerRadius * cos(CGFloat(startAngle.radians))
        let innerStartY = center.y + innerRadius * sin(CGFloat(startAngle.radians))
        path.move(to: CGPoint(x: innerStartX, y: innerStartY))
        
        // Line to outer circle starting point
        let outerStartX = center.x + radius * cos(CGFloat(startAngle.radians))
        let outerStartY = center.y + radius * sin(CGFloat(startAngle.radians))
        path.addLine(to: CGPoint(x: outerStartX, y: outerStartY))
        
        // Arc around the outer edge
        path.addArc(center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        
        // Line back to inner circle
        let innerEndX = center.x + innerRadius * cos(CGFloat(endAngle.radians))
        let innerEndY = center.y + innerRadius * sin(CGFloat(endAngle.radians))
        path.addLine(to: CGPoint(x: innerEndX, y: innerEndY))
        
        // Arc around inner edge (in reverse)
        path.addArc(center: center,
                    radius: innerRadius,
                    startAngle: endAngle,
                    endAngle: startAngle,
                    clockwise: true)
        
        return path
    }
}

// Basic preview provider
struct ReportPieChartView_Previews: PreviewProvider {
    static var previews: some View {
        // Create some dummy data for preview
        let data = [
            ReportPieEntry(label: "Task 1", value: 12, color: nil),
            ReportPieEntry(label: "Task 2", value: 8, color: nil),
            ReportPieEntry(label: "Task 3", value: 5, color: nil)
        ]
        
        ReportPieChartView(data: data, unit: .intervals)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
