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

    @AppStorage("selectedSessionID") private var selectedSessionID: Session.ID?
    @AppStorage("selectedTargetID") private var selectedTargetID: Target.ID?

    // selectedFileIDs isn't @AppStorage because it can't handle Sets
    @State private var selectedFileIDs: Set<File.ID> = []

    var body: some View {
        NavigationSplitView {
            CategoryList(selection: $selectedCategory)
        } content: {
            switch selectedCategory {
            case .sessions:
                SessionList(selection: $selectedSessionID)
            case .targets:
                TargetList(selection: $selectedTargetID)
            case .files:
                FileList(selection: $selectedFileIDs)
            }
        } detail: {
            switch selectedCategory {
            case .sessions:
                SessionView(sessionID: $selectedSessionID)
            case .targets:
                TargetView(targetID: $selectedTargetID)
            case .files:
                MultiFileView(fileIDs: selectedFileIDs)
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
