//
//  ExportService.swift
//  Komiks
//
//  ХроноБудни - Комикс-дневник
//

import SwiftUI
import PDFKit
import UIKit

// MARK: - Export Service
final class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - Documents Directory
    
    var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var exportsDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Exports", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    var photosDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    // MARK: - Export to PNG
    
    @MainActor
    func exportToPNG<V: View>(view: V, size: CGSize = CGSize(width: 390, height: 520)) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    @MainActor
    func savePNG<V: View>(view: V, filename: String, size: CGSize = CGSize(width: 390, height: 520)) -> URL? {
        guard let image = exportToPNG(view: view, size: size),
              let data = image.pngData() else {
            return nil
        }
        
        let url = exportsDirectory.appendingPathComponent("\(filename).png")
        
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Error saving PNG: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Export to PDF
    
    @MainActor
    func exportToPDF<V: View>(views: [V], pageSize: CGSize = CGSize(width: 390, height: 520)) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        let data = pdfRenderer.pdfData { context in
            for view in views {
                context.beginPage()
                
                let controller = UIHostingController(rootView: view)
                controller.view.bounds = CGRect(origin: .zero, size: pageSize)
                controller.view.backgroundColor = .white
                
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
        }
        
        return data
    }
    
    @MainActor
    func savePDF<V: View>(views: [V], filename: String, pageSize: CGSize = CGSize(width: 390, height: 520)) -> URL? {
        guard let data = exportToPDF(views: views, pageSize: pageSize) else {
            return nil
        }
        
        let url = exportsDirectory.appendingPathComponent("\(filename).pdf")
        
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Error saving PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Photo Management
    
    func savePhoto(_ image: UIImage) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let url = photosDirectory.appendingPathComponent(filename)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        do {
            try data.write(to: url)
            return filename
        } catch {
            print("Error saving photo: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadPhoto(filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    func deletePhoto(filename: String) {
        let url = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Backup
    
    func createBackup() -> URL? {
        guard let jsonData = CoreDataManager.shared.exportToJSON() else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "ChronoBudni_Backup_\(dateFormatter.string(from: Date())).json"
        let url = exportsDirectory.appendingPathComponent(filename)
        
        do {
            try jsonData.write(to: url)
            return url
        } catch {
            print("Error creating backup: \(error.localizedDescription)")
            return nil
        }
    }
    
    func restoreBackup(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url) else {
            return false
        }
        return CoreDataManager.shared.importFromJSON(data)
    }
    
    // MARK: - Share
    
    func getShareItems(for url: URL) -> [Any] {
        return [url]
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

