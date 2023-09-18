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

    @AppStorage("selectedSession") private var selectedSessionID: String?
    @State private var selectedTarget: Target?
    @State private var selectedFiles: Set<File> = []
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
                    TargetList(selection: $selectedTarget)
                case .files:
                    FileList(selection: $selectedFiles)
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
                        if let selectedSession = selectedSession {
                            SessionView(session: selectedSession, navStackPath: $navStackPath)
                        } else {
                            Text("No session selected")
                        }
                    case .targets:
                        if let selectedTarget = selectedTarget {
                            TargetView(target: selectedTarget, navStackPath: $navStackPath)
                        } else {
                            Text("No target selected")
                        }
                    case .files:
                        switch selectedFiles.count {
                        case 0:
                            Text("No files selected - YO: \(selectedFiles.count)")
                        case 1:
                            FileViewer(file: selectedFiles.first!)
                        default:
                            FileBrowser(source: .selection(selectedFiles.map { $0.id }),
                                        navStackPath: $navStackPath,
                                        viewMode: $fileBrowserViewMode)
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
            let fetchRequest: NSFetchRequest<Session> = Session.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            return try? viewContext.fetch(fetchRequest).first
        }
    }
}
