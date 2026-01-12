//
//  FeedView.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI

// MARK: - Feed View
struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @State private var selectedDay: DayModel?
    @State private var showDayView = false
    
    var themeManager: ThemeManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.allDays.isEmpty {
                    emptyState
                } else {
                    feedContent
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(themeManager.isBackgroundDark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(themeManager.currentTheme.accentUIColor)
                    }
                }
            }
            .navigationDestination(isPresented: $showDayView) {
                if let day = selectedDay {
                    DayView(date: day.date, themeManager: themeManager)
                }
            }
            .onAppear {
                viewModel.loadAllDays()
            }
        }
        .tint(themeManager.currentTheme.accentUIColor)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(themeManager.textColor.opacity(0.3))
            
            Text("Nothing Yet")
                .font(themeManager.font(size: 20, weight: .semibold))
                .foregroundStyle(themeManager.textColor)
            
            Text("Add events in the calendar\nto see them here")
                .font(themeManager.font(size: 14, weight: .regular))
                .foregroundStyle(themeManager.textColor.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Feed Content
    
    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                // Statistics
                statsHeader
                
                // Group by month
                ForEach(viewModel.daysGroupedByMonth, id: \.0) { month, days in
                    Section {
                        ForEach(days) { day in
                            FeedDayCard(
                                day: day,
                                themeManager: themeManager
                            ) {
                                selectedDay = day
                                showDayView = true
                            }
                        }
                    } header: {
                        monthHeader(month)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Days",
                value: "\(viewModel.totalDays)",
                icon: "calendar",
                themeManager: themeManager
            )
            
            StatCard(
                title: "Events",
                value: "\(viewModel.totalEvents)",
                icon: "star.fill",
                themeManager: themeManager
            )
            
            StatCard(
                title: "This Month",
                value: "\(viewModel.daysThisMonth)",
                icon: "flame.fill",
                themeManager: themeManager
            )
        }
    }
    
    // MARK: - Month Header
    
    private func monthHeader(_ month: String) -> some View {
        HStack {
            Text(month)
                .font(themeManager.font(size: 18, weight: .bold))
                .foregroundStyle(themeManager.textColor)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(themeManager.backgroundColor)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(themeManager.currentTheme.accentUIColor)
            
            Text(value)
                .font(themeManager.font(size: 22, weight: .bold))
                .foregroundStyle(themeManager.textColor)
            
            Text(title)
                .font(themeManager.font(size: 10, weight: .medium))
                .foregroundStyle(themeManager.textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.textColor.opacity(0.05))
        }
    }
}

// MARK: - Feed Day Card
struct FeedDayCard: View {
    let day: DayModel
    var themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Date header
                dateHeader
                
                // Comic thumbnail
                comicThumbnail
                    .padding(12)
            }
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.backgroundColor)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(themeManager.borderColor.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Date Header
    
    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(weekdayString)
                    .font(themeManager.font(size: 12, weight: .medium))
                    .foregroundStyle(themeManager.currentTheme.accentUIColor)
                
                Text(dateString)
                    .font(themeManager.font(size: 16, weight: .semibold))
                    .foregroundStyle(themeManager.textColor)
            }
            
            Spacer()
            
            // Event count
            HStack(spacing: 4) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 12))
                Text("\(day.events.count)")
                    .font(themeManager.font(size: 14, weight: .medium))
            }
            .foregroundStyle(themeManager.textColor.opacity(0.6))
        }
        .padding(12)
        .background(themeManager.textColor.opacity(0.03))
    }
    
    // MARK: - Comic Thumbnail
    
    private var comicThumbnail: some View {
        HStack(spacing: 8) {
            ForEach(day.sortedEvents.prefix(4)) { event in
                miniEventBlock(event)
            }
            
            if day.events.isEmpty {
                Text("No events")
                    .font(themeManager.font(size: 12, weight: .medium))
                    .foregroundStyle(themeManager.textColor.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 80)
    }
    
    private func miniEventBlock(_ event: EventModel) -> some View {
        VStack(spacing: 4) {
            Image(systemName: event.sfSymbol)
                .font(.system(size: 18))
                .foregroundStyle(event.color)
            
            Text(event.text)
                .font(themeManager.font(size: 9, weight: .medium))
                .foregroundStyle(themeManager.textColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(6)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.backgroundColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(event.color, lineWidth: 2)
                }
        }
    }
    
    // MARK: - Date Formatting
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: day.date)
    }
    
    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: day.date)
    }
}

#Preview {
    FeedView(themeManager: ThemeManager.shared)
}
