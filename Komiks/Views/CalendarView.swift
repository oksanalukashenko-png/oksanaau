//
//  CalendarView.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI

// MARK: - Calendar View
struct CalendarView: View {
    @State private var viewModel = CalendarViewModel()
    @State private var selectedDate: Date?
    @State private var showDayView = false
    
    var themeManager: ThemeManager
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Month header with navigation
                    monthHeader
                    
                    // Weekday header
                    weekdayHeader
                    
                    // Calendar grid
                    calendarGrid
                    
                    Spacer()
                }
            }
            .navigationTitle("ChronoBudni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(themeManager.isBackgroundDark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.goToToday()
                    } label: {
                        Text("Today")
                            .font(themeManager.font(size: 14, weight: .medium))
                            .foregroundStyle(themeManager.currentTheme.accentUIColor)
                    }
                }
            }
            .navigationDestination(isPresented: $showDayView) {
                if let date = selectedDate {
                    DayView(date: date, themeManager: themeManager)
                }
            }
        }
        .tint(themeManager.currentTheme.accentUIColor)
    }
    
    // MARK: - Month Header
    
    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.previousMonth()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(themeManager.currentTheme.accentUIColor)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(viewModel.monthYearString)
                .font(themeManager.font(size: 20, weight: .bold))
                .foregroundStyle(themeManager.textColor)
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.nextMonth()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(themeManager.currentTheme.accentUIColor)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Weekday Header
    
    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(themeManager.font(size: 12, weight: .semibold))
                    .foregroundStyle(themeManager.textColor.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.daysInMonth) { day in
                CalendarDayCell(
                    day: day,
                    themeManager: themeManager
                ) {
                    if let date = day.date {
                        selectedDate = date
                        showDayView = true
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let day: CalendarDay
    var themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Cell background
                RoundedRectangle(cornerRadius: 8)
                    .fill(cellBackgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(cellBorderColor, lineWidth: day.isToday ? 2 : 0)
                    }
                
                VStack(spacing: 4) {
                    if day.isCurrentMonth {
                        Text("\(day.dayNumber)")
                            .font(themeManager.font(size: 16, weight: day.isToday ? .bold : .regular))
                            .foregroundStyle(textColor)
                        
                        // Event indicator
                        if day.hasEvents {
                            Circle()
                                .fill(day.firstEventColor ?? themeManager.currentTheme.accentUIColor)
                                .frame(width: 8, height: 8)
                        } else {
                            Spacer()
                                .frame(height: 8)
                        }
                    }
                }
                .padding(4)
            }
            .frame(height: 50)
        }
        .buttonStyle(.plain)
        .disabled(!day.isCurrentMonth)
    }
    
    private var cellBackgroundColor: Color {
        if !day.isCurrentMonth {
            return .clear
        }
        if day.isToday {
            return themeManager.currentTheme.accentUIColor.opacity(0.15)
        }
        if day.hasEvents {
            return themeManager.currentTheme.secondaryUIColor.opacity(0.1)
        }
        return themeManager.backgroundColor.opacity(0.5)
    }
    
    private var cellBorderColor: Color {
        day.isToday ? themeManager.currentTheme.accentUIColor : .clear
    }
    
    private var textColor: Color {
        if !day.isCurrentMonth {
            return themeManager.textColor.opacity(0.3)
        }
        if day.isToday {
            return themeManager.currentTheme.accentUIColor
        }
        return themeManager.textColor
    }
}

#Preview {
    CalendarView(themeManager: ThemeManager.shared)
}
