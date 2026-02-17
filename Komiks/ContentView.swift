//
//  ContentView.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @State private var themeManager = ThemeManager.shared
    @State private var selectedTab: Tab = .calendar
    
    enum Tab: String, CaseIterable {
        case calendar = "Calendar"
        case feed = "Feed"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .calendar: return "calendar"
            case .feed: return "book.pages"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Calendar
            CalendarView(themeManager: themeManager)
                .tabItem {
                    Label(Tab.calendar.rawValue, systemImage: Tab.calendar.icon)
                }
                .tag(Tab.calendar)
            
            // Feed
            FeedView(themeManager: themeManager)
                .tabItem {
                    Label(Tab.feed.rawValue, systemImage: Tab.feed.icon)
                }
                .tag(Tab.feed)
            
            // Settings
            SettingsView(themeManager: themeManager)
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(themeManager.currentTheme.accentUIColor)
    }
}

#Preview {
    ContentView()
}
