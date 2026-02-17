//
//  FeedViewModel.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI
import Observation

// MARK: - Feed ViewModel
@Observable
final class FeedViewModel {
    var allDays: [DayModel] = []
    var isLoading = false
    
    private let coreDataManager = CoreDataManager.shared
    
    init() {
        loadAllDays()
    }
    
    // MARK: - Data Loading
    
    func loadAllDays() {
        isLoading = true
        
        let entities = coreDataManager.fetchAllDays()
        allDays = entities.map { DayModel(from: $0) }
        
        isLoading = false
    }
    
    func refresh() {
        loadAllDays()
    }
    
    // MARK: - Grouped by Month
    
    var daysGroupedByMonth: [(String, [DayModel])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        
        var grouped: [String: [DayModel]] = [:]
        var monthOrder: [String] = []
        
        for day in allDays {
            let key = formatter.string(from: day.date)
            if grouped[key] == nil {
                grouped[key] = []
                monthOrder.append(key)
            }
            grouped[key]?.append(day)
        }
        
        return monthOrder.compactMap { key in
            guard let days = grouped[key] else { return nil }
            return (key, days.sorted { $0.date > $1.date })
        }
    }
    
    // MARK: - Statistics
    
    var totalDays: Int {
        allDays.count
    }
    
    var totalEvents: Int {
        allDays.reduce(0) { $0 + $1.events.count }
    }
    
    var daysThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return allDays.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }
    
    var eventsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return allDays
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.events.count }
    }
}
