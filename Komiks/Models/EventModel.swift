//
//  EventModel.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import Foundation
import SwiftUI

// MARK: - Event Model (Swift struct wrapper for EventEntity)
struct EventModel: Identifiable, Equatable {
    let id: UUID
    var iconName: String
    var colorHex: String
    var text: String
    var photoPath: String?
    var position: Int16
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var sfSymbol: String {
        IconNames.sfSymbol(for: iconName)
    }
    
    init(id: UUID = UUID(), iconName: String = "icon_work", colorHex: String = "#FF5C5C", text: String = "", photoPath: String? = nil, position: Int16 = 0) {
        self.id = id
        self.iconName = iconName
        self.colorHex = colorHex
        self.text = text
        self.photoPath = photoPath
        self.position = position
    }
    
    init(from entity: EventEntity) {
        self.id = entity.id ?? UUID()
        self.iconName = entity.iconName ?? "icon_work"
        self.colorHex = entity.colorHex ?? "#FF5C5C"
        self.text = entity.text ?? ""
        self.photoPath = entity.photoPath
        self.position = entity.position
    }
}

// MARK: - Day Model (Swift struct wrapper for DayEntity)
struct DayModel: Identifiable, Equatable {
    let id: UUID
    var date: Date
    var templateId: Int16
    var events: [EventModel]
    
    init(id: UUID = UUID(), date: Date = Date(), templateId: Int16 = 0, events: [EventModel] = []) {
        self.id = id
        self.date = date
        self.templateId = templateId
        self.events = events
    }
    
    init(from entity: DayEntity) {
        self.id = entity.id ?? UUID()
        self.date = entity.date ?? Date()
        self.templateId = entity.templateId
        
        if let eventsSet = entity.events as? Set<EventEntity> {
            self.events = eventsSet.map { EventModel(from: $0) }.sorted { $0.position < $1.position }
        } else {
            self.events = []
        }
    }
    
    var sortedEvents: [EventModel] {
        events.sorted { $0.position < $1.position }
    }
    
    var firstEventColor: Color? {
        events.first?.color
    }
}

// MARK: - Template Layouts
enum ComicTemplate: Int16, CaseIterable {
    case twoByTwo = 0      // 4 blocks 2x2
    case twoTopOneBig = 1  // 2 top + 1 big bottom
    case threePlusOne = 2  // 3 small + 1 big
    case sixBlocks = 3     // 6 blocks
    
    var name: String {
        switch self {
        case .twoByTwo: return "2×2"
        case .twoTopOneBig: return "2+1"
        case .threePlusOne: return "3+1"
        case .sixBlocks: return "6 Blocks"
        }
    }
    
    var maxEvents: Int {
        switch self {
        case .twoByTwo: return 4
        case .twoTopOneBig: return 3
        case .threePlusOne: return 4
        case .sixBlocks: return 6
        }
    }
}
