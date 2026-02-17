//
//  Theme.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI

// MARK: - Comic Theme Model
struct ComicTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let borderWidth: CGFloat
    let borderColor: String
    let backgroundColor: String
    let fontName: String
    let secondaryColor: String
    let accentColor: String
    let textColor: String // Added explicit text color
    
    var borderUIColor: Color {
        Color(hex: borderColor)
    }
    
    var backgroundUIColor: Color {
        Color(hex: backgroundColor)
    }
    
    var secondaryUIColor: Color {
        Color(hex: secondaryColor)
    }
    
    var accentUIColor: Color {
        Color(hex: accentColor)
    }
    
    var textUIColor: Color {
        Color(hex: textColor)
    }
}

// MARK: - Predefined Themes
extension ComicTheme {
    static let classic = ComicTheme(
        id: "classic",
        name: "Classic",
        borderWidth: 3,
        borderColor: "#000000",
        backgroundColor: "#FFFEF0",
        fontName: "ComicSansMS-Bold",
        secondaryColor: "#2C2C2C",
        accentColor: "#FF6B35",
        textColor: "#1A1A1A"
    )
    
    static let manga = ComicTheme(
        id: "manga",
        name: "Manga",
        borderWidth: 2,
        borderColor: "#1A1A1A",
        backgroundColor: "#FFFFFF",
        fontName: "HiraginoSans-W6",
        secondaryColor: "#4A4A4A",
        accentColor: "#FF4081",
        textColor: "#1A1A1A"
    )
    
    static let minimal = ComicTheme(
        id: "minimal",
        name: "Minimal",
        borderWidth: 1,
        borderColor: "#D0D0D0",
        backgroundColor: "#F8F9FA",
        fontName: "SFProRounded-Medium",
        secondaryColor: "#6C757D",
        accentColor: "#0D6EFD",
        textColor: "#212529"
    )
    
    static let neon = ComicTheme(
        id: "neon",
        name: "Neon",
        borderWidth: 2,
        borderColor: "#00FFFF",
        backgroundColor: "#0A0A1A",
        fontName: "Menlo-Bold",
        secondaryColor: "#FF00FF",
        accentColor: "#39FF14",
        textColor: "#FFFFFF" // White text for dark background
    )
    
    static let pastel = ComicTheme(
        id: "pastel",
        name: "Pastel",
        borderWidth: 2,
        borderColor: "#E8B4B8",
        backgroundColor: "#FFF5F5",
        fontName: "Georgia-Bold",
        secondaryColor: "#A5B8D4",
        accentColor: "#98D4BB",
        textColor: "#4A4A4A"
    )
    
    static let allThemes: [ComicTheme] = [classic, manga, minimal, neon, pastel]
}

// MARK: - Color Palette
struct ColorPalette {
    static let eventColors: [String] = [
        "#FF5C5C", // Red
        "#5CB3FF", // Blue
        "#8CFF5C", // Green
        "#FFD15C", // Yellow/Orange
        "#C95CFF", // Purple
        "#000000", // Black
        "#FF85A2", // Pink
        "#5CFFD4", // Teal
        "#FFB85C", // Orange
        "#85A2FF"  // Indigo
    ]
    
    static func color(for hex: String) -> Color {
        Color(hex: hex)
    }
}

// MARK: - Icon Names
struct IconNames {
    static let all: [String] = [
        "icon_sport",
        "icon_read",
        "icon_work",
        "icon_meet",
        "icon_sleep",
        "icon_hobby",
        "icon_food",
        "icon_travel",
        "icon_music",
        "icon_movie",
        "icon_study",
        "icon_shop"
    ]
    
    // SF Symbol fallbacks for display
    static func sfSymbol(for iconName: String) -> String {
        switch iconName {
        case "icon_sport": return "figure.run"
        case "icon_read": return "book.fill"
        case "icon_work": return "briefcase.fill"
        case "icon_meet": return "person.2.fill"
        case "icon_sleep": return "bed.double.fill"
        case "icon_hobby": return "paintbrush.fill"
        case "icon_food": return "fork.knife"
        case "icon_travel": return "airplane"
        case "icon_music": return "music.note"
        case "icon_movie": return "film.fill"
        case "icon_study": return "graduationcap.fill"
        case "icon_shop": return "cart.fill"
        default: return "star.fill"
        }
    }
    
    static func displayName(for iconName: String) -> String {
        switch iconName {
        case "icon_sport": return "Sport"
        case "icon_read": return "Reading"
        case "icon_work": return "Work"
        case "icon_meet": return "Meeting"
        case "icon_sleep": return "Sleep"
        case "icon_hobby": return "Hobby"
        case "icon_food": return "Food"
        case "icon_travel": return "Travel"
        case "icon_music": return "Music"
        case "icon_movie": return "Movie"
        case "icon_study": return "Study"
        case "icon_shop": return "Shopping"
        default: return "Event"
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
