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
    @Environment(\.openWindow) private var openWindow

    @AppStorage("selectedCategory") private var selectedCategory: CategoryItem = .sessions

    @State private var selectedSession: Session?
    @State private var selectedTarget: Target?
    @State private var selectedFiles: Set<File> = []
    @State private var navStackPath = [File]()

    var body: some View {
        NavigationSplitView {
            CategoryList(selection: $selectedCategory)
        } content: {
            VStack {
                switch selectedCategory {
                case .sessions:
                    SessionList(selection: $selectedSession)
                case .targets:
                    TargetList(selection: $selectedTarget)
                case .files:
                    FileList(selection: $selectedFiles)
                }
            }
            .navigationDestination(for: File.self) { file in
                SingleFileView(file: file)
            }
            .navigationDestination(for: Target.self) { target in
                TargetView(target: target, navStackPath: $navStackPath)
            }
            .navigationDestination(for: Session.self) { session in
                SessionView(session: session, navStackPath: $navStackPath)
            }

        } detail: {
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
                            Text("No files selected")
                        default:
                            FileView(files: selectedFiles, navStackPath: $navStackPath)
                        }
                    }
                }
                .navigationDestination(for: File.self) { file in
                    SingleFileView(file: file)
                }
                .navigationDestination(for: Target.self) { target in
                    TargetView(target: target, navStackPath: $navStackPath)
                }
                .navigationDestination(for: Session.self) { session in
                    SessionView(session: session, navStackPath: $navStackPath)
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
    }

    private func importFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            // Open a new window with ImportContentView
            let importRequest = ImportRequest(context: viewContext)
            importRequest.id = UUID().uuidString
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
