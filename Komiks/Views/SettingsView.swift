//
//  SettingsView.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @Bindable var themeManager: ThemeManager
    
    @State private var showBackupSuccess = false
    @State private var backupURL: URL?
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                List {
                    // Themes
                    themesSection
                    
                    // Display settings
                    displaySection
                    
                    // Export and backup
                    exportSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(themeManager.isBackgroundDark ? .dark : .light, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                if let url = backupURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .tint(themeManager.currentTheme.accentUIColor)
    }
    
    // MARK: - Themes Section
    
    private var themesSection: some View {
        Section {
            ForEach(themeManager.allThemes) { theme in
                ThemeRow(
                    theme: theme,
                    isSelected: themeManager.currentTheme.id == theme.id,
                    themeManager: themeManager
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        themeManager.setTheme(theme)
                    }
                }
            }
        } header: {
            Text("Comic Theme")
                .font(themeManager.font(size: 12, weight: .semibold))
                .foregroundStyle(themeManager.textColor.opacity(0.7))
        }
        .listRowBackground(themeManager.textColor.opacity(0.05))
    }
    
    // MARK: - Display Section
    
    private var displaySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Border Thickness")
                    .font(themeManager.font(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.textColor)
                
                HStack {
                    Text("Thin")
                        .font(themeManager.font(size: 12, weight: .regular))
                        .foregroundStyle(themeManager.textColor.opacity(0.6))
                    
                    Slider(value: $themeManager.borderSizeMultiplier, in: 0.5...2.0, step: 0.25)
                        .tint(themeManager.currentTheme.accentUIColor)
                    
                    Text("Thick")
                        .font(themeManager.font(size: 12, weight: .regular))
                        .foregroundStyle(themeManager.textColor.opacity(0.6))
                }
                
                // Border preview
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(themeManager.borderColor, lineWidth: themeManager.effectiveBorderWidth)
                        .frame(width: 60, height: 40)
                        .overlay {
                            Text("×\(String(format: "%.1f", themeManager.borderSizeMultiplier))")
                                .font(themeManager.font(size: 10, weight: .medium))
                                .foregroundStyle(themeManager.textColor.opacity(0.5))
                        }
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Display")
                .font(themeManager.font(size: 12, weight: .semibold))
                .foregroundStyle(themeManager.textColor.opacity(0.7))
        }
        .listRowBackground(themeManager.textColor.opacity(0.05))
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        Section {
            Button {
                createBackup()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.doc")
                        .foregroundStyle(themeManager.currentTheme.accentUIColor)
                    Text("Create Backup")
                        .foregroundStyle(themeManager.textColor)
                    Spacer()
                    if showBackupSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Button {
                exportAllToPDF()
            } label: {
                HStack {
                    Image(systemName: "doc.richtext")
                        .foregroundStyle(themeManager.currentTheme.accentUIColor)
                    Text("Export All to PDF")
                        .foregroundStyle(themeManager.textColor)
                }
            }
        } header: {
            Text("Data")
                .font(themeManager.font(size: 12, weight: .semibold))
                .foregroundStyle(themeManager.textColor.opacity(0.7))
        } footer: {
            Text("Backup saves all your entries in JSON format")
                .font(themeManager.font(size: 11, weight: .regular))
                .foregroundStyle(themeManager.textColor.opacity(0.5))
        }
        .listRowBackground(themeManager.textColor.opacity(0.05))
    }
    
    // MARK: - Actions
    
    private func createBackup() {
        if let url = ExportService.shared.createBackup() {
            backupURL = url
            showBackupSuccess = true
            showShareSheet = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showBackupSuccess = false
            }
        }
    }
    
    @MainActor
    private func exportAllToPDF() {
        let days = CoreDataManager.shared.fetchAllDays()
        var views: [ExportableComicView] = []
        
        for dayEntity in days {
            let dayModel = DayModel(from: dayEntity)
            let template = ComicTemplate(rawValue: dayModel.templateId) ?? .twoByTwo
            
            let view = ExportableComicView(
                date: dayModel.date,
                events: dayModel.sortedEvents,
                template: template,
                themeManager: themeManager
            )
            views.append(view)
        }
        
        if !views.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let filename = "ChronoBudni_All_\(dateFormatter.string(from: Date()))"
            
            if let url = ExportService.shared.savePDF(views: views, filename: filename) {
                backupURL = url
                showShareSheet = true
            }
        }
    }
}

// MARK: - Theme Row
struct ThemeRow: View {
    let theme: ComicTheme
    let isSelected: Bool
    var themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Theme preview
                themePreview
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(themeManager.font(size: 16, weight: .medium))
                        .foregroundStyle(themeManager.textColor)
                    
                    Text(themeDescription)
                        .font(themeManager.font(size: 12, weight: .regular))
                        .foregroundStyle(themeManager.textColor.opacity(0.6))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeManager.currentTheme.accentUIColor)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private var themePreview: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(hex: theme.backgroundColor))
            .frame(width: 50, height: 50)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(hex: theme.borderColor), lineWidth: theme.borderWidth)
                    .padding(4)
            }
            .overlay {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: theme.accentColor))
            }
    }
    
    private var themeDescription: String {
        switch theme.id {
        case "classic": return "Classic comic style"
        case "manga": return "Japanese manga"
        case "minimal": return "Minimalist design"
        case "neon": return "Bright neon colors"
        case "pastel": return "Soft pastel tones"
        default: return ""
        }
    }
}

#Preview {
    SettingsView(themeManager: ThemeManager.shared)
}
