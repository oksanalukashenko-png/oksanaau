//
//  CalendarViewModel.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI
import Observation

// MARK: - Calendar ViewModel
@Observable
final class CalendarViewModel {
    var currentMonth: Date = Date()
    var selectedDate: Date?
    var daysWithEvents: [Date: DayModel] = [:]
    
    private let coreDataManager = CoreDataManager.shared
    private let calendar = Calendar.current
    
    init() {
        loadDaysForCurrentMonth()
    }
    
    // MARK: - Month Navigation
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
            loadDaysForCurrentMonth()
        }
    }
    
    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
            loadDaysForCurrentMonth()
        }
    }
    
    func goToToday() {
        currentMonth = Date()
        loadDaysForCurrentMonth()
    }
    
    // MARK: - Calendar Grid
    
    var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        // Start from Monday
        var symbols = formatter.shortWeekdaySymbols ?? []
        if !symbols.isEmpty {
            let sunday = symbols.removeFirst()
            symbols.append(sunday)
        }
        return symbols.map { $0.uppercased() }
    }
    
    var daysInMonth: [CalendarDay] {
        var days: [CalendarDay] = []
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return days
        }
        
        // Adjust for week starting from Monday
        let adjustedFirstWeekday = firstWeekday == 1 ? 7 : firstWeekday - 1
        
        // Add empty days before month start
        for _ in 1..<adjustedFirstWeekday {
            days.append(CalendarDay(date: nil, dayNumber: 0, isCurrentMonth: false))
        }
        
        // Add days of month
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        for dayNumber in range {
            if let date = calendar.date(bySetting: .day, value: dayNumber, of: monthInterval.start) {
                let normalizedDate = calendar.startOfDay(for: date)
                let hasEvents = daysWithEvents[normalizedDate] != nil
                let isToday = calendar.isDateInToday(date)
                
                days.append(CalendarDay(
                    date: date,
                    dayNumber: dayNumber,
                    isCurrentMonth: true,
                    hasEvents: hasEvents,
                    isToday: isToday,
                    firstEventColor: daysWithEvents[normalizedDate]?.firstEventColor
                ))
            }
        }
        
        // Add empty days at end for grid alignment
        while days.count < 42 {
            days.append(CalendarDay(date: nil, dayNumber: 0, isCurrentMonth: false))
        }
        
        return days
    }
    
    // MARK: - Data Loading
    
    func loadDaysForCurrentMonth() {
        let entities = coreDataManager.fetchDays(for: currentMonth)
        daysWithEvents = [:]
        
        for entity in entities {
            if let date = entity.date {
                let normalizedDate = calendar.startOfDay(for: date)
                daysWithEvents[normalizedDate] = DayModel(from: entity)
            }
        }
    }
    
    func hasEvents(for date: Date) -> Bool {
        let normalizedDate = calendar.startOfDay(for: date)
        return daysWithEvents[normalizedDate] != nil
    }
    
    func dayModel(for date: Date) -> DayModel? {
        let normalizedDate = calendar.startOfDay(for: date)
        return daysWithEvents[normalizedDate]
    }
    
    // MARK: - Day Selection
    
    func selectDate(_ date: Date) {
        selectedDate = date
    }
}

// MARK: - Calendar Day Model
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date?
    let dayNumber: Int
    let isCurrentMonth: Bool
    var hasEvents: Bool = false
    var isToday: Bool = false
    var firstEventColor: Color?
}
