//
//  DayView.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI

// MARK: - Day View
struct DayView: View {
    let date: Date
    var themeManager: ThemeManager
    
    @State private var viewModel: DayViewModel
    @State private var showEventEditor = false
    @State private var editingEvent: EventModel?
    @State private var newEventPosition: Int = 0
    @State private var showTemplateSelector = false
    @State private var showExportSheet = false
    @State private var exportedURL: URL?
    
    init(date: Date, themeManager: ThemeManager) {
        self.date = date
        self.themeManager = themeManager
        self._viewModel = State(initialValue: DayViewModel(date: date))
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Date header
                dateHeader
                
                // Comic page
                comicPage
                    .padding()
                
                // Action buttons
                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(themeManager.isBackgroundDark ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showTemplateSelector = true
                    } label: {
                        Label("Template", systemImage: "square.grid.2x2")
                    }
                    
                    Button {
                        exportToPNG()
                    } label: {
                        Label("Export PNG", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(themeManager.currentTheme.accentUIColor)
                }
            }
        }
        .sheet(isPresented: $showEventEditor) {
            EventEditorView(
                event: editingEvent,
                position: Int16(newEventPosition),
                themeManager: themeManager
            ) { savedEvent in
                if editingEvent != nil {
                    // Edit existing
                    viewModel.updateEvent(
                        savedEvent,
                        iconName: savedEvent.iconName,
                        colorHex: savedEvent.colorHex,
                        text: savedEvent.text,
                        photoPath: savedEvent.photoPath
                    )
                } else {
                    // New event
                    viewModel.addEvent(
                        iconName: savedEvent.iconName,
                        colorHex: savedEvent.colorHex,
                        text: savedEvent.text,
                        photoPath: savedEvent.photoPath
                    )
                }
                viewModel.loadDay()
            } onDelete: {
                if let event = editingEvent {
                    viewModel.deleteEvent(event)
                }
            }
        }
        .sheet(isPresented: $showTemplateSelector) {
            TemplateSelectorView(
                selectedTemplate: viewModel.template,
                themeManager: themeManager
            ) { template in
                viewModel.setTemplate(template)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportedURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            viewModel.loadDay()
        }
    }
    
    // MARK: - Date Header
    
    private var dateHeader: some View {
        VStack(spacing: 4) {
            Text(viewModel.weekdayString)
                .font(themeManager.font(size: 14, weight: .medium))
                .foregroundStyle(themeManager.currentTheme.accentUIColor)
            
            Text(viewModel.dateString)
                .font(themeManager.font(size: 24, weight: .bold))
                .foregroundStyle(themeManager.textColor)
            
            if viewModel.isToday {
                Text("Today")
                    .font(themeManager.font(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(themeManager.currentTheme.accentUIColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Comic Page
    
    private var comicPage: some View {
        ComicPageLayout(
            events: viewModel.sortedEvents(),
            template: viewModel.template,
            themeManager: themeManager,
            onEventTap: { event in
                editingEvent = event
                showEventEditor = true
            },
            onAddEvent: { position in
                guard viewModel.canAddEvent else { return }
                editingEvent = nil
                newEventPosition = position
                showEventEditor = true
            }
        )
        .frame(maxHeight: 450)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            if viewModel.canAddEvent {
                Button {
                    editingEvent = nil
                    newEventPosition = viewModel.events.count
                    showEventEditor = true
                } label: {
                    Label("Add Event", systemImage: "plus.circle.fill")
                        .font(themeManager.font(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(themeManager.currentTheme.accentUIColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Text("Max events: \(viewModel.template.maxEvents)")
                    .font(themeManager.font(size: 14, weight: .medium))
                    .foregroundStyle(themeManager.textColor.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(themeManager.textColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Export
    
    @MainActor
    private func exportToPNG() {
        let exportView = ExportableComicView(
            date: date,
            events: viewModel.sortedEvents(),
            template: viewModel.template,
            themeManager: themeManager
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filename = "ChronoBudni_\(dateFormatter.string(from: date))"
        
        if let url = ExportService.shared.savePNG(view: exportView, filename: filename) {
            exportedURL = url
            showExportSheet = true
        }
    }
}

// MARK: - Template Selector
struct TemplateSelectorView: View {
    let selectedTemplate: ComicTemplate
    var themeManager: ThemeManager
    let onSelect: (ComicTemplate) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(ComicTemplate.allCases, id: \.rawValue) { template in
                        TemplatePreviewCell(
                            template: template,
                            isSelected: template == selectedTemplate,
                            themeManager: themeManager
                        ) {
                            onSelect(template)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Choose Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(themeManager.isBackgroundDark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.currentTheme.accentUIColor)
                }
            }
        }
    }
}

// MARK: - Template Preview Cell
struct TemplatePreviewCell: View {
    let template: ComicTemplate
    let isSelected: Bool
    var themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Template thumbnail
                templatePreview
                    .frame(height: 100)
                    .background(themeManager.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? themeManager.currentTheme.accentUIColor : themeManager.borderColor,
                                lineWidth: isSelected ? 3 : 1
                            )
                    }
                
                Text(template.name)
                    .font(themeManager.font(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? themeManager.currentTheme.accentUIColor : themeManager.textColor)
                
                Text("Up to \(template.maxEvents) events")
                    .font(themeManager.font(size: 11, weight: .regular))
                    .foregroundStyle(themeManager.textColor.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var templatePreview: some View {
        switch template {
        case .twoByTwo:
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    previewBlock
                    previewBlock
                }
                HStack(spacing: 4) {
                    previewBlock
                    previewBlock
                }
            }
            .padding(8)
            
        case .twoTopOneBig:
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    previewBlock
                    previewBlock
                }
                previewBlock
            }
            .padding(8)
            
        case .threePlusOne:
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    VStack(spacing: 4) {
                        previewBlock
                        previewBlock
                    }
                    previewBlock
                }
                previewBlock
            }
            .padding(8)
            
        case .sixBlocks:
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    previewBlock
                    previewBlock
                    previewBlock
                }
                HStack(spacing: 4) {
                    previewBlock
                    previewBlock
                    previewBlock
                }
            }
            .padding(8)
        }
    }
    
    private var previewBlock: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(themeManager.textColor.opacity(0.1))
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(themeManager.borderColor, lineWidth: 1)
            }
    }
}

// MARK: - Exportable Comic View
struct ExportableComicView: View {
    let date: Date
    let events: [EventModel]
    let template: ComicTemplate
    var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(dateString)
                    .font(themeManager.font(size: 18, weight: .bold))
                    .foregroundStyle(themeManager.textColor)
                
                Text("ChronoBudni")
                    .font(themeManager.font(size: 10, weight: .medium))
                    .foregroundStyle(themeManager.textColor.opacity(0.5))
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Comic
            ComicPageLayout(
                events: events,
                template: template,
                themeManager: themeManager
            )
            .padding(16)
            
            Spacer()
        }
        .frame(width: 390, height: 520)
        .background(themeManager.backgroundColor)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        DayView(date: Date(), themeManager: ThemeManager.shared)
    }
}
