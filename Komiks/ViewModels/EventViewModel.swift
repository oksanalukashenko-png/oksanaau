//
//  EventViewModel.swift
//  Komiks
//
//  ХроноБудни - Комикс-дневник
//

import SwiftUI
import Observation

// MARK: - Event Editor ViewModel
@Observable
final class EventViewModel {
    var iconName: String
    var colorHex: String
    var text: String
    var photoPath: String?
    var selectedImage: UIImage?
    var position: Int16
    
    var isEditing: Bool
    var originalEvent: EventModel?
    
    init(event: EventModel? = nil, position: Int16 = 0) {
        if let event = event {
            self.iconName = event.iconName
            self.colorHex = event.colorHex
            self.text = event.text
            self.photoPath = event.photoPath
            self.position = event.position
            self.isEditing = true
            self.originalEvent = event
        } else {
            self.iconName = IconNames.all.first ?? "icon_work"
            self.colorHex = ColorPalette.eventColors.first ?? "#FF5C5C"
            self.text = ""
            self.photoPath = nil
            self.position = position
            self.isEditing = false
            self.originalEvent = nil
        }
    }
    
    // MARK: - Computed Properties
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var sfSymbol: String {
        IconNames.sfSymbol(for: iconName)
    }
    
    var iconDisplayName: String {
        IconNames.displayName(for: iconName)
    }
    
    var hasPhoto: Bool {
        photoPath != nil || selectedImage != nil
    }
    
    var isValid: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Icon Selection
    
    var availableIcons: [String] {
        IconNames.all
    }
    
    func selectIcon(_ name: String) {
        iconName = name
    }
    
    // MARK: - Color Selection
    
    var availableColors: [String] {
        ColorPalette.eventColors
    }
    
    func selectColor(_ hex: String) {
        colorHex = hex
    }
    
    // MARK: - Photo Handling
    
    func setPhoto(_ image: UIImage?) {
        selectedImage = image
    }
    
    func removePhoto() {
        if let existingPath = photoPath {
            ExportService.shared.deletePhoto(filename: existingPath)
        }
        photoPath = nil
        selectedImage = nil
    }
    
    func savePhoto() -> String? {
        guard let image = selectedImage else {
            return photoPath
        }
        
        // Удаляем старое фото если есть
        if let existingPath = photoPath {
            ExportService.shared.deletePhoto(filename: existingPath)
        }
        
        // Сохраняем новое
        photoPath = ExportService.shared.savePhoto(image)
        selectedImage = nil
        return photoPath
    }
    
    // MARK: - Create Event Model
    
    func toEventModel() -> EventModel {
        EventModel(
            id: originalEvent?.id ?? UUID(),
            iconName: iconName,
            colorHex: colorHex,
            text: text,
            photoPath: photoPath,
            position: position
        )
    }
}

