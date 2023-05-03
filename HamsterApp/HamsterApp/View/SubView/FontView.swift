//
//  FontView.swift
//  HamsterApp
//
//  Created by Vitta on 2023/5/2.
//

import CloudKit
import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.truetype-ttf-font", "public.opentype-font"], in: .import)

        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_: UIDocumentPickerViewController, context _: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let fontURL = urls.first else { return }
            parent.onPick(fontURL)
        }
    }
}

struct FontView: View {
    @EnvironmentObject var appSettings: HamsterAppSettings
    @EnvironmentObject var rimeEngine: RimeEngine

    @State var fontUrlArray = []
    private let fontKey = "Fonts_Key"
    @State private var isDocumentPickerVisible = false
    @State private var fontName: String?

    init() {
        if let savedFonts = UserDefaults.standard.object(forKey: fontKey) as? [String] {
            fontUrlArray = savedFonts
        }
    }

    func save() {
        UserDefaults.standard.set(fontUrlArray, forKey: fontKey)
    }

    var body: some View {
        VStack {
            Button(action: {
                isDocumentPickerVisible = true
            }, label: {
                Text("Add")
            }).sheet(isPresented: $isDocumentPickerVisible) {
                DocumentPicker { url in
                    registerFont(from: url)
                }
            }
        }
    }

    func registerFont(from url: URL) {
        let fm = FileManager.default
        let tempPath: URL = RimeEngine.appGroupSharedSupportFontsURL.appendingPathComponent(url.lastPathComponent)
        var isSuccess: Bool = true
        if !fm.fileExists(atPath: tempPath.path) {
            if !fm.fileExists(atPath: RimeEngine.appGroupSharedSupportFontsURL.path) {
                do {
                    try fm.createDirectory(at: RimeEngine.appGroupSharedSupportFontsURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    isSuccess = false
                    Logger.shared.log.error(error.localizedDescription)
                }
            }
            do {
                try fm.moveItem(at: url, to: tempPath)
            } catch {
                Logger.shared.log.error("字体处理失败: \(error.localizedDescription)")
                isSuccess = false
            }
        }
        if isSuccess {
            appSettings.customFontUrl = url.lastPathComponent
        }
    }
}

struct FontView_Previews: PreviewProvider {
    static var previews: some View {
        FontView()
    }
}
