//
//  ComicBlockView.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI

// MARK: - Comic Block View
struct ComicBlockView: View {
    let event: EventModel?
    var themeManager: ThemeManager
    var isLarge: Bool = false
    var onTap: (() -> Void)?
    var onAdd: (() -> Void)?
    
    var body: some View {
        Button {
            if event != nil {
                onTap?()
            } else {
                onAdd?()
            }
        } label: {
            ZStack {
                // Block background
                RoundedRectangle(cornerRadius: 12)
                    .fill(blockBackgroundColor)
                
                // Comic border
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        event?.color ?? themeManager.borderColor,
                        lineWidth: themeManager.effectiveBorderWidth
                    )
                
                if let event = event {
                    // Event content
                    eventContent(event)
                } else {
                    // Empty block for adding
                    emptyBlockContent
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Event Content
    
    @ViewBuilder
    private func eventContent(_ event: EventModel) -> some View {
        VStack(spacing: 8) {
            // Photo if exists
            if let photoPath = event.photoPath {
                CachedImageView(filename: photoPath)
                    .frame(maxWidth: .infinity)
                    .frame(height: isLarge ? 120 : 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
            }
            
            Spacer(minLength: 0)
            
            // Icon
            Image(systemName: event.sfSymbol)
                .font(.system(size: isLarge ? 36 : 24))
                .foregroundStyle(event.color)
            
            // Text
            Text(event.text)
                .font(themeManager.font(size: isLarge ? 14 : 12, weight: .medium))
                .foregroundStyle(themeManager.textColor)
                .multilineTextAlignment(.center)
                .lineLimit(isLarge ? 3 : 2)
                .padding(.horizontal, 8)
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty Block Content
    
    private var emptyBlockContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: isLarge ? 40 : 28))
                .foregroundStyle(themeManager.textColor.opacity(0.4))
            
            Text("Add")
                .font(themeManager.font(size: 12, weight: .medium))
                .foregroundStyle(themeManager.textColor.opacity(0.4))
        }
    }
    
    private var blockBackgroundColor: Color {
        if event != nil {
            return themeManager.backgroundColor
        }
        return themeManager.textColor.opacity(0.05)
    }
}

// MARK: - Comic Page Layout
struct ComicPageLayout: View {
    let events: [EventModel]
    let template: ComicTemplate
    var themeManager: ThemeManager
    var onEventTap: ((EventModel) -> Void)?
    var onAddEvent: ((Int) -> Void)?
    
    var body: some View {
        switch template {
        case .twoByTwo:
            twoByTwoLayout
        case .twoTopOneBig:
            twoTopOneBigLayout
        case .threePlusOne:
            threePlusOneLayout
        case .sixBlocks:
            sixBlocksLayout
        }
    }
    
    // MARK: - 2x2 Layout
    // ┌────┬────┐
    // │ 0  │ 1  │
    // ├────┼────┤
    // │ 2  │ 3  │
    // └────┴────┘
    
    private var twoByTwoLayout: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                blockView(at: 0)
                blockView(at: 1)
            }
            HStack(spacing: 8) {
                blockView(at: 2)
                blockView(at: 3)
            }
        }
    }
    
    // MARK: - 2 Top + 1 Big Layout
    // ┌────┬────┐
    // │ 0  │ 1  │
    // ├────┴────┤
    // │    2    │
    // └─────────┘
    
    private var twoTopOneBigLayout: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                blockView(at: 0)
                blockView(at: 1)
            }
            blockView(at: 2, isLarge: true)
        }
    }
    
    // MARK: - 3 + 1 Layout
    // ┌────┬────┐
    // │ 0  │    │
    // ├────┤ 3  │
    // │ 1  │    │
    // ├────┼────┤
    // │    2    │
    // └─────────┘
    
    private var threePlusOneLayout: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VStack(spacing: 8) {
                    blockView(at: 0)
                    blockView(at: 1)
                }
                blockView(at: 3, isLarge: true)
            }
            blockView(at: 2, isLarge: true)
        }
    }
    
    // MARK: - 6 Blocks Layout
    // ┌────┬────┬────┐
    // │ 0  │ 1  │ 2  │
    // ├────┼────┼────┤
    // │ 3  │ 4  │ 5  │
    // └────┴────┴────┘
    
    private var sixBlocksLayout: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                blockView(at: 0)
                blockView(at: 1)
                blockView(at: 2)
            }
            HStack(spacing: 8) {
                blockView(at: 3)
                blockView(at: 4)
                blockView(at: 5)
            }
        }
    }
    
    // MARK: - Helper
    
    @ViewBuilder
    private func blockView(at position: Int, isLarge: Bool = false) -> some View {
        let event = events.first { $0.position == Int16(position) }
        
        ComicBlockView(
            event: event,
            themeManager: themeManager,
            isLarge: isLarge,
            onTap: {
                if let event = event {
                    onEventTap?(event)
                }
            },
            onAdd: {
                onAddEvent?(position)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let sampleEvents = [
        EventModel(iconName: "icon_work", colorHex: "#FF5C5C", text: "Work day", position: 0),
        EventModel(iconName: "icon_sport", colorHex: "#5CB3FF", text: "Workout", position: 1),
        EventModel(iconName: "icon_read", colorHex: "#8CFF5C", text: "Book", position: 2)
    ]
    
    return ComicPageLayout(
        events: sampleEvents,
        template: .twoTopOneBig,
        themeManager: ThemeManager.shared
    )
    .padding()
    .frame(height: 400)
    .background(Color.gray.opacity(0.1))
}
