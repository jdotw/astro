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
    @AppStorage("selectedCategory") private var selectedCategory: CategoryItem = .sessions

    @AppStorage("selectedSessionID") private var selectedSessionID: Session.ID?
    @AppStorage("selectedTargetID") private var selectedTargetID: Target.ID?
//    @AppStorage("selectedFileID") private var selectedFileID: File.ID?

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

    private func importFITSFileFromURL(_ url: URL) {
        print("URL: \(url)")
        guard let fits = FITSFile(url: url),
              let headers = fits.headers else { return }
        print(headers)
        do {
            _ = try fits.importFile(context: viewContext)
        } catch {
            print(error)
        }
    }

    private func importFileFromURL(_ url: URL) {
        if url.isFITS {
            importFITSFileFromURL(url)
        }
    }

    private func importFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            for url in panel.urls {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }

                    guard let resourceValues = try? url.resourceValues(forKeys: Set<URLResourceKey>([.isDirectoryKey])),
                          let isDirectory = resourceValues.isDirectory
                    else {
                        continue
                    }
                    if isDirectory {
                        let enumerator = FileManager.default.enumerator(at: panel.url!, includingPropertiesForKeys: nil)
                        while let url = enumerator?.nextObject() as? URL {
                            importFileFromURL(url)
                        }

                    } else {
                        importFileFromURL(url)
                    }
                }
            }
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
