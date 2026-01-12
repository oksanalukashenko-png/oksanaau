//
//  CoreDataManager.swift
//  Komiks
//
//  ХроноБудни - Комикс-дневник
//

import Foundation
import CoreData

// MARK: - Core Data Manager
final class CoreDataManager: @unchecked Sendable {
    static let shared = CoreDataManager()
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "ChronoBudni")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Save Context
    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Day Operations
    
    func fetchAllDays() -> [DayEntity] {
        let request: NSFetchRequest<DayEntity> = DayEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DayEntity.date, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching days: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchDay(for date: Date) -> DayEntity? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<DayEntity> = DayEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching day: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchDays(for month: Date) -> [DayEntity] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }
        
        let request: NSFetchRequest<DayEntity> = DayEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, endOfMonth as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DayEntity.date, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching days for month: \(error.localizedDescription)")
            return []
        }
    }
    
    @discardableResult
    func createDay(date: Date, templateId: Int16 = 0) -> DayEntity {
        // Проверяем, существует ли уже день с этой датой
        if let existingDay = fetchDay(for: date) {
            return existingDay
        }
        
        let day = DayEntity(context: viewContext)
        day.id = UUID()
        day.date = Calendar.current.startOfDay(for: date)
        day.templateId = templateId
        
        save()
        return day
    }
    
    func deleteDay(_ day: DayEntity) {
        viewContext.delete(day)
        save()
    }
    
    func updateDayTemplate(_ day: DayEntity, templateId: Int16) {
        day.templateId = templateId
        save()
    }
    
    // MARK: - Event Operations
    
    @discardableResult
    func createEvent(for day: DayEntity, iconName: String, colorHex: String, text: String, photoPath: String?, position: Int16) -> EventEntity {
        let event = EventEntity(context: viewContext)
        event.id = UUID()
        event.iconName = iconName
        event.colorHex = colorHex
        event.text = text
        event.photoPath = photoPath
        event.position = position
        event.day = day
        
        save()
        return event
    }
    
    func updateEvent(_ event: EventEntity, iconName: String? = nil, colorHex: String? = nil, text: String? = nil, photoPath: String? = nil, position: Int16? = nil) {
        if let iconName = iconName { event.iconName = iconName }
        if let colorHex = colorHex { event.colorHex = colorHex }
        if let text = text { event.text = text }
        if let photoPath = photoPath { event.photoPath = photoPath }
        if let position = position { event.position = position }
        
        save()
    }
    
    func deleteEvent(_ event: EventEntity) {
        viewContext.delete(event)
        save()
    }
    
    func fetchEvents(for day: DayEntity) -> [EventEntity] {
        let request: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "day == %@", day)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \EventEntity.position, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching events: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Export/Backup
    
    func exportToJSON() -> Data? {
        let days = fetchAllDays()
        var exportData: [[String: Any]] = []
        
        for day in days {
            var dayDict: [String: Any] = [
                "id": day.id?.uuidString ?? "",
                "date": ISO8601DateFormatter().string(from: day.date ?? Date()),
                "templateId": day.templateId
            ]
            
            var eventsArray: [[String: Any]] = []
            if let events = day.events as? Set<EventEntity> {
                for event in events {
                    let eventDict: [String: Any] = [
                        "id": event.id?.uuidString ?? "",
                        "iconName": event.iconName ?? "",
                        "colorHex": event.colorHex ?? "",
                        "text": event.text ?? "",
                        "photoPath": event.photoPath ?? "",
                        "position": event.position
                    ]
                    eventsArray.append(eventDict)
                }
            }
            dayDict["events"] = eventsArray
            exportData.append(dayDict)
        }
        
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("Error exporting to JSON: \(error.localizedDescription)")
            return nil
        }
    }
    
    func importFromJSON(_ data: Data) -> Bool {
        do {
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return false
            }
            
            let formatter = ISO8601DateFormatter()
            
            for dayDict in jsonArray {
                guard let dateString = dayDict["date"] as? String,
                      let date = formatter.date(from: dateString) else { continue }
                
                let templateId = (dayDict["templateId"] as? Int16) ?? 0
                let day = createDay(date: date, templateId: templateId)
                
                if let eventsArray = dayDict["events"] as? [[String: Any]] {
                    for eventDict in eventsArray {
                        let iconName = (eventDict["iconName"] as? String) ?? "icon_work"
                        let colorHex = (eventDict["colorHex"] as? String) ?? "#FF5C5C"
                        let text = (eventDict["text"] as? String) ?? ""
                        let photoPath = eventDict["photoPath"] as? String
                        let position = (eventDict["position"] as? Int16) ?? 0
                        
                        createEvent(for: day, iconName: iconName, colorHex: colorHex, text: text, photoPath: photoPath, position: position)
                    }
                }
            }
            
            return true
        } catch {
            print("Error importing from JSON: \(error.localizedDescription)")
            return false
        }
    }
}

