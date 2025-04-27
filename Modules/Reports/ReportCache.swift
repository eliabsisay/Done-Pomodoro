//
//  ReportCache.swift
//  Done Pomodoro
//
//  Created by Eliab Sisay on 4/25/25.
//

import Foundation

/// A cache to store report data calculations to improve performance
final class ReportCache {
    /// Singleton instance
    static let shared = ReportCache()
    
    // Cache for storing calculated report data
    private var barChartCache: [String: [ReportBarEntry]] = [:]
    private var pieChartCache: [String: [ReportPieEntry]] = [:]
    private var totalValueCache: [String: Double] = [:]
    
    // Maximum number of entries to store in cache
    private let maxCacheEntries = 20
    
    private init() {}
    
    /// Generates a unique key for the cache based on query parameters
    private func cacheKey(
        period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date?,
        endDate: Date?
    ) -> String {
        let periodKey = period.rawValue
        let unitKey = unit.rawValue
        let taskKey = taskID?.uuidString ?? "all_tasks"
        
        var dateKey = ""
        if let start = startDate, let end = endDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            dateKey = "\(formatter.string(from: start))-\(formatter.string(from: end))"
        }
        
        return "\(periodKey)_\(unitKey)_\(taskKey)_\(dateKey)"
    }
    
    // MARK: - Bar Chart Cache
    
    /// Check if bar chart data is in cache
    func hasBarChartData(
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> Bool {
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        return barChartCache[key] != nil
    }
    
    /// Store bar chart data in cache
    func storeBarChartData(
        _ data: [ReportBarEntry],
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        // Check if we need to trim the cache
        if barChartCache.count >= maxCacheEntries {
            // Remove a random entry to prevent cache from growing too large
            if let keyToRemove = barChartCache.keys.randomElement() {
                barChartCache.removeValue(forKey: keyToRemove)
            }
        }
        
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        barChartCache[key] = data
    }
    
    /// Retrieve bar chart data from cache
    func getBarChartData(
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [ReportBarEntry]? {
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        return barChartCache[key]
    }
    
    // MARK: - Pie Chart Cache
    
    /// Check if pie chart data is in cache
    func hasPieChartData(
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> Bool {
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        return pieChartCache[key] != nil
    }
    
    /// Store pie chart data in cache
    func storePieChartData(
        _ data: [ReportPieEntry],
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        // Check if we need to trim the cache
        if pieChartCache.count >= maxCacheEntries {
            // Remove a random entry to prevent cache from growing too large
            if let keyToRemove = pieChartCache.keys.randomElement() {
                pieChartCache.removeValue(forKey: keyToRemove)
            }
        }
        
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        pieChartCache[key] = data
    }
    
    /// Retrieve pie chart data from cache
    func getPieChartData(
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> [ReportPieEntry]? {
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        return pieChartCache[key]
    }
    
    // MARK: - Total Value Cache
    
    /// Check if total value is in cache
    func hasTotalValue(
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> Bool {
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        return totalValueCache[key] != nil
    }
    
    /// Store total value in cache
    func storeTotalValue(
        _ value: Double,
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) {
        // Check if we need to trim the cache
        if totalValueCache.count >= maxCacheEntries {
            // Remove a random entry to prevent cache from growing too large
            if let keyToRemove = totalValueCache.keys.randomElement() {
                totalValueCache.removeValue(forKey: keyToRemove)
            }
        }
        
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        totalValueCache[key] = value
    }
    
    /// Retrieve total value from cache
    func getTotalValue(
        for period: ReportPeriod,
        unit: ReportUnit,
        taskID: UUID?,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> Double? {
        let key = cacheKey(period: period, unit: unit, taskID: taskID, startDate: startDate, endDate: endDate)
        return totalValueCache[key]
    }
    
    /// Clear all cached data
    func clearCache() {
        barChartCache.removeAll()
        pieChartCache.removeAll()
        totalValueCache.removeAll()
    }
}
