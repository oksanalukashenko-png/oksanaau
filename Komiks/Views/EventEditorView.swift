//
//  EventEditorView.swift
//  Komiks
//
//  ChronoBudni - Comic Diary
//

import SwiftUI

// MARK: - Event Editor View
struct EventEditorView: View {
    let event: EventModel?
    let position: Int16
    var themeManager: ThemeManager
    let onSave: (EventModel) -> Void
    let onDelete: () -> Void
    
    @State private var viewModel: EventViewModel
    @State private var showPhotoPicker = false
    @State private var showDeleteConfirmation = false
    
    @Environment(\.dismiss) var dismiss
    
    init(event: EventModel?, position: Int16, themeManager: ThemeManager, onSave: @escaping (EventModel) -> Void, onDelete: @escaping () -> Void) {
        self.event = event
        self.position = position
        self.themeManager = themeManager
        self.onSave = onSave
        self.onDelete = onDelete
        self._viewModel = State(initialValue: EventViewModel(event: event, position: position))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Block preview
                        previewSection
                        
                        // Icon selection
                        iconSelectionSection
                        
                        // Color selection
                        colorSelectionSection
                        
                        // Event text
                        textInputSection
                        
                        // Photo
                        photoSection
                        
                        // Delete (if editing)
                        if viewModel.isEditing {
                            deleteSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Event" : "New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(themeManager.isBackgroundDark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(themeManager.textColor)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.isValid)
                    .foregroundStyle(viewModel.isValid ? themeManager.currentTheme.accentUIColor : themeManager.textColor.opacity(0.3))
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker(selectedImage: $viewModel.selectedImage)
            }
            .alert("Delete Event?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone")
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(spacing: 8) {
            Text("Preview")
                .font(themeManager.font(size: 14, weight: .medium))
                .foregroundStyle(themeManager.textColor.opacity(0.6))
            
            ComicBlockView(
                event: viewModel.toEventModel(),
                themeManager: themeManager,
                isLarge: true
            )
            .frame(height: 150)
            .frame(maxWidth: 200)
        }
    }
    
    // MARK: - Icon Selection
    
    private var iconSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(themeManager.font(size: 16, weight: .semibold))
                .foregroundStyle(themeManager.textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableIcons, id: \.self) { iconName in
                        IconSelectionButton(
                            iconName: iconName,
                            isSelected: viewModel.iconName == iconName,
                            themeManager: themeManager
                        ) {
                            viewModel.selectIcon(iconName)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Color Selection
    
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Border Color")
                .font(themeManager.font(size: 16, weight: .semibold))
                .foregroundStyle(themeManager.textColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(viewModel.availableColors, id: \.self) { colorHex in
                    ColorSelectionButton(
                        colorHex: colorHex,
                        isSelected: viewModel.colorHex == colorHex,
                        themeManager: themeManager
                    ) {
                        viewModel.selectColor(colorHex)
                    }
                }
            }
        }
    }
    
    // MARK: - Text Input
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(themeManager.font(size: 16, weight: .semibold))
                .foregroundStyle(themeManager.textColor)
            
            TextField("What happened?", text: $viewModel.text, axis: .vertical)
                .font(themeManager.font(size: 16, weight: .regular))
                .foregroundStyle(themeManager.textColor)
                .padding()
                .lineLimit(3...6)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.textColor.opacity(0.05))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(themeManager.borderColor, lineWidth: 1)
                        }
                }
        }
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo")
                .font(themeManager.font(size: 16, weight: .semibold))
                .foregroundStyle(themeManager.textColor)
            
            if let image = viewModel.selectedImage {
                // Selected new photo
                photoPreview(uiImage: image)
            } else if let photoPath = viewModel.photoPath {
                // Existing photo
                CachedImageView(filename: photoPath)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        removePhotoButton
                    }
            } else {
                // Add photo button
                addPhotoButton
            }
        }
    }
    
    private func photoPreview(uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topTrailing) {
                removePhotoButton
            }
    }
    
    private var removePhotoButton: some View {
        Button {
            viewModel.removePhoto()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .shadow(radius: 2)
        }
        .padding(8)
    }
    
    private var addPhotoButton: some View {
        Button {
            showPhotoPicker = true
        } label: {
            HStack {
                Image(systemName: "photo.badge.plus")
                Text("Add Photo")
            }
            .font(themeManager.font(size: 16, weight: .medium))
            .foregroundStyle(themeManager.currentTheme.accentUIColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(themeManager.currentTheme.accentUIColor, style: StrokeStyle(lineWidth: 2, dash: [8]))
            }
        }
    }
    
    // MARK: - Delete Section
    
    private var deleteSection: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Event")
            }
            .font(themeManager.font(size: 16, weight: .medium))
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.red.opacity(0.1))
            }
        }
    }
    
    // MARK: - Save
    
    private func saveEvent() {
        // Save photo if selected new
        let _ = viewModel.savePhoto()
        
        let eventModel = viewModel.toEventModel()
        onSave(eventModel)
        dismiss()
    }
}

// MARK: - Icon Selection Button
struct IconSelectionButton: View {
    let iconName: String
    let isSelected: Bool
    var themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: IconNames.sfSymbol(for: iconName))
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : themeManager.textColor)
                    .frame(width: 50, height: 50)
                    .background {
                        Circle()
                            .fill(isSelected ? themeManager.currentTheme.accentUIColor : themeManager.textColor.opacity(0.1))
                    }
                
                Text(IconNames.displayName(for: iconName))
                    .font(themeManager.font(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? themeManager.currentTheme.accentUIColor : themeManager.textColor.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Selection Button
struct ColorSelectionButton: View {
    let colorHex: String
    let isSelected: Bool
    var themeManager: ThemeManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: 44, height: 44)
                .overlay {
                    Circle()
                        .strokeBorder(.white, lineWidth: isSelected ? 3 : 0)
                }
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: Color(hex: colorHex).opacity(0.4), radius: isSelected ? 4 : 0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EventEditorView(
        event: nil,
        position: 0,
        themeManager: ThemeManager.shared,
        onSave: { _ in },
        onDelete: {}
    )
}
