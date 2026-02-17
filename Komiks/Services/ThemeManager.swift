//
//  ThemeManager.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI
import Observation

// MARK: - Theme Manager
@Observable
final class ThemeManager {
    static let shared = ThemeManager()
    
    private let themeKey = "selectedThemeId"
    private let borderSizeKey = "borderSize"
    
    var currentTheme: ComicTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.id, forKey: themeKey)
        }
    }
    
    var borderSizeMultiplier: CGFloat {
        didSet {
            UserDefaults.standard.set(borderSizeMultiplier, forKey: borderSizeKey)
        }
    }
    
    var allThemes: [ComicTheme] {
        ComicTheme.allThemes
    }
    
    private init() {
        // Load saved theme
        let savedThemeId = UserDefaults.standard.string(forKey: themeKey) ?? "classic"
        self.currentTheme = ComicTheme.allThemes.first { $0.id == savedThemeId } ?? .classic
        
        // Load saved border size
        let savedBorderSize = UserDefaults.standard.double(forKey: borderSizeKey)
        self.borderSizeMultiplier = savedBorderSize > 0 ? savedBorderSize : 1.0
    }
    
    func setTheme(_ theme: ComicTheme) {
        currentTheme = theme
    }
    
    func setTheme(byId id: String) {
        if let theme = allThemes.first(where: { $0.id == id }) {
            currentTheme = theme
        }
    }
    
    // MARK: - Computed Theme Properties
    
    var effectiveBorderWidth: CGFloat {
        currentTheme.borderWidth * borderSizeMultiplier
    }
    
    var backgroundColor: Color {
        currentTheme.backgroundUIColor
    }
    
    var borderColor: Color {
        currentTheme.borderUIColor
    }
    
    var textColor: Color {
        currentTheme.textUIColor
    }
    
    var isBackgroundDark: Bool {
        let hex = currentTheme.backgroundColor.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance < 0.5
    }
    
    // MARK: - Font
    
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Try to use theme font, otherwise system
        if UIFont(name: currentTheme.fontName, size: size) != nil {
            return Font.custom(currentTheme.fontName, size: size)
        } else {
            return Font.system(size: size, weight: weight, design: .rounded)
        }
    }
}
