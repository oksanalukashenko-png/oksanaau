//
//  DayViewModel.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI
import Observation

// MARK: - Day ViewModel
@Observable
final class DayViewModel {
    var date: Date
    var dayEntity: DayEntity?
    var events: [EventModel] = []
    var templateId: Int16 = 0
    var isLoading = false
    
    private let coreDataManager = CoreDataManager.shared
    private let calendar = Calendar.current
    
    init(date: Date) {
        self.date = date
        loadDay()
    }
    
    // MARK: - Date Formatting
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    // MARK: - Template
    
    var template: ComicTemplate {
        ComicTemplate(rawValue: templateId) ?? .twoByTwo
    }
    
    var canAddEvent: Bool {
        events.count < template.maxEvents
    }
    
    func setTemplate(_ template: ComicTemplate) {
        templateId = template.rawValue
        if let entity = dayEntity {
            coreDataManager.updateDayTemplate(entity, templateId: templateId)
        }
    }
    
    // MARK: - Data Operations
    
    func loadDay() {
        isLoading = true
        
        if let entity = coreDataManager.fetchDay(for: date) {
            dayEntity = entity
            templateId = entity.templateId
            loadEvents()
        } else {
            dayEntity = nil
            events = []
            templateId = 0
        }
        
        isLoading = false
    }
    
    private func loadEvents() {
        guard let entity = dayEntity else {
            events = []
            return
        }
        
        let eventEntities = coreDataManager.fetchEvents(for: entity)
        events = eventEntities.map { EventModel(from: $0) }
    }
    
    func createDayIfNeeded() -> DayEntity {
        if let existing = dayEntity {
            return existing
        }
        
        let newDay = coreDataManager.createDay(date: date, templateId: templateId)
        dayEntity = newDay
        return newDay
    }
    
    // MARK: - Event Operations
    
    func addEvent(iconName: String, colorHex: String, text: String, photoPath: String?) {
        guard canAddEvent else { return }
        
        let day = createDayIfNeeded()
        let position = Int16(events.count)
        
        let _ = coreDataManager.createEvent(
            for: day,
            iconName: iconName,
            colorHex: colorHex,
            text: text,
            photoPath: photoPath,
            position: position
        )
        
        loadEvents()
    }
    
    func updateEvent(_ event: EventModel, iconName: String?, colorHex: String?, text: String?, photoPath: String?) {
        guard let dayEntity = dayEntity,
              let eventEntities = dayEntity.events as? Set<EventEntity>,
              let eventEntity = eventEntities.first(where: { $0.id == event.id }) else {
            return
        }
        
        coreDataManager.updateEvent(
            eventEntity,
            iconName: iconName,
            colorHex: colorHex,
            text: text,
            photoPath: photoPath
        )
        
        loadEvents()
    }
    
    func deleteEvent(_ event: EventModel) {
        guard let dayEntity = dayEntity,
              let eventEntities = dayEntity.events as? Set<EventEntity>,
              let eventEntity = eventEntities.first(where: { $0.id == event.id }) else {
            return
        }
        
        // Delete photo if exists
        if let photoPath = event.photoPath {
            ExportService.shared.deletePhoto(filename: photoPath)
        }
        
        coreDataManager.deleteEvent(eventEntity)
        loadEvents()
        
        // Reorder positions
        reorderEvents()
    }
    
    func moveEvent(from source: IndexSet, to destination: Int) {
        events.move(fromOffsets: source, toOffset: destination)
        reorderEvents()
    }
    
    private func reorderEvents() {
        guard let dayEntity = dayEntity,
              let eventEntities = dayEntity.events as? Set<EventEntity> else {
            return
        }
        
        for (index, event) in events.enumerated() {
            if let entity = eventEntities.first(where: { $0.id == event.id }) {
                entity.position = Int16(index)
            }
        }
        
        coreDataManager.save()
        loadEvents()
    }
    
    // MARK: - Event by Position
    
    func event(at position: Int) -> EventModel? {
        events.first { $0.position == Int16(position) }
    }
    
    func sortedEvents() -> [EventModel] {
        events.sorted { $0.position < $1.position }
    }
}
