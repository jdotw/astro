//
//  ContentView.swift
//  Astro
//
//  Created by James Wilson on 2/7/2023.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.undoManager) var undoManager
    @Environment(\.openWindow) private var openWindow

    @AppStorage("selectedCategory") private var selectedCategory: CategoryItem = .sessions

    @AppStorage("selectedSession") private var selectedSessionID: URL?
    @AppStorage("selectedTarget") private var selectedTargetID: URL?
    @AppStorage("selectedFile") private var selectedFileID: URL?

    @State private var navStackPath = [File]()

    @AppStorage("fileBrowserViewMode") private var fileBrowserViewMode: FileBrowserViewMode = .table

    var body: some View {
        NavigationSplitView {
            // Collapsable far-left side bar
            CategoryList(selection: $selectedCategory)
        } content: {
            // Side bar
            VStack {
                switch selectedCategory {
                case .sessions:
                    SessionList(selectedSessionID: $selectedSessionID)
                case .targets:
                    TargetList(selectedTargetID: $selectedTargetID)
                case .files:
                    FileList(selectedFileID: $selectedFileID)
                case .calibration:
                    CalibrationSessionList()
                }
            }
        } detail: {
            // Content
            NavigationStack(path: $navStackPath) {
                VStack {
                    switch selectedCategory {
                    case .sessions:
                        if let selectedSession {
                            SessionView(session: selectedSession, navStackPath: $navStackPath)
                        } else {
                            Text("No session selected")
                        }
                    case .targets:
                        if let selectedTarget {
                            TargetView(target: selectedTarget, navStackPath: $navStackPath)
                        } else {
                            Text("No target selected")
                        }
                    case .files:
                        if let selectedFile {
                            FileViewer(file: selectedFile)
                        } else {
                            Text("No files selected")
                        }
                    case .calibration:
                        CalibrationView()
                    }
                }
                .navigationDestination(for: File.self) { file in
                    FileViewer(file: file)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: importFiles) {
                    Label("Import Files", systemImage: "plus")
                }
            }
        }
        .onAppear {
            viewContext.undoManager = undoManager
        }
    }

    private func importFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            // Open a new window with ImportContentView
            let importRequest = ImportRequest(context: viewContext)
            importRequest.timestamp = Date()
            for url in panel.urls {
                let importURL = ImportURL(context: viewContext)
                importURL.url = url
                importURL.bookmark = try! url.bookmarkData(options: .withSecurityScope)
                importURL.importRequest = importRequest
            }
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            openWindow(value: importRequest.id)
        }
    }
}

extension ContentView {
    var selectedSession: Session? {
        return selectedSessionID.flatMap { id in
            let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: id)
            return try? viewContext.existingObject(with: objectID!) as? Session
        }
    }

    var selectedTarget: Target? {
        return selectedTargetID.flatMap { id in
            let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: id)
            return try? viewContext.existingObject(with: objectID!) as? Target
        }
    }

    var selectedFile: File? {
        return selectedFileID.flatMap { id in
            let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: id)
            return try? viewContext.existingObject(with: objectID!) as? File
        }
    }
}
